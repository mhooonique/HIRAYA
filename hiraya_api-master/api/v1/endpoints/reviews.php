<?php
// hiraya_api/api/v1/endpoints/reviews.php

function handleReviews(PDO $pdo, string $method, array $segments): void {
    // Routes:
    // GET  /reviews?product_id=X            → list reviews for product
    // POST /reviews                          → submit review (auth required)
    // PUT  /reviews/{id}                     → edit own review (auth required)
    // DELETE /reviews/{id}                   → delete own review / admin delete
    // POST /reviews/{id}/helpful             → mark review as helpful
    // POST /reviews/{id}/report              → report a review

    $reviewId = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;
    $action   = $segments[2] ?? null; // helpful | report

    if ($reviewId && $action === 'helpful') {
        markHelpful($pdo, $reviewId);
        return;
    }
    if ($reviewId && $action === 'report') {
        reportReview($pdo, $reviewId);
        return;
    }

    match ($method) {
        'GET'    => getReviews($pdo),
        'POST'   => submitReview($pdo),
        'PUT'    => editReview($pdo, $reviewId),
        'DELETE' => deleteReview($pdo, $reviewId),
        default  => respond(405, ['error' => 'Method not allowed']),
    };
}

// ── GET /reviews?product_id=X&page=N&sort=recent|helpful|rating ──────────────
function getReviews(PDO $pdo): void {
    $productId = (int)($_GET['product_id'] ?? 0);
    if (!$productId) { respond(400, ['error' => 'product_id required']); return; }

    $page    = max(1, (int)($_GET['page'] ?? 1));
    $perPage = 10;
    $offset  = ($page - 1) * $perPage;
    $sort    = $_GET['sort'] ?? 'recent';

    $orderSQL = match ($sort) {
        'helpful' => 'r.helpful_count DESC, r.created_at DESC',
        'rating'  => 'r.rating DESC, r.created_at DESC',
        default   => 'r.created_at DESC',
    };

    // Get current user if authenticated
    $currentUserId = getCurrentUserId();

    // Summary stats
    $statsSQL = "SELECT 
                     COUNT(*)                                            AS total,
                     ROUND(AVG(rating), 2)                              AS avg_rating,
                     SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)       AS r5,
                     SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END)       AS r4,
                     SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END)       AS r3,
                     SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END)       AS r2,
                     SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END)       AS r1
                 FROM reviews WHERE product_id = :pid AND status = 'approved'";
    $sStmt = $pdo->prepare($statsSQL);
    $sStmt->execute([':pid' => $productId]);
    $stats = $sStmt->fetch(PDO::FETCH_ASSOC);

    // Paginated reviews
    $dataSQL = "SELECT 
                    r.id, r.product_id, r.user_id, r.rating, r.title, r.body,
                    r.helpful_count, r.status, r.created_at, r.updated_at,
                    CONCAT(u.first_name, ' ', u.last_name) AS reviewer_name,
                    u.username AS reviewer_username,
                    u.role AS reviewer_role,
                    " . ($currentUserId ? "
                    (SELECT COUNT(*) FROM review_helpful rh 
                     WHERE rh.review_id = r.id AND rh.user_id = :uid2) AS marked_helpful
                    " : "0 AS marked_helpful") . "
                FROM reviews r
                JOIN users u ON r.user_id = u.id
                WHERE r.product_id = :pid AND r.status = 'approved'
                ORDER BY {$orderSQL}
                LIMIT :limit OFFSET :offset";

    $stmt = $pdo->prepare($dataSQL);
    $stmt->bindValue(':pid', $productId, PDO::PARAM_INT);
    if ($currentUserId) $stmt->bindValue(':uid2', $currentUserId, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $reviews = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Check if current user has already reviewed
    $userReview = null;
    if ($currentUserId) {
        $urStmt = $pdo->prepare(
            "SELECT * FROM reviews WHERE product_id = :pid AND user_id = :uid LIMIT 1"
        );
        $urStmt->execute([':pid' => $productId, ':uid' => $currentUserId]);
        $userReview = $urStmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    respond(200, [
        'stats' => [
            'total'      => (int)$stats['total'],
            'avg_rating' => $stats['avg_rating'] ? (float)$stats['avg_rating'] : null,
            'breakdown'  => [
                5 => (int)$stats['r5'],
                4 => (int)$stats['r4'],
                3 => (int)$stats['r3'],
                2 => (int)$stats['r2'],
                1 => (int)$stats['r1'],
            ],
        ],
        'reviews'     => array_map('formatReview', $reviews),
        'user_review' => $userReview ? formatReview($userReview) : null,
        'total'       => (int)$stats['total'],
        'page'        => $page,
        'has_more'    => $offset + $perPage < (int)$stats['total'],
    ]);
}

// ── POST /reviews ─────────────────────────────────────────────────────────────
function submitReview(PDO $pdo): void {
    $user = requireAuth($pdo);
    if (!$user) return;

    $body      = json_decode(file_get_contents('php://input'), true) ?? [];
    $productId = (int)($body['product_id'] ?? 0);
    $rating    = (int)($body['rating'] ?? 0);
    $title     = trim($body['title'] ?? '');
    $text      = trim($body['body'] ?? '');

    if (!$productId || $rating < 1 || $rating > 5) {
        respond(400, ['error' => 'product_id and rating (1-5) are required']);
        return;
    }

    // Only clients can review (not innovators reviewing their own product)
    $pStmt = $pdo->prepare("SELECT innovator_id FROM products WHERE id = :pid");
    $pStmt->execute([':pid' => $productId]);
    $product = $pStmt->fetch(PDO::FETCH_ASSOC);
    if (!$product) { respond(404, ['error' => 'Product not found']); return; }
    if ($product['innovator_id'] == $user['id']) {
        respond(403, ['error' => 'You cannot review your own product']);
        return;
    }

    // Check duplicate
    $dupStmt = $pdo->prepare(
        "SELECT id FROM reviews WHERE product_id = :pid AND user_id = :uid"
    );
    $dupStmt->execute([':pid' => $productId, ':uid' => $user['id']]);
    if ($dupStmt->fetch()) {
        respond(409, ['error' => 'You have already reviewed this product']);
        return;
    }

    $insStmt = $pdo->prepare(
        "INSERT INTO reviews (product_id, user_id, rating, title, body, status)
         VALUES (:pid, :uid, :rating, :title, :body, 'approved')"
    );
    $insStmt->execute([
        ':pid'    => $productId,
        ':uid'    => $user['id'],
        ':rating' => $rating,
        ':title'  => $title ?: null,
        ':body'   => $text,
    ]);
    $reviewId = (int)$pdo->lastInsertId();

    // Recompute product average rating
    updateProductRating($pdo, $productId);

    // Notify the innovator
    try {
        $pInfo = $pdo->prepare("SELECT p.name, p.user_id FROM products p WHERE p.id = ?");
        $pInfo->execute([$productId]);
        $pRow = $pInfo->fetch(PDO::FETCH_ASSOC);
        if ($pRow) {
            $stars  = str_repeat('★', $rating) . str_repeat('☆', 5 - $rating);
            $snippet = $title ?: (mb_strlen($text) > 60 ? mb_substr($text, 0, 60) . '…' : $text);
            $pdo->exec("CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                type VARCHAR(64) NOT NULL DEFAULT 'system',
                title VARCHAR(255) NOT NULL,
                body TEXT NOT NULL DEFAULT '',
                action_url VARCHAR(512) NOT NULL DEFAULT '',
                is_read TINYINT(1) NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)")
                ->execute([
                    (int)$pRow['user_id'],
                    'review_posted',
                    'New review on your product',
                    "@{$user['username']} gave \"{$pRow['name']}\" {$stars}: \"{$snippet}\"",
                    "/product/{$productId}",
                ]);
        }
    } catch (\Exception $e) { error_log('review notify: ' . $e->getMessage()); }

    respond(201, ['message' => 'Review submitted', 'review_id' => $reviewId]);
}

// ── PUT /reviews/{id} ─────────────────────────────────────────────────────────
function editReview(PDO $pdo, ?int $reviewId): void {
    if (!$reviewId) { respond(400, ['error' => 'Review ID required']); return; }
    $user = requireAuth($pdo);
    if (!$user) return;

    $body   = json_decode(file_get_contents('php://input'), true) ?? [];
    $rating = isset($body['rating']) ? (int)$body['rating'] : null;
    $title  = isset($body['title']) ? trim($body['title']) : null;
    $text   = isset($body['body'])  ? trim($body['body'])  : null;

    $rStmt = $pdo->prepare("SELECT * FROM reviews WHERE id = :id AND user_id = :uid");
    $rStmt->execute([':id' => $reviewId, ':uid' => $user['id']]);
    $review = $rStmt->fetch(PDO::FETCH_ASSOC);
    if (!$review) { respond(404, ['error' => 'Review not found or not yours']); return; }

    $sets   = [];
    $params = [':id' => $reviewId];
    if ($rating !== null && $rating >= 1 && $rating <= 5) { $sets[] = 'rating = :rating'; $params[':rating'] = $rating; }
    if ($title  !== null) { $sets[] = 'title = :title'; $params[':title'] = $title; }
    if ($text   !== null) { $sets[] = 'body = :body';   $params[':body']  = $text; }

    if (empty($sets)) { respond(400, ['error' => 'Nothing to update']); return; }

    $pdo->prepare("UPDATE reviews SET " . implode(',', $sets) . ", updated_at = NOW() WHERE id = :id")
        ->execute($params);

    updateProductRating($pdo, (int)$review['product_id']);
    respond(200, ['message' => 'Review updated']);
}

// ── DELETE /reviews/{id} ──────────────────────────────────────────────────────
function deleteReview(PDO $pdo, ?int $reviewId): void {
    if (!$reviewId) { respond(400, ['error' => 'Review ID required']); return; }
    $user = requireAuth($pdo);
    if (!$user) return;

    $rStmt = $pdo->prepare("SELECT * FROM reviews WHERE id = :id");
    $rStmt->execute([':id' => $reviewId]);
    $review = $rStmt->fetch(PDO::FETCH_ASSOC);
    if (!$review) { respond(404, ['error' => 'Review not found']); return; }

    // Only owner or admin can delete
    if ($review['user_id'] != $user['id'] && $user['role'] !== 'admin') {
        respond(403, ['error' => 'Forbidden']); return;
    }

    $pdo->prepare("DELETE FROM reviews WHERE id = :id")->execute([':id' => $reviewId]);
    updateProductRating($pdo, (int)$review['product_id']);
    respond(200, ['message' => 'Review deleted']);
}

// ── POST /reviews/{id}/helpful ────────────────────────────────────────────────
function markHelpful(PDO $pdo, int $reviewId): void {
    $user = requireAuth($pdo);
    if (!$user) return;

    // Ensure table exists
    $pdo->exec("CREATE TABLE IF NOT EXISTS review_helpful (
        review_id INT NOT NULL,
        user_id   INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (review_id, user_id)
    ) ENGINE=InnoDB;");

    // Toggle
    $check = $pdo->prepare("SELECT 1 FROM review_helpful WHERE review_id=:rid AND user_id=:uid");
    $check->execute([':rid' => $reviewId, ':uid' => $user['id']]);
    if ($check->fetch()) {
        $pdo->prepare("DELETE FROM review_helpful WHERE review_id=:rid AND user_id=:uid")
            ->execute([':rid' => $reviewId, ':uid' => $user['id']]);
        $pdo->prepare("UPDATE reviews SET helpful_count = GREATEST(0, helpful_count - 1) WHERE id=:id")
            ->execute([':id' => $reviewId]);
        respond(200, ['helpful' => false]);
    } else {
        $pdo->prepare("INSERT INTO review_helpful (review_id, user_id) VALUES (:rid,:uid)")
            ->execute([':rid' => $reviewId, ':uid' => $user['id']]);
        $pdo->prepare("UPDATE reviews SET helpful_count = helpful_count + 1 WHERE id=:id")
            ->execute([':id' => $reviewId]);
        respond(200, ['helpful' => true]);
    }
}

// ── POST /reviews/{id}/report ─────────────────────────────────────────────────
function reportReview(PDO $pdo, int $reviewId): void {
    $user = requireAuth($pdo);
    if (!$user) return;
    $body   = json_decode(file_get_contents('php://input'), true) ?? [];
    $reason = trim($body['reason'] ?? '');

    $pdo->exec("CREATE TABLE IF NOT EXISTS review_reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        review_id INT NOT NULL,
        reporter_id INT NOT NULL,
        reason VARCHAR(500),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB;");

    $pdo->prepare("INSERT INTO review_reports (review_id, reporter_id, reason) VALUES (:rid,:uid,:reason)")
        ->execute([':rid' => $reviewId, ':uid' => $user['id'], ':reason' => $reason]);

    respond(200, ['message' => 'Review reported']);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function updateProductRating(PDO $pdo, int $productId): void {
    $pdo->prepare(
        "UPDATE products p SET
            p.average_rating = (SELECT ROUND(AVG(rating),2) FROM reviews WHERE product_id = :pid AND status='approved'),
            p.review_count   = (SELECT COUNT(*) FROM reviews WHERE product_id = :pid2 AND status='approved')
         WHERE p.id = :pid3"
    )->execute([':pid' => $productId, ':pid2' => $productId, ':pid3' => $productId]);
}

function formatReview(array $r): array {
    return [
        'id'               => (int)$r['id'],
        'product_id'       => (int)$r['product_id'],
        'user_id'          => (int)$r['user_id'],
        'rating'           => (int)$r['rating'],
        'title'            => $r['title'] ?? null,
        'body'             => $r['body'],
        'helpful_count'    => (int)($r['helpful_count'] ?? 0),
        'marked_helpful'   => (bool)($r['marked_helpful'] ?? false),
        'status'           => $r['status'],
        'reviewer_name'    => $r['reviewer_name'] ?? null,
        'reviewer_username'=> $r['reviewer_username'] ?? null,
        'reviewer_role'    => $r['reviewer_role'] ?? null,
        'created_at'       => $r['created_at'],
        'updated_at'       => $r['updated_at'] ?? null,
    ];
}

function getCurrentUserId(): ?int {
    try {
        $headers = getallheaders();
        $auth    = $headers['Authorization'] ?? '';
        if (preg_match('/Bearer\s+(.+)/', $auth, $m)) {
            $payload = verifyJWT($m[1]);
            return isset($payload['user_id']) ? (int)$payload['user_id'] : null;
        }
    } catch (\Exception $e) {}
    return null;
}

function requireAuth(PDO $pdo): ?array {
    $userId = getCurrentUserId();
    if (!$userId) {
        respond(401, ['error' => 'Authentication required']);
        return null;
    }
    $stmt = $pdo->prepare("SELECT id, role, user_status FROM users WHERE id = :id");
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user || !$user['user_status']) {
        respond(403, ['error' => 'Account inactive']);
        return null;
    }
    return $user;
}

function respond(int $code, array $data): void {
    http_response_code($code);
    echo json_encode($data);
}