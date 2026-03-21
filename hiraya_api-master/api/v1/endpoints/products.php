<?php
// hiraya_api/api/v1/endpoints/products.php

function _ensureNotifTable(PDO $pdo): void {
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
}

function _productsNotifyAdmins(PDO $pdo, string $type, string $title, string $body, string $url = ''): void {
    try {
        _ensureNotifTable($pdo);
        $admins = $pdo->query("SELECT id FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_COLUMN);
        $stmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)");
        foreach ($admins as $adminId) {
            $stmt->execute([$adminId, $type, $title, $body, $url]);
        }
    } catch (\Exception $e) { error_log('productsNotifyAdmins: ' . $e->getMessage()); }
}

function _productsNotifyUser(PDO $pdo, int $userId, string $type, string $title, string $body, string $url = ''): void {
    try {
        _ensureNotifTable($pdo);
        $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)")
            ->execute([$userId, $type, $title, $body, $url]);
    } catch (\Exception $e) { error_log('productsNotifyUser: ' . $e->getMessage()); }
}

function getProducts(): void {
    try {
        $pdo  = getDB();
        $stmt = $pdo->query('
            SELECT p.id, p.user_id, p.name, p.description, p.category,
                   p.images, p.likes, p.views, p.interest_count,
                   p.status, p.created_at, p.stage, p.tags,
                   p.external_link, p.qr_image, p.video_filename,
                   u.first_name, u.last_name, u.username as innovator_username,
                   u.kyc_status,
                   CONCAT(u.first_name, " ", u.last_name) as innovator_name,
                   u.id as innovator_id
            FROM products p
            JOIN users u ON p.user_id = u.id
            WHERE p.status = "approved" AND (p.is_draft = 0 OR p.is_draft IS NULL)
            ORDER BY p.created_at DESC
        ');
        $products = $stmt->fetchAll();
        foreach ($products as &$p) {
            $p['images']         = json_decode($p['images'] ?? '[]', true) ?? [];
            $p['likes']          = (int)$p['likes'];
            $p['views']          = (int)$p['views'];
            $p['interest_count'] = (int)$p['interest_count'];
        }
        echo json_encode(['success' => true, 'data' => $products]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function getProduct(int $id): void {
    try {
        $pdo  = getDB();
        try { $pdo->exec('ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_base64 MEDIUMTEXT NULL'); } catch (Exception $ignored) {}
        $stmt = $pdo->prepare('
            SELECT p.*,
                   CONCAT(u.first_name, " ", u.last_name) as innovator_name,
                   u.username as innovator_username,
                   u.kyc_status,
                   u.id as innovator_id,
                   u.avatar_base64 as innovator_avatar_base64
            FROM products p
            JOIN users u ON p.user_id = u.id
            WHERE p.id = ? AND p.status = "approved"
        ');
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        if (!$product) {
            echo json_encode(['success' => false, 'message' => 'Product not found.']);
            return;
        }
        $pdo->prepare('UPDATE products SET views = views + 1 WHERE id = ?')->execute([$id]);
        $product['images'] = json_decode($product['images'] ?? '[]', true) ?? [];
        echo json_encode(['success' => true, 'data' => $product]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function likeProduct(int $id): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Login required.']);
        return;
    }
    try {
        $pdo = getDB();
        // Ensure product_likes table exists
        $pdo->exec("CREATE TABLE IF NOT EXISTS product_likes (
            user_id    INT NOT NULL,
            product_id INT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, product_id)
        ) ENGINE=InnoDB;");

        // Check if already liked
        $check = $pdo->prepare("SELECT 1 FROM product_likes WHERE user_id = ? AND product_id = ? LIMIT 1");
        $check->execute([$user['user_id'], $id]);

        if ($check->fetch()) {
            // Unlike
            $pdo->prepare("DELETE FROM product_likes WHERE user_id = ? AND product_id = ?")->execute([$user['user_id'], $id]);
            $pdo->prepare("UPDATE products SET likes = GREATEST(0, likes - 1) WHERE id = ?")->execute([$id]);
            echo json_encode(['success' => true, 'liked' => false]);
        } else {
            // Like — notify the innovator
            $pdo->prepare("INSERT IGNORE INTO product_likes (user_id, product_id) VALUES (?, ?)")->execute([$user['user_id'], $id]);
            $pdo->prepare("UPDATE products SET likes = likes + 1 WHERE id = ?")->execute([$id]);

            $pInfo = $pdo->prepare("SELECT p.name, p.user_id, u.username FROM products p JOIN users u ON u.id = ? WHERE p.id = ?");
            $pInfo->execute([$user['user_id'], $id]);
            $pRow = $pInfo->fetch(PDO::FETCH_ASSOC);
            if ($pRow && $pRow['user_id'] != $user['user_id']) {
                _productsNotifyUser(
                    $pdo,
                    (int)$pRow['user_id'],
                    'product_liked',
                    'Someone liked your product',
                    "@{$pRow['username']} liked your product \"{$pRow['name']}\"",
                    "/product/{$id}"
                );
            }

            echo json_encode(['success' => true, 'liked' => true]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function getLikedProductIds(): void {
    $user = getAuthUser();
    if (!$user) {
        echo json_encode(['success' => true, 'data' => []]);
        return;
    }
    try {
        $pdo = getDB();
        $pdo->exec("CREATE TABLE IF NOT EXISTS product_likes (
            user_id    INT NOT NULL,
            product_id INT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, product_id)
        ) ENGINE=InnoDB;");
        $stmt = $pdo->prepare("SELECT product_id FROM product_likes WHERE user_id = ?");
        $stmt->execute([$user['user_id']]);
        $ids = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'product_id');
        echo json_encode(['success' => true, 'data' => array_map('intval', $ids)]);
    } catch (Exception $e) {
        echo json_encode(['success' => true, 'data' => []]);
    }
}

function expressInterest(int $id, array $body): void {
    $user = getAuthUser();
    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'Login required.']);
        return;
    }
    try {
        $pdo  = getDB();
        $stmt = $pdo->prepare('SELECT id FROM product_interactions WHERE product_id = ? AND user_id = ? AND type = "interest"');
        $stmt->execute([$id, $user['user_id']]);
        if ($stmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'Already expressed interest.']);
            return;
        }
        $pdo->prepare('INSERT INTO product_interactions (product_id, user_id, type, created_at) VALUES (?, ?, "interest", NOW())')
            ->execute([$id, $user['user_id']]);
        $pdo->prepare('UPDATE products SET interest_count = interest_count + 1 WHERE id = ?')->execute([$id]);

        // Notify the innovator
        $pInfo = $pdo->prepare("SELECT p.name, p.user_id, u.username FROM products p JOIN users u ON u.id = ? WHERE p.id = ?");
        $pInfo->execute([$user['user_id'], $id]);
        $pRow = $pInfo->fetch(PDO::FETCH_ASSOC);
        if ($pRow && $pRow['user_id'] != $user['user_id']) {
            _productsNotifyUser(
                $pdo,
                (int)$pRow['user_id'],
                'new_interest',
                'New interest in your product',
                "@{$pRow['username']} expressed interest in your product \"{$pRow['name']}\"",
                "/product/{$id}"
            );
        }

        echo json_encode(['success' => true, 'message' => 'Interest expressed.']);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function createProduct(array $body): void {
    $user = getAuthUser();
    if (!$user || $user['role'] !== 'innovator') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Innovator access required.']);
        return;
    }
    $pdo     = getDB();
    $isDraft = (bool)($body['is_draft'] ?? false);

    if (!$isDraft) {
        if (empty($body['name']) || empty($body['description']) || empty($body['category'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Name, description, and category are required.']);
            return;
        }
        if (count($body['images'] ?? []) < 5) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'At least 5 images are required.']);
            return;
        }
    }

    try {
        // Check for existing draft — update it
        $existingDraft = $pdo->prepare("SELECT id FROM products WHERE user_id = ? AND is_draft = 1 LIMIT 1");
        $existingDraft->execute([$user['user_id']]);
        $draft = $existingDraft->fetch();

        if ($draft && $isDraft) {
            $pdo->prepare('
                UPDATE products SET
                    name           = :name,
                    description    = :desc,
                    category       = :cat,
                    images         = :images,
                    video_base64   = :video,
                    video_filename = :vname,
                    external_link  = :link,
                    qr_image       = :qr,
                    updated_at     = NOW()
                WHERE id = :id AND user_id = :uid
            ')->execute([
                ':name'   => $body['name']          ?? '',
                ':desc'   => $body['description']   ?? '',
                ':cat'    => $body['category']       ?? '',
                ':images' => json_encode($body['images'] ?? []),
                ':video'  => $body['video_base64']   ?? null,
                ':vname'  => $body['video_filename'] ?? null,
                ':link'   => $body['external_link']  ?? null,
                ':qr'     => $body['qr_image']        ?? null,
                ':id'     => $draft['id'],
                ':uid'    => $user['user_id'],
            ]);
            echo json_encode(['success' => true, 'message' => 'Draft saved.', 'id' => $draft['id']]);
            return;
        }

        $pdo->prepare('
            INSERT INTO products
                (user_id, name, description, category, images,
                 video_base64, video_filename, external_link, qr_image,
                 is_draft, status, created_at)
            VALUES
                (:uid, :name, :desc, :cat, :images,
                 :video, :vname, :link, :qr,
                 :draft, "pending", NOW())
        ')->execute([
            ':uid'    => $user['user_id'],
            ':name'   => $body['name']          ?? '',
            ':desc'   => $body['description']   ?? '',
            ':cat'    => $body['category']       ?? '',
            ':images' => json_encode($body['images'] ?? []),
            ':video'  => $body['video_base64']   ?? null,
            ':vname'  => $body['video_filename'] ?? null,
            ':link'   => $body['external_link']  ?? null,
            ':qr'     => $body['qr_image']        ?? null,
            ':draft'  => $isDraft ? 1 : 0,
        ]);

        $newId = (int)$pdo->lastInsertId();
        if (!$isDraft) {
            $productName = $body['name'] ?? '';
            try {
                _productsNotifyAdmins($pdo, 'product_submitted', 'New Product Pending Review', "A product \"{$productName}\" has been submitted and is waiting for your review.", '/admin');
            } catch (\Exception $e) { error_log('createProduct notify: ' . $e->getMessage()); }
        }
        echo json_encode([
            'success' => true,
            'message' => $isDraft ? 'Draft saved.' : 'Product submitted for review.',
            'id'      => $newId,
        ]);
    } catch (Exception $e) {
        error_log('createProduct error: ' . $e->getMessage());
        error_log('products error: ' . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'An error occurred. Please try again.']);
    }
}

function updateProduct(int $id, array $body): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo     = getDB();
        $isDraft = (bool)($body['is_draft'] ?? false);
        $pdo->prepare('
            UPDATE products SET
                name           = :name,
                description    = :desc,
                category       = :cat,
                images         = :images,
                video_base64   = :video,
                video_filename = :vname,
                external_link  = :link,
                qr_image       = :qr,
                is_draft       = :draft,
                updated_at     = NOW()
            WHERE id = :id AND user_id = :uid
        ')->execute([
            ':name'   => $body['name']          ?? '',
            ':desc'   => $body['description']   ?? '',
            ':cat'    => $body['category']       ?? '',
            ':images' => json_encode($body['images'] ?? []),
            ':video'  => $body['video_base64']   ?? null,
            ':vname'  => $body['video_filename'] ?? null,
            ':link'   => $body['external_link']  ?? null,
            ':qr'     => $body['qr_image']        ?? null,
            ':draft'  => $isDraft ? 1 : 0,
            ':id'     => $id,
            ':uid'    => $user['user_id'],
        ]);
        echo json_encode(['success' => true]);
    } catch (Exception $e) {
        echo json_encode(['success' => false]);
    }
}

function getMyProducts(): void {
    $user = getAuthUser();
    if (!$user) {
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo  = getDB();
        $stmt = $pdo->prepare('
            SELECT p.id, p.user_id, p.name, p.description, p.category,
                   p.images, p.likes, p.views, p.interest_count,
                   p.status, p.created_at, p.is_draft,
                   p.external_link, p.video_filename,
                   CONCAT(u.first_name, " ", u.last_name) as innovator_name,
                   u.username as innovator_username,
                   u.kyc_status,
                   u.id as innovator_id
            FROM products p
            JOIN users u ON p.user_id = u.id
            WHERE p.user_id = ?
            ORDER BY p.created_at DESC
        ');
        $stmt->execute([$user['user_id']]);
        $products = $stmt->fetchAll();
        foreach ($products as &$p) {
            $p['images']         = json_decode($p['images'] ?? '[]', true) ?? [];
            $p['likes']          = (int)$p['likes'];
            $p['views']          = (int)$p['views'];
            $p['interest_count'] = (int)$p['interest_count'];
            $p['is_draft']       = (int)($p['is_draft'] ?? 0);
        }
        echo json_encode(['success' => true, 'data' => $products]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function getMyDraft(): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo  = getDB();
        $stmt = $pdo->prepare(
            "SELECT * FROM products WHERE user_id = ? AND is_draft = 1 ORDER BY updated_at DESC LIMIT 1"
        );
        $stmt->execute([$user['user_id']]);
        $draft = $stmt->fetch();
        if (!$draft) {
            echo json_encode(['success' => false, 'message' => 'No draft found.']);
            return;
        }
        $draft['images'] = json_decode($draft['images'] ?? '[]', true) ?? [];
        echo json_encode(['success' => true, 'data' => $draft]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

function deleteDraft(int $id): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }
    try {
        $pdo = getDB();
        $pdo->prepare("DELETE FROM products WHERE id = ? AND user_id = ? AND is_draft = 1")
            ->execute([$id, $user['user_id']]);
        echo json_encode(['success' => true, 'message' => 'Draft deleted.']);
    } catch (Exception $e) {
        echo json_encode(['success' => false]);
    }
}

function getProductAdmin(int $id): void {
    $user = getAuthUser();
    if (!$user || $user['role'] !== 'admin') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Admin access required.']);
        return;
    }
    try {
        $pdo  = getDB();
        $stmt = $pdo->prepare('
            SELECT p.*,
                   CONCAT(u.first_name, " ", u.last_name) as innovator_name,
                   u.username as innovator_username,
                   u.kyc_status, u.id as innovator_id,
                   u.email as innovator_email
            FROM products p
            JOIN users u ON p.user_id = u.id
            WHERE p.id = ?
        ');
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        if (!$product) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Product not found.']);
            return;
        }
        $product['images'] = json_decode($product['images'] ?? '[]', true) ?? [];
        echo json_encode(['success' => true, 'data' => $product]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Server error.']);
    }
}

// ── Wishlist & Bookmark Handler ───────────────────────────────────────────────
function handleWishlistBookmark(PDO $pdo, string $method, array $segments): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }

    // Auto-create tables
    $pdo->exec('
        CREATE TABLE IF NOT EXISTS wishlists (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            product_id INT UNSIGNED NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uq_wishlist (user_id, product_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ');
    $pdo->exec('
        CREATE TABLE IF NOT EXISTS bookmarks (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            product_id INT UNSIGNED NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uq_bookmark (user_id, product_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ');

    $userId    = $user['user_id'];
    $sub       = $segments[1] ?? null;   // 'wishlist' | 'bookmarks' | numeric id
    $action    = $segments[2] ?? null;   // 'wishlist' | 'bookmark' (when sub is numeric)
    $productId = (is_numeric($sub)) ? (int)$sub : null;

    try {
        // GET products/wishlist
        if ($sub === 'wishlist' && $method === 'GET') {
            $stmt = $pdo->prepare('
                SELECT p.id, p.name, p.description, p.category,
                       p.likes, p.views, p.interest_count, p.status,
                       CONCAT(u.first_name, " ", u.last_name) AS innovator_name,
                       u.username AS innovator_username,
                       u.id AS innovator_id, u.kyc_status
                FROM wishlists w
                JOIN products p ON p.id = w.product_id
                JOIN users u ON u.id = p.user_id
                WHERE w.user_id = ?
                ORDER BY w.created_at DESC
            ');
            $stmt->execute([$userId]);
            $rows = $stmt->fetchAll();
            foreach ($rows as &$r) {
                $r['likes']          = (int)$r['likes'];
                $r['views']          = (int)$r['views'];
                $r['interest_count'] = (int)$r['interest_count'];
            }
            echo json_encode(['success' => true, 'data' => $rows]);
            return;
        }

        // GET products/bookmarks
        if ($sub === 'bookmarks' && $method === 'GET') {
            $stmt = $pdo->prepare('
                SELECT p.id, p.name, p.description, p.category,
                       p.likes, p.views, p.interest_count, p.status,
                       CONCAT(u.first_name, " ", u.last_name) AS innovator_name,
                       u.username AS innovator_username,
                       u.id AS innovator_id, u.kyc_status
                FROM bookmarks b
                JOIN products p ON p.id = b.product_id
                JOIN users u ON u.id = p.user_id
                WHERE b.user_id = ?
                ORDER BY b.created_at DESC
            ');
            $stmt->execute([$userId]);
            $rows = $stmt->fetchAll();
            foreach ($rows as &$r) {
                $r['likes']          = (int)$r['likes'];
                $r['views']          = (int)$r['views'];
                $r['interest_count'] = (int)$r['interest_count'];
            }
            echo json_encode(['success' => true, 'data' => $rows]);
            return;
        }

        // POST products/{id}/wishlist
        if ($productId && $action === 'wishlist' && $method === 'POST') {
            $pdo->prepare('INSERT IGNORE INTO wishlists (user_id, product_id) VALUES (?, ?)')
                ->execute([$userId, $productId]);
            echo json_encode(['success' => true]);
            return;
        }

        // DELETE products/{id}/wishlist
        if ($productId && $action === 'wishlist' && $method === 'DELETE') {
            $pdo->prepare('DELETE FROM wishlists WHERE user_id = ? AND product_id = ?')
                ->execute([$userId, $productId]);
            echo json_encode(['success' => true]);
            return;
        }

        // POST products/{id}/bookmark
        if ($productId && $action === 'bookmark' && $method === 'POST') {
            $pdo->prepare('INSERT IGNORE INTO bookmarks (user_id, product_id) VALUES (?, ?)')
                ->execute([$userId, $productId]);
            echo json_encode(['success' => true]);
            return;
        }

        // DELETE products/{id}/bookmark
        if ($productId && $action === 'bookmark' && $method === 'DELETE') {
            $pdo->prepare('DELETE FROM bookmarks WHERE user_id = ? AND product_id = ?')
                ->execute([$userId, $productId]);
            echo json_encode(['success' => true]);
            return;
        }

        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Route not found.']);
    } catch (Exception $e) {
        http_response_code(500);
        error_log('products error: ' . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'An error occurred. Please try again.']);
    }
}

// ── Router ────────────────────────────────────────────────────────────────────
function handleProducts(PDO $pdo, string $method, array $segments): void {
    $id     = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;
    $sub    = $segments[1] ?? null;
    $action = $segments[2] ?? null;

    if ($sub === 'my-draft' && $method === 'GET') { getMyDraft(); return; }
    if ($sub === 'likes'   && $method === 'GET') { getLikedProductIds(); return; }
    if ($id && $action === 'draft'    && $method === 'DELETE') { deleteDraft($id); return; }
    if ($id && $action === 'admin'    && $method === 'GET')    { getProductAdmin($id); return; }
    if ($id && $action === 'like'     && $method === 'POST')   { likeProduct($id); return; }
    if ($id && $action === 'interest')                         { expressInterest($id, json_decode(file_get_contents('php://input'), true) ?? []); return; }

    // Wishlist & Bookmark routes
    if ($sub === 'wishlist' || $sub === 'bookmarks')                  { handleWishlistBookmark($pdo, $method, $segments); return; }
    if ($id && ($action === 'wishlist' || $action === 'bookmark'))     { handleWishlistBookmark($pdo, $method, $segments); return; }

    match ($method) {
        'GET'   => $id ? getProduct($id) : getProducts(),
        'POST'  => createProduct(json_decode(file_get_contents('php://input'), true) ?? []),
        'PUT'   => $id ? updateProduct($id, json_decode(file_get_contents('php://input'), true) ?? []) : notFound(),
        default => notFound(),
    };
}