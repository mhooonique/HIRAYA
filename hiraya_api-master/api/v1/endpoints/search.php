<?php
// hiraya_api/api/v1/endpoints/search.php

function handleSearch(PDO $pdo, string $method, array $segments): void {
    if ($method !== 'GET') {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
        return;
    }

    $sub = $segments[1] ?? '';

    match ($sub) {
        'trending'    => getTrending($pdo),
        'suggestions' => getSuggestions($pdo),
        default       => searchProducts($pdo),
    };
}

// ── GET /search ───────────────────────────────────────────────────────────────
function searchProducts(PDO $pdo): void {
    $q         = trim($_GET['q'] ?? '');
    $category  = $_GET['category'] ?? null;
    $minRating = isset($_GET['min_rating']) ? (float)$_GET['min_rating'] : null;
    $sort      = $_GET['sort'] ?? 'trending';
    $verified  = isset($_GET['verified']) && $_GET['verified'] === '1';
    $available = isset($_GET['available']) && $_GET['available'] === '1';
    $page      = max(1, (int)($_GET['page'] ?? 1));
    $perPage   = 12;
    $offset    = ($page - 1) * $perPage;

    if (!empty($q)) {
        logSearch($pdo, $q);
    }

    $where  = ['p.status = "approved"'];
    $params = [];

    if (!empty($q)) {
        $where[]       = '(p.name LIKE :q OR p.description LIKE :q2 OR u.first_name LIKE :q3 OR u.last_name LIKE :q4)';
        $params[':q']  = "%{$q}%";
        $params[':q2'] = "%{$q}%";
        $params[':q3'] = "%{$q}%";
        $params[':q4'] = "%{$q}%";
    }

    if ($category) {
        $where[]             = 'p.category = :category';
        $params[':category'] = $category;
    }

    if ($minRating !== null) {
        $where[]               = 'COALESCE(avg_r.avg_rating, 0) >= :min_rating';
        $params[':min_rating'] = $minRating;
    }

    if ($verified) {
        $where[] = 'u.kyc_status = "verified"';
    }

    $whereSQL = implode(' AND ', $where);

    $orderSQL = match ($sort) {
        'newest'     => 'p.created_at DESC',
        'most_liked' => 'likes DESC',
        'most_viewed'=> 'views DESC',
        default      => '(views * 0.4 + likes * 0.6) DESC',
    };

    // Count
    $countSQL = "
        SELECT COUNT(*)
        FROM products p
        JOIN users u ON p.user_id = u.id
        LEFT JOIN (
            SELECT product_id, AVG(rating) AS avg_rating
            FROM reviews GROUP BY product_id
        ) avg_r ON avg_r.product_id = p.id
        WHERE {$whereSQL}
    ";
    $countStmt = $pdo->prepare($countSQL);
    $countStmt->execute($params);
    $total = (int)$countStmt->fetchColumn();

    // Data
    $dataSQL = "
        SELECT
            p.id, p.name, p.description, p.category,
            p.status, p.kyc_status, p.created_at,
            COALESCE(SUM(CASE WHEN pi.type = 'like'     THEN 1 END), 0) AS likes,
            COALESCE(SUM(CASE WHEN pi.type = 'view'     THEN 1 END), 0) AS views,
            COALESCE(SUM(CASE WHEN pi.type = 'interest' THEN 1 END), 0) AS interest_count,
            COALESCE(avg_r.avg_rating, NULL) AS avg_rating,
            CONCAT(u.first_name, ' ', u.last_name) AS innovator_name,
            u.username AS innovator_username,
            u.id AS innovator_id,
            u.kyc_status AS innovator_kyc,
            GROUP_CONCAT(DISTINCT img.image_url) AS image_urls
        FROM products p
        JOIN users u ON p.user_id = u.id
        LEFT JOIN product_interactions pi ON pi.product_id = p.id
        LEFT JOIN product_images img ON img.product_id = p.id
        LEFT JOIN (
            SELECT product_id, AVG(rating) AS avg_rating
            FROM reviews GROUP BY product_id
        ) avg_r ON avg_r.product_id = p.id
        WHERE {$whereSQL}
        GROUP BY p.id
        ORDER BY {$orderSQL}
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($dataSQL);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':limit',  $perPage, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset,  PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $products = array_map('formatSearchProduct', $rows);

    echo json_encode([
        'success'  => true,
        'products' => $products,
        'total'    => $total,
        'page'     => $page,
        'per_page' => $perPage,
        'has_more' => ($offset + $perPage) < $total,
    ]);
}

// ── GET /search/trending ──────────────────────────────────────────────────────
function getTrending(PDO $pdo): void {
    $productSQL = "
        SELECT
            p.id, p.name, p.description, p.category,
            p.status, p.kyc_status, p.created_at,
            COALESCE(SUM(CASE WHEN pi.type = 'like'     THEN 1 END), 0) AS likes,
            COALESCE(SUM(CASE WHEN pi.type = 'view'     THEN 1 END), 0) AS views,
            COALESCE(SUM(CASE WHEN pi.type = 'interest' THEN 1 END), 0) AS interest_count,
            CONCAT(u.first_name, ' ', u.last_name) AS innovator_name,
            u.username AS innovator_username,
            u.id AS innovator_id,
            u.kyc_status AS innovator_kyc,
            GROUP_CONCAT(DISTINCT img.image_url) AS image_urls
        FROM products p
        JOIN users u ON p.user_id = u.id
        LEFT JOIN product_interactions pi ON pi.product_id = p.id
        LEFT JOIN product_images img ON img.product_id = p.id
        WHERE p.status = 'approved'
        GROUP BY p.id
        ORDER BY (
            COALESCE(SUM(CASE WHEN pi.type = 'view' THEN 1 END), 0) * 0.4 +
            COALESCE(SUM(CASE WHEN pi.type = 'like' THEN 1 END), 0) * 0.6
        ) DESC
        LIMIT 8
    ";

    $stmt     = $pdo->query($productSQL);
    $products = array_map('formatSearchProduct', $stmt->fetchAll(PDO::FETCH_ASSOC));

    $topicsSQL = "
        SELECT
            keyword,
            SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS recent_count,
            SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)
                      AND created_at >= DATE_SUB(NOW(), INTERVAL 14 DAY) THEN 1 ELSE 0 END) AS prior_count,
            COUNT(*) AS search_count
        FROM search_log
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 14 DAY)
        GROUP BY keyword
        ORDER BY search_count DESC
        LIMIT 10
    ";

    try {
        $tStmt  = $pdo->query($topicsSQL);
        $tRows  = $tStmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (\Exception $e) {
        $tRows = [];
    }

    $topics = array_map(function ($r) {
        $prior  = max(1, (int)$r['prior_count']);
        $recent = (int)$r['recent_count'];
        $change = round((($recent - $prior) / $prior) * 100, 1);
        return [
            'keyword'        => $r['keyword'],
            'search_count'   => (int)$r['search_count'],
            'change_percent' => $change,
        ];
    }, $tRows);

    echo json_encode([
        'success'            => true,
        'trending_products'  => $products,
        'trending_topics'    => $topics,
    ]);
}

// ── GET /search/suggestions ───────────────────────────────────────────────────
function getSuggestions(PDO $pdo): void {
    $q = trim($_GET['q'] ?? '');
    if (strlen($q) < 2) {
        echo json_encode(['success' => true, 'suggestions' => []]);
        return;
    }

    $suggestions = [];

    $pStmt = $pdo->prepare(
        "SELECT DISTINCT p.name FROM products p
         WHERE p.status = 'approved' AND p.name LIKE :q
         ORDER BY p.created_at DESC LIMIT 4"
    );
    $pStmt->execute([':q' => "%{$q}%"]);
    $suggestions = array_merge($suggestions, $pStmt->fetchAll(PDO::FETCH_COLUMN));

    try {
        $sStmt = $pdo->prepare(
            "SELECT DISTINCT keyword FROM search_log
             WHERE keyword LIKE :q
             GROUP BY keyword ORDER BY COUNT(*) DESC LIMIT 4"
        );
        $sStmt->execute([':q' => "%{$q}%"]);
        $suggestions = array_merge($suggestions, $sStmt->fetchAll(PDO::FETCH_COLUMN));
    } catch (\Exception $e) {}

    $suggestions = array_slice(array_values(array_unique($suggestions)), 0, 6);
    echo json_encode(['success' => true, 'suggestions' => $suggestions]);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function logSearch(PDO $pdo, string $keyword): void {
    $pdo->exec("CREATE TABLE IF NOT EXISTS search_log (
        id INT AUTO_INCREMENT PRIMARY KEY,
        keyword VARCHAR(255) NOT NULL,
        user_id INT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_keyword (keyword),
        INDEX idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $userId = null;
    try {
        $headers = getallheaders();
        $auth    = $headers['Authorization'] ?? '';
        if (preg_match('/Bearer\s+(.+)/', $auth, $m)) {
            $payload = verifyJWT($m[1]);
            $userId  = $payload['user_id'] ?? null;
        }
    } catch (\Exception $e) {}

    $stmt = $pdo->prepare("INSERT INTO search_log (keyword, user_id) VALUES (:kw, :uid)");
    $stmt->execute([':kw' => strtolower(trim($keyword)), ':uid' => $userId]);
}

function formatSearchProduct(array $r): array {
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
}