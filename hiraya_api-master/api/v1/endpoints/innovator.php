<?php
// hiraya_api/api/v1/endpoints/innovator.php

function getInnovatorProducts(PDO $pdo): void {
    $userId = _innovatorAuth();
    if (!$userId) return;

    try {
        $stmt = $pdo->prepare("
            SELECT
                p.id, p.name, p.description, p.category,
                p.status, p.kyc_status, p.created_at,
                COALESCE(SUM(CASE WHEN pi.type = 'like'     THEN 1 END), 0) AS likes,
                COALESCE(SUM(CASE WHEN pi.type = 'view'     THEN 1 END), 0) AS views,
                COALESCE(SUM(CASE WHEN pi.type = 'interest' THEN 1 END), 0) AS interest_count,
                CONCAT(u.first_name, ' ', u.last_name) AS innovator_name,
                u.username AS innovator_username,
                u.id AS innovator_id,
                GROUP_CONCAT(DISTINCT img.image_url) AS image_urls
            FROM products p
            JOIN users u ON p.user_id = u.id
            LEFT JOIN product_interactions pi ON pi.product_id = p.id
            LEFT JOIN product_images img ON img.product_id = p.id
            WHERE p.user_id = :uid
            GROUP BY p.id
            ORDER BY p.created_at DESC
        ");
        $stmt->execute([':uid' => $userId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $products = array_map(function ($r) {
            return [
                'id'                 => (int)$r['id'],
                'name'               => $r['name'],
                'description'        => $r['description'],
                'category'           => $r['category'],
                'status'             => $r['status'],
                'kyc_status'         => $r['kyc_status'],
                'likes'              => (int)$r['likes'],
                'views'              => (int)$r['views'],
                'interest_count'     => (int)$r['interest_count'],
                'innovator_name'     => $r['innovator_name'],
                'innovator_username' => $r['innovator_username'],
                'innovator_id'       => (int)$r['innovator_id'],
                'images'             => $r['image_urls'] ? explode(',', $r['image_urls']) : [],
                'created_at'         => $r['created_at'],
            ];
        }, $rows);

        echo json_encode(['success' => true, 'data' => $products]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

function submitProduct(PDO $pdo): void {
    $userId = _innovatorAuth();
    if (!$userId) return;

    $body        = json_decode(file_get_contents('php://input'), true) ?? [];
    $name        = trim($body['name'] ?? '');
    $description = trim($body['description'] ?? '');
    $category    = trim($body['category'] ?? '');

    if (!$name || !$description || !$category) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'name, description, and category are required.']);
        return;
    }

    try {
        $stmt = $pdo->prepare("
            INSERT INTO products (user_id, name, description, category, status, kyc_status, created_at)
            VALUES (:uid, :name, :desc, :cat, 'pending', 'pending', NOW())
        ");
        $stmt->execute([
            ':uid'  => $userId,
            ':name' => $name,
            ':desc' => $description,
            ':cat'  => $category,
        ]);
        $id = (int)$pdo->lastInsertId();
        echo json_encode(['success' => true, 'message' => 'Product submitted for review.', 'id' => $id]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

// ── Private auth helper ───────────────────────────────────────────────────────
function _innovatorAuth(): ?int {
    $headers = getallheaders();
    $auth    = $headers['Authorization'] ?? '';
    if (!preg_match('/Bearer\s+(.+)/', $auth, $m)) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized']);
        return null;
    }
    try {
        $payload = verifyJWT($m[1]);
        $userId  = $payload['user_id'] ?? null;
        if (!$userId) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Unauthorized']);
            return null;
        }
        $role = $payload['role'] ?? '';
        if ($role !== 'innovator') {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Innovator access required']);
            return null;
        }
        return (int)$userId;
    } catch (Exception $e) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token']);
        return null;
    }
}

// ── Router ────────────────────────────────────────────────────────────────────
function handleInnovator(PDO $pdo, string $method, array $segments): void {
    $sub = $segments[1] ?? '';

    match (true) {
        $method === 'GET'  && $sub === 'products' => getInnovatorProducts($pdo),
        $method === 'POST' && $sub === 'products' => submitProduct($pdo),
        default => (function() {
            http_response_code(404);
            echo json_encode(['error' => 'Innovator route not found']);
        })(),
    };
}