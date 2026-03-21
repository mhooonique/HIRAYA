<?php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/jwt.php';

function getMe(): void {
    $user = getAuthUser();
    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo = getDB();
        // Auto-add columns if missing
        try { $pdo->exec('ALTER TABLE users ADD COLUMN IF NOT EXISTS social_links JSON NULL'); } catch (Exception $ignored) {}
        try { $pdo->exec('ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_base64 MEDIUMTEXT NULL'); } catch (Exception $ignored) {}
        $stmt = $pdo->prepare('SELECT id, first_name, last_name, username, email, role, kyc_status, user_status, phone, date_of_birth, city, province, social_links, avatar_base64 FROM users WHERE id = ?');
        $stmt->execute([$user['user_id']]);
        $u = $stmt->fetch();
        if ($u) {
            $u['social_links'] = json_decode($u['social_links'] ?? 'null', true) ?? [];
        }
        echo json_encode(['success' => true, 'user' => $u]);
    } catch (Exception $e) {
        echo json_encode(['success' => false]);
    }
}

function updateAvatar(): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo  = getDB();
        try { $pdo->exec('ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_base64 MEDIUMTEXT NULL'); } catch (Exception $ignored) {}

        $body         = json_decode(file_get_contents('php://input'), true) ?? [];
        $avatarBase64 = trim((string)($body['avatar_base64'] ?? ''));

        // Strip data URL prefix if present (e.g. "data:image/jpeg;base64,")
        if (str_contains($avatarBase64, ',')) {
            $avatarBase64 = substr($avatarBase64, strpos($avatarBase64, ',') + 1);
        }

        // Validate: ~300 KB binary = ~410 KB base64 ≈ 420 000 chars
        if (strlen($avatarBase64) > 420000) {
            http_response_code(413);
            echo json_encode(['success' => false, 'message' => 'Image too large. Please use an image under 300 KB.']);
            return;
        }

        // Allow clearing avatar with empty string
        $value = $avatarBase64 === '' ? null : $avatarBase64;

        $pdo->prepare('UPDATE users SET avatar_base64 = ? WHERE id = ?')
            ->execute([$value, $user['user_id']]);

        echo json_encode(['success' => true]);
    } catch (Exception $e) {
        error_log('updateAvatar: ' . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function updateSocialLinks(): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo  = getDB();
        $body = json_decode(file_get_contents('php://input'), true) ?? [];

        $facebook  = trim((string)($body['facebook']  ?? ''));
        $instagram = trim((string)($body['instagram'] ?? ''));
        $linkedin  = trim((string)($body['linkedin']  ?? ''));
        $x         = trim((string)($body['x']         ?? ''));

        // Validate: allow empty strings or valid URLs
        foreach (['facebook' => $facebook, 'instagram' => $instagram, 'linkedin' => $linkedin, 'x' => $x] as $key => $val) {
            if ($val !== '' && !filter_var($val, FILTER_VALIDATE_URL)) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => "Invalid URL for $key."]);
                return;
            }
        }

        $pdo->prepare('
            UPDATE users
            SET social_links = JSON_OBJECT("facebook", :fb, "instagram", :ig, "linkedin", :li, "x", :x)
            WHERE id = :id
        ')->execute([
            ':fb' => $facebook,
            ':ig' => $instagram,
            ':li' => $linkedin,
            ':x'  => $x,
            ':id' => $user['user_id'],
        ]);

        echo json_encode(['success' => true]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function getUser(int $id): void {
    try {
        $pdo  = getDB();
        $stmt = $pdo->prepare('
            SELECT id, first_name, last_name, username, role, kyc_status
            FROM users WHERE id = ? AND user_status = 1
        ');
        $stmt->execute([$id]);
        $u = $stmt->fetch();
        if (!$u) {
            echo json_encode(['success' => false, 'message' => 'User not found.']);
            return;
        }
        echo json_encode(['success' => true, 'data' => $u]);
    } catch (Exception $e) {
        echo json_encode(['success' => false]);
    }
}

function getPublicProfile(int $id): void {
    try {
        $pdo = getDB();

        // Ensure columns exist
        try { $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS social_links JSON NULL"); } catch (Exception $e) {}
        try { $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_base64 MEDIUMTEXT NULL"); } catch (Exception $e) {}

        // Get user (public info only — no sensitive data)
        $stmt = $pdo->prepare('
            SELECT id, first_name, last_name, username, role, kyc_status, social_links, avatar_base64
            FROM users WHERE id = ? AND user_status = 1
        ');
        $stmt->execute([$id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found.']);
            return;
        }

        // Decode social_links
        $user['social_links'] = !empty($user['social_links'])
            ? json_decode($user['social_links'], true)
            : (object)[];

        // Get their approved products
        $prodStmt = $pdo->prepare('
            SELECT p.id, p.name, p.description, p.category, p.images, p.likes, p.views,
                   p.interest_count, p.status, p.external_link, p.created_at,
                   u.name AS innovator_name, u.username AS innovator_username,
                   u.id AS innovator_id, u.kyc_status
            FROM products p
            LEFT JOIN users u ON u.id = p.user_id
            WHERE p.user_id = ? AND p.status = ? AND p.is_draft = 0
            ORDER BY p.created_at DESC
        ');
        $prodStmt->execute([$id, 'approved']);
        $products = $prodStmt->fetchAll(PDO::FETCH_ASSOC);

        // Format products
        $formatted = array_map(function($p) {
            $p['images']         = json_decode($p['images'] ?? '[]', true) ?? [];
            $p['interest_count'] = (int)($p['interest_count'] ?? 0);
            $p['likes']          = (int)($p['likes'] ?? 0);
            $p['views']          = (int)($p['views'] ?? 0);
            return $p;
        }, $products);

        $user['products'] = $formatted;

        echo json_encode(['success' => true, 'data' => $user]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false]);
    }
}