<?php
// hiraya_api/api/v1/endpoints/notifications.php

function handleNotifications(PDO $pdo, string $method, array $segments): void {
    $id     = isset($segments[1]) && is_numeric($segments[1]) ? (int)$segments[1] : null;
    $action = $segments[2] ?? null; // 'read'

    // POST /notifications/{id}/read  OR  PUT /notifications/{id}/read
    if ($id && $action === 'read') {
        markRead($pdo, $id);
        return;
    }

    // PUT /notifications/read-all
    if (($segments[1] ?? '') === 'read-all' && $method === 'PUT') {
        markAllRead($pdo);
        return;
    }

    match ($method) {
        'GET'    => getNotifications($pdo),
        'PUT'    => $id ? markRead($pdo, $id) : markAllRead($pdo),
        'DELETE' => $id ? deleteNotification($pdo, $id) : respond(400, ['error' => 'ID required']),
        default  => respond(405, ['error' => 'Method not allowed']),
    };
}

// ── GET /notifications ────────────────────────────────────────────────────────
function getNotifications(PDO $pdo): void {
    $userId = requireUserId();
    if (!$userId) return;

    $limit = min(50, (int)($_GET['limit'] ?? 30));

    // Ensure table exists
    ensureNotificationsTable($pdo);

    $stmt = $pdo->prepare(
        "SELECT id, type, title, body, is_read, action_url, created_at
         FROM notifications
         WHERE user_id = :uid
         ORDER BY created_at DESC
         LIMIT :limit"
    );
    $stmt->bindValue(':uid',   $userId, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit,  PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $notifications = array_map(function ($r) {
        return [
            'id'         => (int)$r['id'],
            'type'       => $r['type'],
            'title'      => $r['title'],
            'body'       => $r['body'],
            'is_read'    => (bool)$r['is_read'],
            'action_url' => $r['action_url'],
            'created_at' => $r['created_at'],
        ];
    }, $rows);

    respond(200, [
        'notifications' => $notifications,
        'unread_count'  => count(array_filter($notifications, fn($n) => !$n['is_read'])),
    ]);
}

// ── PUT /notifications/{id}/read ──────────────────────────────────────────────
function markRead(PDO $pdo, int $id): void {
    $userId = requireUserId();
    if (!$userId) return;

    $pdo->prepare(
        "UPDATE notifications SET is_read = 1 WHERE id = :id AND user_id = :uid"
    )->execute([':id' => $id, ':uid' => $userId]);

    respond(200, ['message' => 'Marked as read']);
}

// ── PUT /notifications/read-all ───────────────────────────────────────────────
function markAllRead(PDO $pdo): void {
    $userId = requireUserId();
    if (!$userId) return;

    $pdo->prepare(
        "UPDATE notifications SET is_read = 1 WHERE user_id = :uid AND is_read = 0"
    )->execute([':uid' => $userId]);

    respond(200, ['message' => 'All marked as read']);
}

// ── DELETE /notifications/{id} ────────────────────────────────────────────────
function deleteNotification(PDO $pdo, int $id): void {
    $userId = requireUserId();
    if (!$userId) return;

    $pdo->prepare(
        "DELETE FROM notifications WHERE id = :id AND user_id = :uid"
    )->execute([':id' => $id, ':uid' => $userId]);

    respond(200, ['message' => 'Deleted']);
}

// ── Helper: push a notification (called from other endpoints) ─────────────────
function pushNotification(
    PDO $pdo,
    int $userId,
    string $type,
    string $title,
    string $body,
    ?string $actionUrl = null
): void {
    ensureNotificationsTable($pdo);
    $pdo->prepare(
        "INSERT INTO notifications (user_id, type, title, body, action_url, is_read)
         VALUES (:uid, :type, :title, :body, :url, 0)"
    )->execute([
        ':uid'   => $userId,
        ':type'  => $type,
        ':title' => $title,
        ':body'  => $body,
        ':url'   => $actionUrl,
    ]);
}

// ── Ensure table exists ───────────────────────────────────────────────────────
function ensureNotificationsTable(PDO $pdo): void {
    $pdo->exec("CREATE TABLE IF NOT EXISTS notifications (
        id         INT AUTO_INCREMENT PRIMARY KEY,
        user_id    INT NOT NULL,
        type       VARCHAR(50) NOT NULL DEFAULT 'system',
        title      VARCHAR(255) NOT NULL,
        body       TEXT NOT NULL,
        is_read    TINYINT(1) DEFAULT 0,
        action_url VARCHAR(500) DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_user    (user_id),
        INDEX idx_read    (user_id, is_read),
        INDEX idx_created (created_at),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
}

// ── Shared helpers ─────────────────────────────────────────────────────────────
function requireUserId(): ?int {
    try {
        $headers = getallheaders();
        $auth    = $headers['Authorization'] ?? '';
        if (preg_match('/Bearer\s+(.+)/', $auth, $m)) {
            $payload = verifyJWT($m[1]);
            return isset($payload['user_id']) ? (int)$payload['user_id'] : null;
        }
    } catch (\Exception $e) {}
    respond(401, ['error' => 'Authentication required']);
    return null;
}

function respond(int $code, array $data): void {
    http_response_code($code);
    echo json_encode($data);
}