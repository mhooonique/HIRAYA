<?php
// hiraya_api/api/v1/endpoints/otp.php

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/mail_helpers.php';

// ── Ensure otp_attempts table exists ──────────────────────────────────────────
function _ensureOtpAttemptsTable(PDO $pdo): void {
    $pdo->exec("CREATE TABLE IF NOT EXISTS otp_attempts (
        id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id      INT UNSIGNED NOT NULL,
        attempted_at DATETIME     NOT NULL,
        INDEX idx_user_time (user_id, attempted_at)
    ) ENGINE=InnoDB;");
}

// ── Send OTP ──────────────────────────────────────────────────────────────────
function handleSendOtp(PDO $pdo): void {
    $body   = json_decode(file_get_contents('php://input'), true) ?? [];
    $userId = (int)($body['user_id'] ?? 0);
    $type   = in_array($body['type'] ?? '', ['sms', 'email']) ? $body['type'] : 'email';

    if (!$userId) {
        http_response_code(400);
        echo json_encode(['error' => 'user_id is required']);
        return;
    }

    $stmt = $pdo->prepare("SELECT id, email, first_name, phone FROM users WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(404);
        echo json_encode(['error' => 'User not found']);
        return;
    }

    // Rate limit: max 3 OTP sends per user per 5 minutes
    $pdo->exec("CREATE TABLE IF NOT EXISTS otp_send_log (
        id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id INT UNSIGNED NOT NULL,
        sent_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_user_time (user_id, sent_at)
    ) ENGINE=InnoDB");
    $sendCount = $pdo->prepare(
        "SELECT COUNT(*) FROM otp_send_log WHERE user_id = ? AND sent_at > NOW() - INTERVAL 5 MINUTE"
    );
    $sendCount->execute([$userId]);
    if ((int)$sendCount->fetchColumn() >= 3) {
        http_response_code(429);
        echo json_encode(['error' => 'Too many OTP requests. Please wait 5 minutes before trying again.']);
        return;
    }

    // Reuse existing valid code if available — prevents invalidation on double send
    $existing = $pdo->prepare(
        "SELECT code FROM otp_codes
         WHERE user_id = :uid AND used = 0 AND expires_at > NOW()
         ORDER BY id DESC LIMIT 1"
    );
    $existing->execute([':uid' => $userId]);
    $row = $existing->fetch(PDO::FETCH_ASSOC);

    if ($row) {
        $code = $row['code'];
    } else {
        // Invalidate old expired/used codes first
        $pdo->prepare("UPDATE otp_codes SET used = 1 WHERE user_id = :uid AND used = 0")
            ->execute([':uid' => $userId]);

        $code      = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $expiresAt = date('Y-m-d H:i:s', strtotime('+5 minutes'));

        $pdo->prepare(
            "INSERT INTO otp_codes (user_id, code, type, expires_at)
             VALUES (:uid, :code, :type, :exp)"
        )->execute([
            ':uid'  => $userId,
            ':code' => $code,
            ':type' => $type,
            ':exp'  => $expiresAt,
        ]);
        $pdo->prepare("INSERT INTO otp_send_log (user_id) VALUES (?)")->execute([$userId]);
    }

    if ($type === 'email') {
        $sent = _sendOtpEmail($user['email'], $user['first_name'], $code);
        if (!$sent) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to send OTP email. Please try again.']);
            return;
        }
    }

    http_response_code(200);
    echo json_encode([
        'success'    => true,
        'message'    => $type === 'email' ? 'OTP sent to your Gmail address' : 'OTP sent via SMS',
        'expires_in' => 300,
    ]);
}

// ── Verify OTP ────────────────────────────────────────────────────────────────
function handleVerifyOtp(PDO $pdo): void {
    $body        = json_decode(file_get_contents('php://input'), true) ?? [];
    $userId      = (int)($body['user_id'] ?? 0);
    $code        = trim($body['code'] ?? '');
    $deviceId    = trim($body['device_id'] ?? '');
    $smsVerified = (bool)($body['sms_verified'] ?? false);

    if (!$userId || !$deviceId) {
        http_response_code(400);
        echo json_encode(['error' => 'user_id and device_id are required']);
        return;
    }

    _ensureOtpAttemptsTable($pdo);

    // SMS was already verified by Firebase on the client — just trust the device
    if (!$smsVerified) {
        if (!$code) {
            http_response_code(400);
            echo json_encode(['error' => 'code is required']);
            return;
        }

        // Rate limit: max 5 failed attempts per user in the last 10 minutes
        $attempts = $pdo->prepare(
            "SELECT COUNT(*) FROM otp_attempts
             WHERE user_id = :uid AND attempted_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)"
        );
        $attempts->execute([':uid' => $userId]);
        if ((int)$attempts->fetchColumn() >= 5) {
            http_response_code(429);
            echo json_encode(['error' => 'Too many attempts. Please wait before trying again.']);
            return;
        }

        $stmt = $pdo->prepare(
            "SELECT id FROM otp_codes
             WHERE user_id = :uid
               AND code = :code
               AND used = 0
               AND expires_at > NOW()
             ORDER BY id DESC LIMIT 1"
        );
        $stmt->execute([':uid' => $userId, ':code' => $code]);
        $otp = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$otp) {
            // Log the failed attempt
            $pdo->prepare("INSERT INTO otp_attempts (user_id, attempted_at) VALUES (:uid, NOW())")
                ->execute([':uid' => $userId]);

            http_response_code(401);
            echo json_encode(['error' => 'Invalid or expired code. Please try again.']);
            return;
        }

        $pdo->prepare("UPDATE otp_codes SET used = 1 WHERE id = :id")
            ->execute([':id' => $otp['id']]);
    }

    // Trust this device
    $pdo->exec("CREATE TABLE IF NOT EXISTS trusted_devices (
        id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id   INT UNSIGNED NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_user_device (user_id, device_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    $pdo->prepare(
        "INSERT IGNORE INTO trusted_devices (user_id, device_id)
         VALUES (:uid, :did)"
    )->execute([':uid' => $userId, ':did' => $deviceId]);

    // Fetch user for response
    $uStmt = $pdo->prepare(
        "SELECT id, email, first_name, last_name, username, role, kyc_status, user_status
         FROM users WHERE id = :id LIMIT 1"
    );
    $uStmt->execute([':id' => $userId]);
    $user = $uStmt->fetch(PDO::FETCH_ASSOC);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Verification successful',
        'user'    => [
            'id'          => $user['id'],
            'email'       => $user['email'],
            'first_name'  => $user['first_name'],
            'last_name'   => $user['last_name'],
            'username'    => $user['username'],
            'role'        => $user['role'],
            'kyc_status'  => $user['kyc_status'],
            'user_status' => (int)$user['user_status'],
        ],
    ]);
}

// ── Resend OTP ────────────────────────────────────────────────────────────────
function handleResendOtp(PDO $pdo): void {
    handleSendOtp($pdo);
}

// ── Status email (called from admin endpoints) ────────────────────────────────
function sendStatusEmail(PDO $pdo, int $userId, bool $approved): bool {
    $stmt = $pdo->prepare("SELECT email, first_name FROM users WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) return false;

    return $approved
        ? sendEmail($user['email'], $user['first_name'],
            '🎉 Your HIRAYA Account Has Been Approved!',
            _approvalEmailBody($user['first_name']))
        : sendEmail($user['email'], $user['first_name'],
            'Update on Your HIRAYA Account Application',
            _rejectionEmailBody($user['first_name']));
}

// ── PHPMailer helpers ─────────────────────────────────────────────────────────
function _sendOtpEmail(string $email, string $firstName, string $code): bool {
    return sendEmail($email, $firstName, 'Your HIRAYA Verification Code', _otpEmailBody($firstName, $code));
}

// ── Email templates ───────────────────────────────────────────────────────────
function _otpEmailBody(string $name, string $code): string {
    return "
<div style='font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;background:#f9f9f9;border-radius:12px;'>
  <h2 style='color:#0A2540;'>HIRAYA</h2>
  <p style='color:#444;'>Hi <strong>{$name}</strong>,</p>
  <p style='color:#444;'>Your verification code is:</p>
  <div style='background:#0A2540;color:#fff;font-size:36px;font-weight:bold;letter-spacing:12px;text-align:center;padding:24px;border-radius:10px;margin:24px 0;'>
    {$code}
  </div>
  <p style='color:#888;font-size:13px;'>Expires in <strong>5 minutes</strong>. Do not share this code.</p>
  <hr style='border:none;border-top:1px solid #eee;margin:24px 0;'>
  <p style='color:#bbb;font-size:11px;text-align:center;'>HIRAYA Innovation Marketplace</p>
</div>";
}

function _approvalEmailBody(string $name): string {
    return "
<div style='font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;background:#f9f9f9;border-radius:12px;'>
  <h2 style='color:#0A2540;'>HIRAYA</h2>
  <p style='color:#444;'>Hi <strong>{$name}</strong>,</p>
  <p style='color:#444;'>Great news! Your HIRAYA account has been <strong style='color:#00897B;'>approved</strong>.</p>
  <p style='color:#444;'>You can now log in and start exploring the HIRAYA Innovation Marketplace.</p>
  <div style='text-align:center;margin:32px 0;'>
    <a href='https://yosef-trilingual-scalably.ngrok-free.dev/hiraya/login'
       style='background:#00897B;color:#fff;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:bold;'>
      Log In to HIRAYA
    </a>
  </div>
  <hr style='border:none;border-top:1px solid #eee;margin:24px 0;'>
  <p style='color:#bbb;font-size:11px;text-align:center;'>HIRAYA Innovation Marketplace</p>
</div>";
}

function _rejectionEmailBody(string $name): string {
    return "
<div style='font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;background:#f9f9f9;border-radius:12px;'>
  <h2 style='color:#0A2540;'>HIRAYA</h2>
  <p style='color:#444;'>Hi <strong>{$name}</strong>,</p>
  <p style='color:#444;'>Thank you for applying to HIRAYA. After reviewing your application, we were unable to approve your account at this time.</p>
  <p style='color:#444;'>This may be due to incomplete or unclear KYC documents. Please contact our support team if you believe this is an error.</p>
  <hr style='border:none;border-top:1px solid #eee;margin:24px 0;'>
  <p style='color:#bbb;font-size:11px;text-align:center;'>HIRAYA Innovation Marketplace</p>
</div>";
}