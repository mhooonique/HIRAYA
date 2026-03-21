<?php
// hiraya_api/api/v1/endpoints/admin.php

require_once __DIR__ . '/../../../vendor/autoload.php';
require_once __DIR__ . '/../config/env.php';
require_once __DIR__ . '/../config/mail_config.php';
require_once __DIR__ . '/users.php';

function handleAdmin(PDO $pdo, string $method, array $segments): void {
    $user = getAuthUser();
    if (!$user || $user['role'] !== 'admin') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Admin access required.']);
        return;
    }

    $sub    = $segments[1] ?? '';
    $subId  = isset($segments[2]) && is_numeric($segments[2]) ? (int)$segments[2] : null;
    $action = $segments[3] ?? null;

    // GET /admin/pending
    if ($sub === 'pending' && $method === 'GET') {
        $stmt = $pdo->query('
            SELECT p.*, CONCAT(u.first_name, " ", u.last_name) as innovator_name,
                   u.username
            FROM products p
            JOIN users u ON p.user_id = u.id
            WHERE p.status = "pending"
            ORDER BY p.created_at ASC
        ');
        echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
        return;
    }

    // PUT /admin/products/{id}/approve
    if ($sub === 'products' && $action === 'approve' && $method === 'PUT') {
        $pdo->prepare('UPDATE products SET status = "approved" WHERE id = ?')
            ->execute([$subId]);
        _notifyProductOwner($pdo, $subId, true);
        echo json_encode(['success' => true]);
        return;
    }

    // PUT /admin/products/{id}/reject
    if ($sub === 'products' && $action === 'reject' && $method === 'PUT') {
        $pdo->prepare('UPDATE products SET status = "rejected" WHERE id = ?')
            ->execute([$subId]);
        _notifyProductOwner($pdo, $subId, false);
        echo json_encode(['success' => true]);
        return;
    }

    // GET /admin/users — list (no KYC blobs, fast for table)
    if ($sub === 'users' && $method === 'GET' && $subId === null) {
        $stmt = $pdo->query('
            SELECT id, first_name, last_name, username, email, role,
                   kyc_status, user_status, phone, created_at
            FROM users
            ORDER BY created_at DESC
        ');
        echo json_encode(['success' => true, 'data' => $stmt->fetchAll()]);
        return;
    }

    // GET /admin/users/{id} — full detail with KYC images
    if ($sub === 'users' && $method === 'GET' && $subId !== null && $action === null) {
        $stmt = $pdo->prepare('
            SELECT id, first_name, last_name, username, email, role,
                   kyc_status, user_status, phone,
                   date_of_birth, city, province,
                   gov_id_base64, gov_id_filename,
                   selfie_base64, selfie_filename
            FROM users WHERE id = ?
            LIMIT 1
        ');
        $stmt->execute([$subId]);
        $row = $stmt->fetch();
        if (!$row) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found.']);
            return;
        }
        echo json_encode(['success' => true, 'data' => $row]);
        return;
    }

    // PUT /admin/users/{id}/approve
    if ($sub === 'users' && $action === 'approve' && $method === 'PUT') {
        $pdo->prepare("UPDATE users SET user_status = 1, kyc_status = 'verified' WHERE id = ?")
            ->execute([$subId]);
        _trySendStatusEmail($pdo, $subId, true);
        _adminPushNotification($pdo, $subId, 'account_approved', 'Account Approved!', 'Your account has been verified. Welcome to HIRAYA!', '/client/dashboard');
        echo json_encode(['success' => true]);
        return;
    }

    // PUT /admin/users/{id}/reject
    if ($sub === 'users' && $action === 'reject' && $method === 'PUT') {
        $pdo->prepare("UPDATE users SET user_status = 2, kyc_status = 'rejected' WHERE id = ?")
            ->execute([$subId]);
        _trySendStatusEmail($pdo, $subId, false);
        _adminPushNotification($pdo, $subId, 'account_rejected', 'Account Update', 'Unfortunately your account was not approved.', '/login');
        echo json_encode(['success' => true]);
        return;
    }

    // PUT /admin/users/{id}/promote-admin
    if ($sub === 'users' && $action === 'promote-admin' && $method === 'PUT') {
        if ($subId === null) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'User ID required.']);
            return;
        }
        if ($subId === (int)$user['id']) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'You cannot change your own role.']);
            return;
        }
        $check = $pdo->prepare('SELECT id FROM users WHERE id = ? LIMIT 1');
        $check->execute([$subId]);
        if (!$check->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found.']);
            return;
        }
        $pdo->prepare("UPDATE users SET role = 'admin' WHERE id = ?")
            ->execute([$subId]);
        echo json_encode(['success' => true, 'message' => 'User promoted to admin.']);
        return;
    }

    // PUT /admin/users/{id}/demote-admin
    if ($sub === 'users' && $action === 'demote-admin' && $method === 'PUT') {
        if ($subId === null) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'User ID required.']);
            return;
        }
        if ($subId === (int)$user['id']) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'You cannot change your own role.']);
            return;
        }
        $check = $pdo->prepare('SELECT id FROM users WHERE id = ? LIMIT 1');
        $check->execute([$subId]);
        if (!$check->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found.']);
            return;
        }
        $pdo->prepare("UPDATE users SET role = 'client' WHERE id = ?")
            ->execute([$subId]);
        echo json_encode(['success' => true, 'message' => 'User demoted to client.']);
        return;
    }

    // DELETE /admin/users/{id}
    if ($sub === 'users' && $method === 'DELETE' && $subId !== null && $action === null) {
        $check = $pdo->prepare('SELECT id FROM users WHERE id = ? LIMIT 1');
        $check->execute([$subId]);
        if (!$check->fetch()) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found.']);
            return;
        }
        $pdo->prepare('DELETE FROM users WHERE id = ?')->execute([$subId]);
        echo json_encode(['success' => true, 'message' => 'User deleted.']);
        return;
    }

    // GET /admin/analytics/full — comprehensive analytics (MUST be before /admin/analytics)
    if ($sub === 'analytics' && ($segments[2] ?? '') === 'full' && $method === 'GET') {
        // DAU / MAU
        $dau = 0;
        $mau = 0;
        try {
            $dau = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE DATE(last_login) = CURDATE() AND role != 'admin'")->fetchColumn();
            $mau = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE last_login >= DATE_SUB(NOW(), INTERVAL 30 DAY) AND role != 'admin'")->fetchColumn();
        } catch (\Exception $e) { error_log('analytics/full dau/mau: ' . $e->getMessage()); }

        // Inactive users
        $inactive30 = 0;
        $inactive60 = 0;
        $inactive90 = 0;
        try {
            $inactive30 = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE (last_login IS NULL OR last_login < DATE_SUB(NOW(), INTERVAL 30 DAY)) AND user_status = 1 AND role != 'admin'")->fetchColumn();
            $inactive60 = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE (last_login IS NULL OR last_login < DATE_SUB(NOW(), INTERVAL 60 DAY)) AND user_status = 1 AND role != 'admin'")->fetchColumn();
            $inactive90 = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE (last_login IS NULL OR last_login < DATE_SUB(NOW(), INTERVAL 90 DAY)) AND user_status = 1 AND role != 'admin'")->fetchColumn();
        } catch (\Exception $e) { error_log('analytics/full inactive: ' . $e->getMessage()); }

        // User growth — last 12 months grouped by year/month
        $userGrowth = [];
        try {
            $growthRows = $pdo->query("
                SELECT
                    YEAR(created_at)  AS yr,
                    MONTH(created_at) AS mo,
                    SUM(CASE WHEN role = 'innovator' THEN 1 ELSE 0 END) AS innovators,
                    SUM(CASE WHEN role = 'client'    THEN 1 ELSE 0 END) AS clients
                FROM users
                WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
                  AND role != 'admin'
                GROUP BY yr, mo
                ORDER BY yr ASC, mo ASC
            ")->fetchAll(PDO::FETCH_ASSOC);

            $monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            foreach ($growthRows as $row) {
                $userGrowth[] = [
                    'month'      => $monthNames[(int)$row['mo'] - 1],
                    'innovators' => (int)$row['innovators'],
                    'clients'    => (int)$row['clients'],
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full user_growth: ' . $e->getMessage()); }

        // MoM stats
        $mom = ['this_month' => 0, 'last_month' => 0, 'this_month_innovators' => 0, 'this_month_clients' => 0, 'last_month_innovators' => 0, 'last_month_clients' => 0];
        try {
            $momRows = $pdo->query("
                SELECT
                    SUM(CASE WHEN MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE()) THEN 1 ELSE 0 END) AS this_month,
                    SUM(CASE WHEN MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN 1 ELSE 0 END) AS last_month,
                    SUM(CASE WHEN MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE()) AND role = 'innovator' THEN 1 ELSE 0 END) AS this_month_innovators,
                    SUM(CASE WHEN MONTH(created_at) = MONTH(CURDATE()) AND YEAR(created_at) = YEAR(CURDATE()) AND role = 'client' THEN 1 ELSE 0 END) AS this_month_clients,
                    SUM(CASE WHEN MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND role = 'innovator' THEN 1 ELSE 0 END) AS last_month_innovators,
                    SUM(CASE WHEN MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND role = 'client' THEN 1 ELSE 0 END) AS last_month_clients
                FROM users
                WHERE role != 'admin'
            ")->fetch(PDO::FETCH_ASSOC);

            if ($momRows) {
                $mom = [
                    'this_month'             => (int)$momRows['this_month'],
                    'last_month'             => (int)$momRows['last_month'],
                    'this_month_innovators'  => (int)$momRows['this_month_innovators'],
                    'this_month_clients'     => (int)$momRows['this_month_clients'],
                    'last_month_innovators'  => (int)$momRows['last_month_innovators'],
                    'last_month_clients'     => (int)$momRows['last_month_clients'],
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full mom: ' . $e->getMessage()); }

        // Leaderboard — most_products
        $mostProducts = [];
        try {
            $rows = $pdo->query("
                SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) AS name, u.username, u.role,
                       COUNT(p.id) AS value
                FROM users u
                LEFT JOIN products p ON p.user_id = u.id
                GROUP BY u.id
                ORDER BY value DESC
                LIMIT 10
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $r) {
                $mostProducts[] = [
                    'name'     => $r['name'],
                    'username' => $r['username'],
                    'role'     => $r['role'],
                    'value'    => (int)$r['value'],
                    'rank'     => $i + 1,
                    'metric'   => 'products uploaded',
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full most_products: ' . $e->getMessage()); }

        // Leaderboard — most_approved
        $mostApproved = [];
        try {
            $rows = $pdo->query("
                SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) AS name, u.username, u.role,
                       COUNT(p.id) AS value
                FROM users u
                LEFT JOIN products p ON p.user_id = u.id AND p.status = 'approved'
                WHERE u.role = 'innovator'
                GROUP BY u.id
                ORDER BY value DESC
                LIMIT 10
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $r) {
                $mostApproved[] = [
                    'name'     => $r['name'],
                    'username' => $r['username'],
                    'role'     => $r['role'],
                    'value'    => (int)$r['value'],
                    'rank'     => $i + 1,
                    'metric'   => 'approved products',
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full most_approved: ' . $e->getMessage()); }

        // Leaderboard — most_interest
        $mostInterest = [];
        try {
            $rows = $pdo->query("
                SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) AS name, u.username, u.role,
                       COUNT(pi.id) AS value
                FROM users u
                LEFT JOIN products p ON p.user_id = u.id
                LEFT JOIN product_interactions pi ON pi.product_id = p.id AND pi.type = 'interest'
                WHERE u.role = 'innovator'
                GROUP BY u.id
                ORDER BY value DESC
                LIMIT 10
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $r) {
                $mostInterest[] = [
                    'name'     => $r['name'],
                    'username' => $r['username'],
                    'role'     => $r['role'],
                    'value'    => (int)$r['value'],
                    'rank'     => $i + 1,
                    'metric'   => 'interests received',
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full most_interest: ' . $e->getMessage()); }

        // Leaderboard — most_liked
        $mostLiked = [];
        try {
            $rows = $pdo->query("
                SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) AS name, u.username, u.role,
                       COUNT(pi.id) AS value
                FROM users u
                LEFT JOIN products p ON p.user_id = u.id
                LEFT JOIN product_interactions pi ON pi.product_id = p.id AND pi.type = 'like'
                WHERE u.role = 'innovator'
                GROUP BY u.id
                ORDER BY value DESC
                LIMIT 10
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $i => $r) {
                $mostLiked[] = [
                    'name'     => $r['name'],
                    'username' => $r['username'],
                    'role'     => $r['role'],
                    'value'    => (int)$r['value'],
                    'rank'     => $i + 1,
                    'metric'   => 'likes received',
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full most_liked: ' . $e->getMessage()); }

        // Top products
        $topProducts = [];
        try {
            $rows = $pdo->query("
                SELECT p.name, p.category, p.created_at,
                       CONCAT(u.first_name, ' ', u.last_name) AS innovator,
                       u.username AS innovator_username,
                       COALESCE(SUM(CASE WHEN pi.type = 'like'     THEN 1 ELSE 0 END), 0) AS likes,
                       COALESCE(SUM(CASE WHEN pi.type = 'view'     THEN 1 ELSE 0 END), 0) AS views,
                       COALESCE(SUM(CASE WHEN pi.type = 'interest' THEN 1 ELSE 0 END), 0) AS interests
                FROM products p
                JOIN users u ON u.id = p.user_id
                LEFT JOIN product_interactions pi ON pi.product_id = p.id
                WHERE p.status = 'approved'
                GROUP BY p.id
                ORDER BY (likes + views + interests) DESC
                LIMIT 10
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $r) {
                $topProducts[] = [
                    'name'               => $r['name'],
                    'category'           => $r['category'],
                    'innovator'          => $r['innovator'],
                    'innovator_username' => $r['innovator_username'],
                    'likes'              => (int)$r['likes'],
                    'views'              => (int)$r['views'],
                    'interests'          => (int)$r['interests'],
                    'rising'             => strtotime($r['created_at']) >= strtotime('-30 days'),
                ];
            }
        } catch (\Exception $e) { error_log('analytics/full top_products: ' . $e->getMessage()); }

        // Category distribution
        $categoryDistribution = [];
        try {
            $categoryDistribution = $pdo->query("
                SELECT category, COUNT(*) AS count
                FROM products
                WHERE status = 'approved'
                GROUP BY category
                ORDER BY count DESC
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($categoryDistribution as &$c) {
                $c['count'] = (int)$c['count'];
            }
            unset($c);
        } catch (\Exception $e) { error_log('analytics/full category_dist: ' . $e->getMessage()); }

        // Product status distribution
        $productStatus = [];
        try {
            $productStatus = $pdo->query("
                SELECT status, COUNT(*) AS count
                FROM products
                GROUP BY status
                ORDER BY count DESC
            ")->fetchAll(PDO::FETCH_ASSOC);
            foreach ($productStatus as &$s) {
                $s['count'] = (int)$s['count'];
            }
            unset($s);
        } catch (\Exception $e) { error_log('analytics/full product_status: ' . $e->getMessage()); }

        echo json_encode([
            'success' => true,
            'data'    => [
                'dau'                  => $dau,
                'mau'                  => $mau,
                'inactive_30d'         => $inactive30,
                'inactive_60d'         => $inactive60,
                'inactive_90d'         => $inactive90,
                'user_growth'          => $userGrowth,
                'mom'                  => $mom,
                'leaderboard'          => [
                    'most_products' => $mostProducts,
                    'most_approved' => $mostApproved,
                    'most_interest' => $mostInterest,
                    'most_liked'    => $mostLiked,
                ],
                'top_products'         => $topProducts,
                'category_distribution' => $categoryDistribution,
                'product_status'       => $productStatus,
            ],
        ]);
        return;
    }

    // GET /admin/analytics
    if ($sub === 'analytics' && $method === 'GET') {
        $users     = $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
        $products  = $pdo->query('SELECT COUNT(*) FROM products WHERE status = "approved"')->fetchColumn();
        $pending   = $pdo->query('SELECT COUNT(*) FROM products WHERE status = "pending"')->fetchColumn();
        $interests = $pdo->query('SELECT COUNT(*) FROM product_interactions WHERE type = "interest"')->fetchColumn();

        echo json_encode([
            'success' => true,
            'data'    => [
                'total_users'      => (int)$users,
                'total_products'   => (int)$products,
                'pending_products' => (int)$pending,
                'total_interests'  => (int)$interests,
            ],
        ]);
        return;
    }

    // GET /admin/products/{id}
    if ($sub === 'products' && $method === 'GET' && $subId !== null && $action === null) {
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
        $stmt->execute([$subId]);
        $product = $stmt->fetch();
        if (!$product) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Product not found.']);
            return;
        }
        $product['images'] = json_decode($product['images'] ?? '[]', true) ?? [];
        echo json_encode(['success' => true, 'data' => $product]);
        return;
    }

    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Unknown admin endpoint.']);
}

function handleUsers(PDO $pdo, string $method, array $segments): void {
    $user = getAuthUser();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
        return;
    }

    // GET /users/me
    if (($segments[1] ?? '') === 'me' && $method === 'GET') {
        getMe();
        return;
    }

    // PUT /users/me/social
    if (($segments[1] ?? '') === 'me' && ($segments[2] ?? '') === 'social' && $method === 'PUT') {
        updateSocialLinks();
        return;
    }

    // PUT /users/me/avatar
    if (($segments[1] ?? '') === 'me' && ($segments[2] ?? '') === 'avatar' && $method === 'PUT') {
        updateAvatar();
        return;
    }

    // GET /users/{id}/profile  — public profile (auth required, no role restriction)
    $userId = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;
    if ($userId !== null && ($segments[2] ?? '') === 'profile' && $method === 'GET') {
        getPublicProfile($userId);
        return;
    }

    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Unknown users endpoint.']);
}

// ── Silent email helper ────────────────────────────────────────────────────────
function _trySendStatusEmail(PDO $pdo, int $userId, bool $approved): void {
    try {
        $stmt = $pdo->prepare('SELECT email, first_name FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $u = $stmt->fetch();
        if (!$u) return;

        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
        $mail->isSMTP();
        $mail->Host       = MAIL_HOST;
        $mail->SMTPAuth   = true;
        $mail->Username   = MAIL_USERNAME;
        $mail->Password   = MAIL_PASSWORD;
        $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = MAIL_PORT;
        $mail->setFrom(MAIL_FROM, MAIL_NAME);
        $mail->addAddress($u['email'], $u['first_name']);

        if ($approved) {
            $loginUrl      = env('APP_URL') . '/hiraya/login';
            $mail->Subject = 'Your Hiraya Account Has Been Approved!';
            $mail->Body    = "
                <h2>Welcome to Hiraya, {$u['first_name']}!</h2>
                <p>Your account has been <strong>approved</strong>. You can now log in and start exploring.</p>
                <p><a href='{$loginUrl}'
                      style='background:#00C49A;color:white;padding:12px 24px;
                             border-radius:8px;text-decoration:none;'>
                    Log In Now
                </a></p>
            ";
        } else {
            $mail->Subject = 'Hiraya Account Review Update';
            $mail->Body    = "
                <h2>Account Review Update</h2>
                <p>Hi {$u['first_name']}, unfortunately your account was
                   <strong>not approved</strong> at this time.</p>
                <p>Please contact support if you have questions.</p>
            ";
        }
        $mail->isHTML(true);
        $mail->send();
    } catch (\Exception $e) {
        error_log('Hiraya status email failed: ' . $e->getMessage());
    }
}

// ── Notification helpers ───────────────────────────────────────────────────────

// Notify all admin users
function _notifyAdmins(PDO $pdo, string $type, string $title, string $body, string $url = ''): void {
    try {
        _ensureNotifTable($pdo);
        $admins = $pdo->query("SELECT id FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_COLUMN);
        $stmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)");
        foreach ($admins as $adminId) {
            $stmt->execute([$adminId, $type, $title, $body, $url]);
        }
    } catch (\Exception $e) { error_log('notifyAdmins: ' . $e->getMessage()); }
}

// Notify a single user
function _adminPushNotification(PDO $pdo, int $userId, string $type, string $title, string $body, string $url = ''): void {
    try {
        _ensureNotifTable($pdo);
        $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)")
            ->execute([$userId, $type, $title, $body, $url]);
    } catch (\Exception $e) { error_log('adminPushNotif: ' . $e->getMessage()); }
}

// Notify product owner when product approved/rejected
function _notifyProductOwner(PDO $pdo, int $productId, bool $approved): void {
    try {
        $stmt = $pdo->prepare('SELECT user_id, name FROM products WHERE id = ? LIMIT 1');
        $stmt->execute([$productId]);
        $p = $stmt->fetch();
        if (!$p) return;
        if ($approved) {
            _adminPushNotification($pdo, (int)$p['user_id'], 'product_approved',
                'Product Approved!', "Your product \"{$p['name']}\" is now live on the marketplace.", '/innovator/dashboard');
        } else {
            _adminPushNotification($pdo, (int)$p['user_id'], 'product_rejected',
                'Product Not Approved', "Your product \"{$p['name']}\" was not approved. Please review and resubmit.", '/innovator/dashboard');
        }
    } catch (\Exception $e) { error_log('notifyProductOwner: ' . $e->getMessage()); }
}


