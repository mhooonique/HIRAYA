<?php
// hiraya_api/api/v1/endpoints/messages.php

require_once __DIR__ . '/../config/jwt.php';

// ── Entry point ───────────────────────────────────────────────────────────────
function handleMessages(PDO $pdo, string $method, array $segments): void {
    // Ensure all tables exist
    _ensureMessagesTables($pdo);

    // Authenticate every request
    $user = getAuthUser();
    if (!$user) {
        _msgRespond(401, ['success' => false, 'error' => 'Authentication required']);
        return;
    }
    $currentUserId = (int)$user['user_id'];

    // segments[0] = 'messages'
    // segments[1] = 'conversations'
    // segments[2] = {id}  (optional)
    // segments[3] = action (optional: 'send', 'read', 'report', 'block')

    $resource  = $segments[1] ?? '';
    $segment2  = $segments[2] ?? null;  // numeric id OR named sub-resource
    $resourceId = ($segment2 !== null && is_numeric($segment2)) ? (int)$segment2 : null;
    $action    = $segments[3] ?? null;

    // ── Calls resource ────────────────────────────────────────────────────────

    if ($resource === 'calls') {
        // POST /messages/calls — initiate a call
        if ($method === 'POST' && $segment2 === null) {
            _initiateCall($pdo, $currentUserId);
            return;
        }
        // GET /messages/calls/incoming — poll for incoming calls
        if ($method === 'GET' && $segment2 === 'incoming') {
            _getIncomingCalls($pdo, $currentUserId);
            return;
        }
        // PUT /messages/calls/{id}/accept
        if ($method === 'PUT' && $resourceId !== null && $action === 'accept') {
            _acceptCall($pdo, $currentUserId, $resourceId);
            return;
        }
        // PUT /messages/calls/{id}/decline
        if ($method === 'PUT' && $resourceId !== null && $action === 'decline') {
            _declineCall($pdo, $currentUserId, $resourceId);
            return;
        }
        _msgRespond(404, ['success' => false, 'error' => 'Route not found']);
        return;
    }

    // ── Conversations resource ────────────────────────────────────────────────

    if ($resource !== 'conversations') {
        _msgRespond(404, ['success' => false, 'error' => 'Route not found']);
        return;
    }

    $convId = $resourceId;

    // GET /messages/conversations
    if ($method === 'GET' && $convId === null) {
        _listConversations($pdo, $currentUserId);
        return;
    }

    // POST /messages/conversations
    if ($method === 'POST' && $convId === null) {
        _createConversation($pdo, $currentUserId);
        return;
    }

    // GET /messages/conversations/{id}
    if ($method === 'GET' && $convId !== null && $action === null) {
        _getConversation($pdo, $currentUserId, $convId);
        return;
    }

    // POST /messages/conversations/{id}/send
    if ($method === 'POST' && $convId !== null && $action === 'send') {
        _sendMessage($pdo, $currentUserId, $convId);
        return;
    }

    // PUT /messages/conversations/{id}/read
    if ($method === 'PUT' && $convId !== null && $action === 'read') {
        _markRead($pdo, $currentUserId, $convId);
        return;
    }

    // POST /messages/conversations/{id}/report
    if ($method === 'POST' && $convId !== null && $action === 'report') {
        _reportConversation($pdo, $currentUserId, $convId);
        return;
    }

    // POST /messages/conversations/{id}/block
    if ($method === 'POST' && $convId !== null && $action === 'block') {
        _blockUser($pdo, $currentUserId, $convId);
        return;
    }

    // DELETE /messages/conversations/{id}/block
    if ($method === 'DELETE' && $convId !== null && $action === 'block') {
        _unblockUser($pdo, $currentUserId, $convId);
        return;
    }

    _msgRespond(404, ['success' => false, 'error' => 'Route not found']);
}

// ── Table creation ─────────────────────────────────────────────────────────────
function _ensureMessagesTables(PDO $pdo): void {
    $pdo->exec("CREATE TABLE IF NOT EXISTS conversations (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        innovator_id INT UNSIGNED NOT NULL,
        client_id INT UNSIGNED NOT NULL,
        origin_product_id INT UNSIGNED NULL,
        origin_product_name VARCHAR(255) NULL,
        origin_product_category VARCHAR(100) NULL,
        last_activity DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_pair (innovator_id, client_id),
        INDEX idx_innovator (innovator_id),
        INDEX idx_client (client_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $pdo->exec("CREATE TABLE IF NOT EXISTS messages (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        conversation_id INT UNSIGNED NOT NULL,
        sender_id INT UNSIGNED NOT NULL,
        text TEXT NOT NULL DEFAULT '',
        attachment_name VARCHAR(255) NULL,
        attachment_size_kb INT NULL,
        attachment_type ENUM('image','file') NULL,
        attachment_base64 MEDIUMTEXT NULL,
        status ENUM('sent','delivered','read') NOT NULL DEFAULT 'sent',
        is_reported TINYINT(1) NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_conversation (conversation_id, created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $pdo->exec("CREATE TABLE IF NOT EXISTS message_reports (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        conversation_id INT UNSIGNED NOT NULL,
        message_id INT UNSIGNED NULL,
        reporter_id INT UNSIGNED NOT NULL,
        flagged_user_id INT UNSIGNED NOT NULL,
        reason VARCHAR(255) NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    // Migrate existing tables that may not have flagged_user_id
    try {
        $pdo->exec("ALTER TABLE message_reports ADD COLUMN flagged_user_id INT UNSIGNED NOT NULL DEFAULT 0 AFTER reporter_id");
    } catch (\Exception $ignored) {}

    $pdo->exec("CREATE TABLE IF NOT EXISTS message_blocks (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        conversation_id INT UNSIGNED NOT NULL,
        blocker_id INT UNSIGNED NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_block (conversation_id, blocker_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $pdo->exec("CREATE TABLE IF NOT EXISTS calls (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        conversation_id INT UNSIGNED NOT NULL,
        caller_id INT UNSIGNED NOT NULL,
        callee_id INT UNSIGNED NOT NULL,
        is_video TINYINT(1) NOT NULL DEFAULT 0,
        status ENUM('pending','accepted','declined','ended','missed') NOT NULL DEFAULT 'pending',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_callee_status (callee_id, status),
        INDEX idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
}

// ── GET /messages/conversations ───────────────────────────────────────────────
function _listConversations(PDO $pdo, int $userId): void {
    $stmt = $pdo->prepare("
        SELECT
            c.id,
            c.innovator_id,
            c.client_id,
            c.origin_product_id,
            c.origin_product_name,
            c.origin_product_category,
            c.last_activity,
            c.created_at,
            ui.name AS innovator_name,
            uc.name AS client_name,
            (
                SELECT m2.text FROM messages m2
                WHERE m2.conversation_id = c.id
                ORDER BY m2.created_at DESC LIMIT 1
            ) AS last_message_text,
            (
                SELECT m3.created_at FROM messages m3
                WHERE m3.conversation_id = c.id
                ORDER BY m3.created_at DESC LIMIT 1
            ) AS last_message_time,
            (
                SELECT COUNT(*) FROM messages m4
                WHERE m4.conversation_id = c.id
                  AND m4.sender_id != :uid1
                  AND m4.status != 'read'
            ) AS unread_count,
            (
                SELECT COUNT(*) FROM message_blocks mb
                WHERE mb.conversation_id = c.id AND mb.blocker_id = c.innovator_id
            ) AS is_blocked_by_innovator,
            (
                SELECT COUNT(*) FROM message_blocks mb2
                WHERE mb2.conversation_id = c.id AND mb2.blocker_id = c.client_id
            ) AS is_blocked_by_client
        FROM conversations c
        LEFT JOIN users ui ON ui.id = c.innovator_id
        LEFT JOIN users uc ON uc.id = c.client_id
        WHERE c.innovator_id = :uid2 OR c.client_id = :uid3
        ORDER BY c.last_activity DESC
    ");
    $stmt->execute([':uid1' => $userId, ':uid2' => $userId, ':uid3' => $userId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $conversations = array_map(fn($r) => _formatConversation($r), $rows);

    _msgRespond(200, ['success' => true, 'data' => $conversations]);
}

// ── POST /messages/conversations ──────────────────────────────────────────────
function _createConversation(PDO $pdo, int $currentUserId): void {
    $body = _msgBody();
    $innovatorId = isset($body['innovator_id']) ? (int)$body['innovator_id'] : 0;
    $clientId    = isset($body['client_id'])    ? (int)$body['client_id']    : 0;

    if ($innovatorId === 0 || $clientId === 0) {
        _msgRespond(400, ['success' => false, 'error' => 'innovator_id and client_id are required']);
        return;
    }

    // Caller must be one of the participants
    if ($currentUserId !== $innovatorId && $currentUserId !== $clientId) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    $originProductId       = isset($body['origin_product_id'])       ? (int)$body['origin_product_id']         : null;
    $originProductName     = $body['origin_product_name']     ?? null;
    $originProductCategory = $body['origin_product_category'] ?? null;

    // Insert or ignore if pair already exists
    $insert = $pdo->prepare("
        INSERT IGNORE INTO conversations
            (innovator_id, client_id, origin_product_id, origin_product_name, origin_product_category)
        VALUES
            (:iid, :cid, :pid, :pname, :pcat)
    ");
    $insert->execute([
        ':iid'   => $innovatorId,
        ':cid'   => $clientId,
        ':pid'   => $originProductId,
        ':pname' => $originProductName,
        ':pcat'  => $originProductCategory,
    ]);

    // Fetch the existing or newly created conversation
    $stmt = $pdo->prepare("
        SELECT
            c.id,
            c.innovator_id,
            c.client_id,
            c.origin_product_id,
            c.origin_product_name,
            c.origin_product_category,
            c.last_activity,
            c.created_at,
            ui.name AS innovator_name,
            uc.name AS client_name,
            NULL AS last_message_text,
            NULL AS last_message_time,
            0 AS unread_count,
            0 AS is_blocked_by_innovator,
            0 AS is_blocked_by_client
        FROM conversations c
        LEFT JOIN users ui ON ui.id = c.innovator_id
        LEFT JOIN users uc ON uc.id = c.client_id
        WHERE c.innovator_id = :iid AND c.client_id = :cid
    ");
    $stmt->execute([':iid' => $innovatorId, ':cid' => $clientId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        _msgRespond(500, ['success' => false, 'error' => 'Failed to create conversation']);
        return;
    }

    _msgRespond(200, ['success' => true, 'data' => _formatConversation($row)]);
}

// ── GET /messages/conversations/{id} ─────────────────────────────────────────
function _getConversation(PDO $pdo, int $currentUserId, int $convId): void {
    $conv = _fetchConvRow($pdo, $convId);
    if (!$conv) {
        _msgRespond(404, ['success' => false, 'error' => 'Conversation not found']);
        return;
    }

    if ($currentUserId !== (int)$conv['innovator_id'] && $currentUserId !== (int)$conv['client_id']) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    // Mark 'sent' messages from other person as 'delivered'
    $pdo->prepare("
        UPDATE messages
        SET status = 'delivered'
        WHERE conversation_id = :cid
          AND sender_id != :uid
          AND status = 'sent'
    ")->execute([':cid' => $convId, ':uid' => $currentUserId]);

    // Fetch all messages with sender_name
    $msgStmt = $pdo->prepare("
        SELECT m.*, u.name AS sender_name
        FROM messages m
        LEFT JOIN users u ON u.id = m.sender_id
        WHERE m.conversation_id = :cid
        ORDER BY m.created_at ASC
    ");
    $msgStmt->execute([':cid' => $convId]);
    $messages = array_map(fn($m) => _formatMessage($m), $msgStmt->fetchAll(PDO::FETCH_ASSOC));

    $formatted = _formatConversation($conv);
    $formatted['messages'] = $messages;

    _msgRespond(200, ['success' => true, 'data' => $formatted]);
}

// ── POST /messages/conversations/{id}/send ────────────────────────────────────
function _sendMessage(PDO $pdo, int $currentUserId, int $convId): void {
    $conv = _fetchConvRow($pdo, $convId);
    if (!$conv) {
        _msgRespond(404, ['success' => false, 'error' => 'Conversation not found']);
        return;
    }

    if ($currentUserId !== (int)$conv['innovator_id'] && $currentUserId !== (int)$conv['client_id']) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    $body            = _msgBody();
    $text            = $body['text']               ?? '';
    $attachName      = $body['attachment_name']    ?? null;
    $attachSizeKb    = isset($body['attachment_size_kb']) ? (int)$body['attachment_size_kb'] : null;
    $attachType      = $body['attachment_type']    ?? null;
    $attachBase64    = $body['attachment_base64']  ?? null;

    // Validate attachment_type
    if ($attachType !== null && !in_array($attachType, ['image', 'file'], true)) {
        $attachType = null;
    }

    $stmt = $pdo->prepare("
        INSERT INTO messages
            (conversation_id, sender_id, text, attachment_name, attachment_size_kb,
             attachment_type, attachment_base64, status)
        VALUES
            (:cid, :sid, :text, :aname, :asizekb, :atype, :ab64, 'sent')
    ");
    $stmt->execute([
        ':cid'     => $convId,
        ':sid'     => $currentUserId,
        ':text'    => $text,
        ':aname'   => $attachName,
        ':asizekb' => $attachSizeKb,
        ':atype'   => $attachType,
        ':ab64'    => $attachBase64,
    ]);
    $newId = (int)$pdo->lastInsertId();

    // Update last_activity on the conversation
    $pdo->prepare("UPDATE conversations SET last_activity = NOW() WHERE id = :cid")
        ->execute([':cid' => $convId]);

    // Fetch the inserted message with sender_name
    $fetchStmt = $pdo->prepare("
        SELECT m.*, u.name AS sender_name
        FROM messages m
        LEFT JOIN users u ON u.id = m.sender_id
        WHERE m.id = :mid
    ");
    $fetchStmt->execute([':mid' => $newId]);
    $row = $fetchStmt->fetch(PDO::FETCH_ASSOC);

    _msgRespond(201, ['success' => true, 'data' => _formatMessage($row)]);
}

// ── PUT /messages/conversations/{id}/read ─────────────────────────────────────
function _markRead(PDO $pdo, int $currentUserId, int $convId): void {
    $conv = _fetchConvRow($pdo, $convId);
    if (!$conv) {
        _msgRespond(404, ['success' => false, 'error' => 'Conversation not found']);
        return;
    }

    if ($currentUserId !== (int)$conv['innovator_id'] && $currentUserId !== (int)$conv['client_id']) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    // Mark messages from the OTHER person as 'read'
    $pdo->prepare("
        UPDATE messages
        SET status = 'read'
        WHERE conversation_id = :cid
          AND sender_id != :uid
          AND status != 'read'
    ")->execute([':cid' => $convId, ':uid' => $currentUserId]);

    _msgRespond(200, ['success' => true]);
}

// ── POST /messages/conversations/{id}/report ──────────────────────────────────
function _reportConversation(PDO $pdo, int $currentUserId, int $convId): void {
    $conv = _fetchConvRow($pdo, $convId);
    if (!$conv) {
        _msgRespond(404, ['success' => false, 'error' => 'Conversation not found']);
        return;
    }

    if ($currentUserId !== (int)$conv['innovator_id'] && $currentUserId !== (int)$conv['client_id']) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    // Determine who is being flagged (the OTHER person)
    $flaggedUserId = $currentUserId === (int)$conv['innovator_id']
        ? (int)$conv['client_id']
        : (int)$conv['innovator_id'];

    $body      = _msgBody();
    $messageId = isset($body['message_id']) ? (int)$body['message_id'] : null;
    $reason    = isset($body['reason']) ? trim((string)$body['reason']) : 'No reason provided';

    // Insert report (ignore duplicate reporter per conversation to prevent spam)
    try {
        $pdo->prepare("
            INSERT INTO message_reports (conversation_id, message_id, reporter_id, flagged_user_id, reason)
            VALUES (:cid, :mid, :rid, :fid, :reason)
        ")->execute([
            ':cid'    => $convId,
            ':mid'    => $messageId,
            ':rid'    => $currentUserId,
            ':fid'    => $flaggedUserId,
            ':reason' => $reason,
        ]);
    } catch (\Exception $e) {
        // Duplicate insert — still respond success
        _msgRespond(200, ['success' => true]);
        return;
    }

    // If a specific message was reported, flag it
    if ($messageId !== null) {
        $pdo->prepare("UPDATE messages SET is_reported = 1 WHERE id = :mid AND conversation_id = :cid")
            ->execute([':mid' => $messageId, ':cid' => $convId]);
    }

    // Count distinct reporters who flagged this user (3-strike system)
    $strikeStmt = $pdo->prepare("SELECT COUNT(DISTINCT reporter_id) FROM message_reports WHERE flagged_user_id = :fid");
    $strikeStmt->execute([':fid' => $flaggedUserId]);
    $strikeCount = (int)$strikeStmt->fetchColumn();

    $suspended = false;
    if ($strikeCount >= 3) {
        // Auto-suspend the flagged user
        $pdo->prepare("UPDATE users SET user_status = 2 WHERE id = :id AND role != 'admin'")
            ->execute([':id' => $flaggedUserId]);
        $suspended = true;
    }

    // Get reporter name and flagged user name for notifications
    $reporterRow = $pdo->prepare("SELECT CONCAT(first_name, ' ', last_name) AS name FROM users WHERE id = :id LIMIT 1");
    $reporterRow->execute([':id' => $currentUserId]);
    $reporterName = $reporterRow->fetchColumn() ?: 'A user';

    $flaggedRow = $pdo->prepare("SELECT CONCAT(first_name, ' ', last_name) AS name, username FROM users WHERE id = :id LIMIT 1");
    $flaggedRow->execute([':id' => $flaggedUserId]);
    $flaggedData = $flaggedRow->fetch(PDO::FETCH_ASSOC);
    $flaggedName = $flaggedData ? $flaggedData['name'] : 'Unknown user';

    // Always notify admins of the flag
    if ($suspended) {
        _msgNotifyAdmins($pdo, 'user_suspended',
            "User Auto-Suspended: {$flaggedName}",
            "{$flaggedName} received {$strikeCount} flags and has been automatically suspended. Reason for latest flag: \"{$reason}\".",
            '/admin');
        // Notify the suspended user
        _msgPushNotification($pdo, $flaggedUserId, 'account_suspended',
            'Your account has been suspended',
            'Your account has been suspended due to multiple reports from users. Please contact support.',
            '/login');
    } else {
        _msgNotifyAdmins($pdo, 'user_flagged',
            "User Flagged: {$flaggedName}",
            "{$reporterName} flagged {$flaggedName} for: \"{$reason}\". Strike {$strikeCount}/3.",
            '/admin');
    }

    _msgRespond(200, ['success' => true, 'strikes' => $strikeCount, 'suspended' => $suspended]);
}

// ── POST /messages/conversations/{id}/block ───────────────────────────────────
function _blockUser(PDO $pdo, int $currentUserId, int $convId): void {
    $conv = _fetchConvRow($pdo, $convId);
    if (!$conv) {
        _msgRespond(404, ['success' => false, 'error' => 'Conversation not found']);
        return;
    }

    if ($currentUserId !== (int)$conv['innovator_id'] && $currentUserId !== (int)$conv['client_id']) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    $pdo->prepare("
        INSERT IGNORE INTO message_blocks (conversation_id, blocker_id)
        VALUES (:cid, :bid)
    ")->execute([':cid' => $convId, ':bid' => $currentUserId]);

    _msgRespond(200, ['success' => true]);
}

// ── DELETE /messages/conversations/{id}/block ─────────────────────────────────
function _unblockUser(PDO $pdo, int $currentUserId, int $convId): void {
    $conv = _fetchConvRow($pdo, $convId);
    if (!$conv) {
        _msgRespond(404, ['success' => false, 'error' => 'Conversation not found']);
        return;
    }

    if ($currentUserId !== (int)$conv['innovator_id'] && $currentUserId !== (int)$conv['client_id']) {
        _msgRespond(403, ['success' => false, 'error' => 'Forbidden']);
        return;
    }

    $pdo->prepare("
        DELETE FROM message_blocks
        WHERE conversation_id = :cid AND blocker_id = :bid
    ")->execute([':cid' => $convId, ':bid' => $currentUserId]);

    _msgRespond(200, ['success' => true]);
}

// ── POST /messages/calls ──────────────────────────────────────────────────────
function _initiateCall(PDO $pdo, int $callerId): void {
    $body         = _msgBody();
    $convId       = isset($body['conversation_id']) ? (int)$body['conversation_id'] : 0;
    $calleeId     = isset($body['callee_id'])       ? (int)$body['callee_id']       : 0;
    $isVideo      = !empty($body['is_video'])        ? 1 : 0;

    if ($convId === 0 || $calleeId === 0) {
        _msgRespond(400, ['success' => false, 'error' => 'conversation_id and callee_id are required']);
        return;
    }

    // Auto-expire any pending calls the caller already has open (missed)
    $pdo->prepare("
        UPDATE calls SET status = 'missed'
        WHERE caller_id = :uid AND status = 'pending'
          AND created_at < DATE_SUB(NOW(), INTERVAL 30 SECOND)
    ")->execute([':uid' => $callerId]);

    // Insert new call record
    $stmt = $pdo->prepare("
        INSERT INTO calls (conversation_id, caller_id, callee_id, is_video, status)
        VALUES (:cid, :caller, :callee, :vid, 'pending')
    ");
    $stmt->execute([
        ':cid'    => $convId,
        ':caller' => $callerId,
        ':callee' => $calleeId,
        ':vid'    => $isVideo,
    ]);
    $callId = (int)$pdo->lastInsertId();

    $room = 'hiraya-conv-' . $convId;
    _msgRespond(201, [
        'success' => true,
        'data'    => [
            'call_id'  => $callId,
            'room_url' => 'https://meet.jit.si/' . $room,
        ],
    ]);
}

// ── GET /messages/calls/incoming ─────────────────────────────────────────────
function _getIncomingCalls(PDO $pdo, int $calleeId): void {
    // Auto-expire old pending calls (> 30 seconds) as missed
    $pdo->prepare("
        UPDATE calls SET status = 'missed'
        WHERE status = 'pending'
          AND created_at < DATE_SUB(NOW(), INTERVAL 30 SECOND)
    ")->execute();

    $stmt = $pdo->prepare("
        SELECT c.id, c.conversation_id, c.caller_id, c.is_video,
               CONCAT(u.first_name, ' ', u.last_name) AS caller_name
        FROM calls c
        LEFT JOIN users u ON u.id = c.caller_id
        WHERE c.callee_id = :uid AND c.status = 'pending'
        ORDER BY c.created_at DESC
        LIMIT 1
    ");
    $stmt->execute([':uid' => $calleeId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        _msgRespond(200, ['success' => true, 'data' => null]);
        return;
    }

    $room = 'hiraya-conv-' . (int)$row['conversation_id'];
    _msgRespond(200, ['success' => true, 'data' => [
        'id'              => (int)$row['id'],
        'conversation_id' => (int)$row['conversation_id'],
        'caller_name'     => $row['caller_name'] ?? 'Unknown',
        'is_video'        => (bool)$row['is_video'],
        'room_url'        => 'https://meet.jit.si/' . $room,
    ]]);
}

// ── PUT /messages/calls/{id}/accept ──────────────────────────────────────────
function _acceptCall(PDO $pdo, int $calleeId, int $callId): void {
    $stmt = $pdo->prepare("
        UPDATE calls SET status = 'accepted'
        WHERE id = :id AND callee_id = :uid AND status = 'pending'
    ");
    $stmt->execute([':id' => $callId, ':uid' => $calleeId]);

    if ($stmt->rowCount() === 0) {
        _msgRespond(404, ['success' => false, 'error' => 'Call not found or already handled']);
        return;
    }

    // Fetch room url
    $fetch = $pdo->prepare("SELECT conversation_id FROM calls WHERE id = :id");
    $fetch->execute([':id' => $callId]);
    $row = $fetch->fetch(PDO::FETCH_ASSOC);
    $room = 'hiraya-conv-' . (int)$row['conversation_id'];

    _msgRespond(200, ['success' => true, 'data' => ['room_url' => 'https://meet.jit.si/' . $room]]);
}

// ── PUT /messages/calls/{id}/decline ─────────────────────────────────────────
function _declineCall(PDO $pdo, int $calleeId, int $callId): void {
    $pdo->prepare("
        UPDATE calls SET status = 'declined'
        WHERE id = :id AND callee_id = :uid AND status = 'pending'
    ")->execute([':id' => $callId, ':uid' => $calleeId]);

    _msgRespond(200, ['success' => true]);
}

// ── Internal helpers ──────────────────────────────────────────────────────────

function _fetchConvRow(PDO $pdo, int $convId): ?array {
    $stmt = $pdo->prepare("
        SELECT
            c.id,
            c.innovator_id,
            c.client_id,
            c.origin_product_id,
            c.origin_product_name,
            c.origin_product_category,
            c.last_activity,
            c.created_at,
            ui.name AS innovator_name,
            uc.name AS client_name,
            (
                SELECT m.text FROM messages m
                WHERE m.conversation_id = c.id
                ORDER BY m.created_at DESC LIMIT 1
            ) AS last_message_text,
            (
                SELECT m.created_at FROM messages m
                WHERE m.conversation_id = c.id
                ORDER BY m.created_at DESC LIMIT 1
            ) AS last_message_time,
            (
                SELECT COUNT(*) FROM messages m2
                WHERE m2.conversation_id = c.id AND m2.status != 'read'
            ) AS unread_count,
            (
                SELECT COUNT(*) FROM message_blocks mb
                WHERE mb.conversation_id = c.id AND mb.blocker_id = c.innovator_id
            ) AS is_blocked_by_innovator,
            (
                SELECT COUNT(*) FROM message_blocks mb2
                WHERE mb2.conversation_id = c.id AND mb2.blocker_id = c.client_id
            ) AS is_blocked_by_client
        FROM conversations c
        LEFT JOIN users ui ON ui.id = c.innovator_id
        LEFT JOIN users uc ON uc.id = c.client_id
        WHERE c.id = :cid
    ");
    $stmt->execute([':cid' => $convId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return $row ?: null;
}

function _formatConversation(array $r): array {
    return [
        'id'                      => (int)$r['id'],
        'innovator_id'            => (int)$r['innovator_id'],
        'client_id'               => (int)$r['client_id'],
        'innovator_name'          => $r['innovator_name'] ?? '',
        'client_name'             => $r['client_name']    ?? '',
        'origin_product_id'       => $r['origin_product_id'] !== null ? (int)$r['origin_product_id'] : null,
        'origin_product_name'     => $r['origin_product_name']     ?? '',
        'origin_product_category' => $r['origin_product_category'] ?? '',
        'last_activity'           => $r['last_activity'],
        'created_at'              => $r['created_at'],
        'last_message_text'       => $r['last_message_text']  ?? null,
        'last_message_time'       => $r['last_message_time']  ?? null,
        'unread_count'            => (int)($r['unread_count'] ?? 0),
        'is_blocked_by_innovator' => (int)($r['is_blocked_by_innovator'] ?? 0),
        'is_blocked_by_client'    => (int)($r['is_blocked_by_client']    ?? 0),
    ];
}

function _formatMessage(array $m): array {
    return [
        'id'                 => (int)$m['id'],
        'conversation_id'    => (int)$m['conversation_id'],
        'sender_id'          => (int)$m['sender_id'],
        'sender_name'        => $m['sender_name'] ?? '',
        'text'               => $m['text'] ?? '',
        'attachment_name'    => $m['attachment_name']    ?? null,
        'attachment_size_kb' => $m['attachment_size_kb'] !== null ? (int)$m['attachment_size_kb'] : null,
        'attachment_type'    => $m['attachment_type']    ?? null,
        'attachment_base64'  => $m['attachment_base64']  ?? null,
        'status'             => $m['status'] ?? 'sent',
        'is_reported'        => (bool)$m['is_reported'],
        'created_at'         => $m['created_at'],
    ];
}

function _msgBody(): array {
    $raw = file_get_contents('php://input');
    if (!$raw) return [];
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function _msgRespond(int $code, array $data): void {
    http_response_code($code);
    echo json_encode($data);
}

// ── Notification helpers (local to messages.php) ──────────────────────────────

function _msgNotifyAdmins(PDO $pdo, string $type, string $title, string $body, string $url = ''): void {
    try {
        $pdo->exec("CREATE TABLE IF NOT EXISTS notifications (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            user_id    INT NOT NULL,
            type       VARCHAR(64) NOT NULL DEFAULT 'system',
            title      VARCHAR(255) NOT NULL,
            body       TEXT NOT NULL DEFAULT '',
            action_url VARCHAR(512) NOT NULL DEFAULT '',
            is_read    TINYINT(1) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        $admins = $pdo->query("SELECT id FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_COLUMN);
        $stmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)");
        foreach ($admins as $adminId) {
            $stmt->execute([$adminId, $type, $title, $body, $url]);
        }
    } catch (\Exception $e) { error_log('msgNotifyAdmins: ' . $e->getMessage()); }
}

function _msgPushNotification(PDO $pdo, int $userId, string $type, string $title, string $body, string $url = ''): void {
    try {
        $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)")
            ->execute([$userId, $type, $title, $body, $url]);
    } catch (\Exception $e) { error_log('msgPushNotif: ' . $e->getMessage()); }
}
