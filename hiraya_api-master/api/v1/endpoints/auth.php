<?php
// hiraya_api/api/v1/endpoints/auth.php

require_once __DIR__ . '/../config/jwt.php';
require_once __DIR__ . '/../config/mail_helpers.php';

function _authNotifyAdmins(PDO $pdo, string $type, string $title, string $body, string $url = ''): void {
    try {
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
        $admins = $pdo->query("SELECT id FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_COLUMN);
        $stmt = $pdo->prepare("INSERT INTO notifications (user_id, type, title, body, action_url, is_read) VALUES (?, ?, ?, ?, ?, 0)");
        foreach ($admins as $adminId) {
            $stmt->execute([$adminId, $type, $title, $body, $url]);
        }
    } catch (\Exception $e) { error_log('authNotifyAdmins: ' . $e->getMessage()); }
}

function handleLogin(PDO $pdo): void {
    $pdo  = getDB(); // fresh connection — avoids MySQL gone away
    $body     = json_decode(file_get_contents('php://input'), true) ?? [];
    $email    = trim($body['email'] ?? '');
    $password = $body['password'] ?? '';
    $deviceId = trim($body['device_id'] ?? '');

    if (!$email || !$password) {
        http_response_code(400);
        echo json_encode(['error' => 'Email and password are required']);
        return;
    }

    // Rate limit: max 10 failed login attempts per email in 15 minutes
    _createRateLimitTable($pdo);
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $limitStmt = $pdo->prepare(
        "SELECT COUNT(*) FROM login_rate_limits
         WHERE identifier = :id AND attempted_at > DATE_SUB(NOW(), INTERVAL 15 MINUTE)"
    );
    $limitStmt->execute([':id' => $email]);
    if ((int)$limitStmt->fetchColumn() >= 10) {
        http_response_code(429);
        echo json_encode(['error' => 'Too many login attempts. Please wait 15 minutes before trying again.']);
        return;
    }

    $stmt = $pdo->prepare(
        "SELECT id, email, password_hash, first_name, last_name, username,
                role, user_status, kyc_status, phone
         FROM users WHERE email = :email LIMIT 1"
    );
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid credentials']);
        return;
    }

    $hash = $user['password_hash'] ?? null;
    if (!$hash) {
        $alt = $pdo->prepare("SELECT password FROM users WHERE email = :e LIMIT 1");
        $alt->execute([':e' => $email]);
        $hash = ($alt->fetch(PDO::FETCH_ASSOC))['password'] ?? null;
    }

    $valid = $hash && password_verify($password, $hash);

    if (!$valid) {
        $pdo->prepare("INSERT INTO login_rate_limits (identifier, attempted_at) VALUES (:id, NOW())")
            ->execute([':id' => $email]);
        http_response_code(401);
        echo json_encode(['error' => 'Invalid credentials']);
        return;
    }

    $status = (int)$user['user_status'];
    if ($status === 0) {
        http_response_code(403);
        echo json_encode(['error' => 'Account is pending admin approval', 'status' => 'pending']);
        return;
    }
    if ($status === 2) {
        http_response_code(403);
        echo json_encode(['error' => 'Account application was rejected', 'status' => 'rejected']);
        return;
    }
    if ($status !== 1) {
        http_response_code(403);
        echo json_encode(['error' => 'Account is inactive']);
        return;
    }

    $token = generateJWT(['user_id' => $user['id'], 'email' => $user['email'], 'role' => $user['role']]);
    $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = :id")->execute([':id' => $user['id']]);

    // ── Device / 2FA check ────────────────────────────────────────────────────
    try { $pdo->exec("CREATE TABLE IF NOT EXISTS trusted_devices (
        id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id   INT UNSIGNED NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_user_device (user_id, device_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"); } catch (Exception $ignored) {}
    if ($deviceId && $user['role'] !== 'admin') {
        $devStmt = $pdo->prepare(
            "SELECT id FROM trusted_devices WHERE user_id = :uid AND device_id = :did LIMIT 1"
        );
        $devStmt->execute([':uid' => $user['id'], ':did' => $deviceId]);

        if (!$devStmt->fetch()) {
            $otpType = 'email'; // Web-only build: always use email OTP
            // Mask phone: show only last 4 digits for UI hint, never the full number
            $maskedPhone = null;
            if (!empty($user['phone'])) {
                $maskedPhone = str_repeat('*', max(0, strlen($user['phone']) - 4))
                    . substr($user['phone'], -4);
            }
            http_response_code(200);
            echo json_encode([
                'requires_2fa'  => true,
                'otp_type'      => $otpType,
                'user_id'       => $user['id'],
                'token'         => $token,
                'masked_phone'  => $maskedPhone,
            ]);
            return;
        }
    }

    http_response_code(200);
    echo json_encode([
        'requires_2fa' => false,
        'token'        => $token,
        'user'         => _userPayload($user),
    ]);
}

function handleSignup(PDO $pdo): void {
    $pdo  = getDB();
    
    $body           = json_decode(file_get_contents('php://input'), true) ?? [];
    $email          = trim($body['email'] ?? '');
    $password       = $body['password'] ?? '';
    $firstName      = trim($body['first_name'] ?? '');
    $lastName       = trim($body['last_name'] ?? '');
    $middleName     = trim($body['middle_name'] ?? '');
    $suffix         = trim($body['suffix'] ?? '');
    $username       = trim($body['username'] ?? '');
    $phone          = trim($body['phone'] ?? '');
    $countryCode    = trim($body['country_code'] ?? '+63');
    $role           = in_array($body['role'] ?? '', ['innovator', 'client']) ? $body['role'] : 'client';
    $isGoogleSignup = (bool)($body['is_google_signup'] ?? false);
    $googleId       = trim($body['google_id'] ?? '');

    // KYC
    $govIdBase64    = ($body['gov_id']      ?? '') !== '' ? $body['gov_id']      : null;
    $govIdFilename  = ($body['gov_id_name'] ?? '') !== '' ? $body['gov_id_name'] : null;
    $selfieBase64   = ($body['selfie']      ?? '') !== '' ? $body['selfie']      : null;
    $selfieFilename = ($body['selfie_name'] ?? '') !== '' ? $body['selfie_name'] : null;

    // Personal details
    $dateOfBirth = trim($body['date_of_birth'] ?? '');
    $city        = trim($body['city']          ?? '');
    $province    = trim($body['province']      ?? '');

    if (!$email || !$firstName || !$lastName || !$username) {
        http_response_code(400);
        echo json_encode(['error' => 'All required fields must be filled']);
        return;
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid email format']);
        return;
    }
    if (!str_ends_with(strtolower($email), '@gmail.com')) {
        http_response_code(400);
        echo json_encode(['error' => 'Only Gmail addresses (@gmail.com) are accepted']);
        return;
    }
    if (!$isGoogleSignup && strlen($password) < 8) {
        http_response_code(400);
        echo json_encode(['error' => 'Password must be at least 8 characters']);
        return;
    }

    $dup = $pdo->prepare("SELECT id FROM users WHERE email = :e OR username = :u LIMIT 1");
    $dup->execute([':e' => $email, ':u' => $username]);
    if ($dup->fetch()) {
        http_response_code(409);
        echo json_encode(['error' => 'An account with this email or username already exists.']);
        return;
    }

    $hash = $isGoogleSignup ? null : password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    $fullPhone = $phone ? $countryCode . $phone : null;

    // Ensure date_of_birth, city, province columns exist (added post-launch)
    $pdo->exec("ALTER TABLE users
        ADD COLUMN IF NOT EXISTS date_of_birth DATE         NULL AFTER phone,
        ADD COLUMN IF NOT EXISTS city          VARCHAR(100) NULL AFTER date_of_birth,
        ADD COLUMN IF NOT EXISTS province      VARCHAR(100) NULL AFTER city
    ");

    $ins = $pdo->prepare(
        "INSERT INTO users
            (email, password_hash, first_name, last_name, middle_name, suffix,
             username, role, phone, date_of_birth, city, province,
             user_status, kyc_status,
             gov_id_base64, gov_id_filename, selfie_base64, selfie_filename,
             google_id, created_at)
         VALUES
            (:email, :hash, :fn, :ln, :mn, :sfx,
             :username, :role, :phone, :dob, :city, :province,
             0, 'unverified',
             :gov_id, :gov_id_name, :selfie, :selfie_name,
             :gid, NOW())"
    );
    $ins->execute([
        ':email'       => $email,
        ':hash'        => $hash,
        ':fn'          => $firstName,
        ':ln'          => $lastName,
        ':mn'          => $middleName ?: null,
        ':sfx'         => $suffix ?: null,
        ':username'    => $username,
        ':role'        => $role,
        ':phone'       => $fullPhone,
        ':dob'         => $dateOfBirth ?: null,
        ':city'        => $city ?: null,
        ':province'    => $province ?: null,
        ':gov_id'      => $govIdBase64,
        ':gov_id_name' => $govIdFilename,
        ':selfie'      => $selfieBase64,
        ':selfie_name' => $selfieFilename,
        ':gid'         => $googleId ?: null,
    ]);

    $userId = (int)$pdo->lastInsertId();
    $token  = generateJWT(['user_id' => $userId, 'email' => $email, 'role' => $role]);

    try {
        _authNotifyAdmins($pdo, 'new_user', 'New User Registered', "{$firstName} {$lastName} (@{$username}) has signed up and is pending approval.", '/admin');
    } catch (\Exception $e) { error_log('signup notify: ' . $e->getMessage()); }

    http_response_code(201);
    echo json_encode([
        'message' => 'Account created successfully. Awaiting admin approval.',
        'token'   => $token,
        'user'    => [
            'id'          => $userId,
            'email'       => $email,
            'first_name'  => $firstName,
            'last_name'   => $lastName,
            'username'    => $username,
            'role'        => $role,
            'kyc_status'  => 'unverified',
            'user_status' => 0,
        ],
    ]);
}

function handleForgotPassword(PDO $pdo): void {
    $body  = json_decode(file_get_contents('php://input'), true) ?? [];
    $email = trim($body['email'] ?? '');

    if (!$email) {
        http_response_code(400);
        echo json_encode(['error' => 'Email is required']);
        return;
    }

    $stmt = $pdo->prepare("SELECT id, first_name, google_id, password_hash FROM users WHERE email = :e LIMIT 1");
    $stmt->execute([':e' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        // Don't reveal if email exists
        http_response_code(200);
        echo json_encode(['message' => 'If that email exists, a reset link has been sent.']);
        return;
    }

    // Google-only accounts have no password — direct them to Google Sign-In instead
    if (!empty($user['google_id']) && empty($user['password_hash'])) {
        http_response_code(400);
        echo json_encode(['error' => 'This account was created with Google Sign-In and does not have a password. Please use the "Continue with Google" button to log in.']);
        return;
    }

    $pdo->exec("CREATE TABLE IF NOT EXISTS password_resets (
        email      VARCHAR(255) PRIMARY KEY,
        token      VARCHAR(64)  NOT NULL,
        expires_at DATETIME     NOT NULL,
        INDEX idx_token (token)
    ) ENGINE=InnoDB;");

    // Rate limit: if a reset was sent less than 3 minutes ago, reject
    $recent = $pdo->prepare("SELECT expires_at FROM password_resets WHERE email = ? LIMIT 1");
    $recent->execute([$email]);
    $existingReset = $recent->fetch(PDO::FETCH_ASSOC);
    if ($existingReset && strtotime($existingReset['expires_at']) > strtotime('+12 minutes')) {
        http_response_code(429);
        echo json_encode(['message' => 'A reset link was recently sent. Please wait a few minutes before requesting again.']);
        return;
    }

    $token     = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));

    $pdo->prepare(
        "INSERT INTO password_resets (email, token, expires_at)
         VALUES (:e, :t, :exp)
         ON DUPLICATE KEY UPDATE token = :t2, expires_at = :exp2"
    )->execute([':e' => $email, ':t' => $token, ':exp' => $expiresAt, ':t2' => $token, ':exp2' => $expiresAt]);

    $resetLink = "http://localhost:3000/reset-password?token={$token}";
    _sendResetEmail($email, $user['first_name'], $resetLink);

    http_response_code(200);
    echo json_encode(['message' => 'If that email exists, a reset link has been sent.']);
}

function handleResetPassword(PDO $pdo): void {
    $body     = json_decode(file_get_contents('php://input'), true) ?? [];
    $token    = trim($body['token']    ?? '');
    $password = trim($body['password'] ?? '');

    if (!$token || !$password) {
        http_response_code(400);
        echo json_encode(['error' => 'Token and password are required']);
        return;
    }
    if (strlen($password) < 8) {
        http_response_code(400);
        echo json_encode(['error' => 'Password must be at least 8 characters']);
        return;
    }

    $stmt = $pdo->prepare(
        "SELECT email FROM password_resets
         WHERE token = :t AND expires_at > NOW() LIMIT 1"
    );
    $stmt->execute([':t' => $token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        http_response_code(400);
        echo json_encode(['error' => 'Reset link is invalid or has expired. Please request a new one.']);
        return;
    }

    // Double-check: block reset for Google-only accounts
    $userCheck = $pdo->prepare("SELECT google_id, password_hash FROM users WHERE email = :e LIMIT 1");
    $userCheck->execute([':e' => $row['email']]);
    $userRow = $userCheck->fetch(PDO::FETCH_ASSOC);
    if ($userRow && !empty($userRow['google_id']) && empty($userRow['password_hash'])) {
        http_response_code(400);
        echo json_encode(['error' => 'This account uses Google Sign-In and cannot have a password set this way.']);
        return;
    }

    $hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    $pdo->prepare("UPDATE users SET password_hash = :h WHERE email = :e")
        ->execute([':h' => $hash, ':e' => $row['email']]);

    $pdo->prepare("DELETE FROM password_resets WHERE email = :e")
        ->execute([':e' => $row['email']]);

    http_response_code(200);
    echo json_encode(['message' => 'Password reset successfully']);
}

function handleGoogleAuth(PDO $pdo): void {
    $pdo  = getDB(); // fresh connection — avoids MySQL gone away
    $body     = json_decode(file_get_contents('php://input'), true) ?? [];
    $idToken     = trim($body['id_token']     ?? '');
    $accessToken = trim($body['access_token'] ?? '');  // ← ADD THIS
    $deviceId    = trim($body['device_id']    ?? '');

    if (!$idToken && !$accessToken) {
        http_response_code(400);
        echo json_encode(['error' => 'ID token is required']);
        return;
    }

    // Try id_token first (Android/mobile)
    $payload  = null;
    $response = @file_get_contents('https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken));
    if ($response) {
        $tmp = json_decode($response, true);
        if (!isset($tmp['error_description']) && !empty($tmp['email'])) {
            $expectedClientId = '31131385571-rhrhdr9hk5t2jsrah4gho23k8rj4ctlf.apps.googleusercontent.com';
            if (($tmp['aud'] ?? '') === $expectedClientId) {
                $payload = $tmp;
            }
        }
    }

    // access_token fallback (Flutter Web)
    if (!$payload) {
        $tokenToUse = $accessToken ?: $idToken;  // ← use correct variable
        $response2  = @file_get_contents(
            'https://www.googleapis.com/oauth2/v1/userinfo?access_token=' . urlencode($tokenToUse)
        );
        if ($response2) {
            $tmp = json_decode($response2, true);
            if (!empty($tmp['email'])) {
                $tmp['sub'] = $tmp['id'] ?? '';
                $payload    = $tmp;
            }
        }
    }

    if (!$payload || empty($payload['email'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Failed to verify Google token']);
        return;
    }

    $email     = $payload['email'];
    $firstName = $payload['given_name']  ?? '';
    $lastName  = $payload['family_name'] ?? '';
    $googleId  = $payload['sub'];

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email LIMIT 1");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        // New Google user — client needs to complete signup form
        http_response_code(202);
        echo json_encode([
            'needs_signup' => true,
            'google_id'    => $googleId,
            'email'        => $email,
            'first_name'   => $firstName,
            'last_name'    => $lastName,
        ]);
        return;
    }

    $status = (int)$user['user_status'];
    if ($status === 0) {
        http_response_code(403);
        echo json_encode(['error' => 'Account is pending admin approval', 'status' => 'pending']);
        return;
    }
    if ($status === 2) {
        http_response_code(403);
        echo json_encode(['error' => 'Account application was rejected', 'status' => 'rejected']);
        return;
    }

    if (empty($user['google_id'])) {
        $pdo->prepare("UPDATE users SET google_id = :gid WHERE id = :id")
            ->execute([':gid' => $googleId, ':id' => $user['id']]);
    }

    $token = generateJWT(['user_id' => $user['id'], 'email' => $user['email'], 'role' => $user['role']]);
    $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = :id")->execute([':id' => $user['id']]);

    // Device / 2FA check
    try { $pdo->exec("CREATE TABLE IF NOT EXISTS trusted_devices (
        id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id   INT UNSIGNED NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_user_device (user_id, device_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"); } catch (Exception $ignored) {}
    if ($deviceId) {
        $devStmt = $pdo->prepare(
            "SELECT id FROM trusted_devices WHERE user_id = :uid AND device_id = :did LIMIT 1"
        );
        $devStmt->execute([':uid' => $user['id'], ':did' => $deviceId]);

        if (!$devStmt->fetch()) {
            $otpType = 'email'; // Web-only build: always use email OTP
            $maskedPhone = null;
            if (!empty($user['phone'])) {
                $maskedPhone = str_repeat('*', max(0, strlen($user['phone']) - 4))
                    . substr($user['phone'], -4);
            }
            http_response_code(200);
            echo json_encode([
                'requires_2fa'  => true,
                'otp_type'      => $otpType,
                'user_id'       => $user['id'],
                'token'         => $token,
                'masked_phone'  => $maskedPhone,
            ]);
            return;
        }
    }

    http_response_code(200);
    echo json_encode([
        'requires_2fa' => false,
        'token'        => $token,
        'user'         => _userPayload($user),
    ]);
}

function _sendResetEmail(string $email, string $firstName, string $resetLink): bool {
    return sendEmail($email, $firstName, 'Reset Your HIRAYA Password', _resetEmailBody($firstName, $resetLink));
}

function _resetEmailBody(string $name, string $link): string {
    return "
<div style='font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px;background:#f9f9f9;border-radius:12px;'>
  <h2 style='color:#0A2540;'>HIRAYA</h2>
  <p style='color:#444;'>Hi <strong>{$name}</strong>,</p>
  <p style='color:#444;'>We received a request to reset your password. Click the button below:</p>
  <table width='100%' cellspacing='0' cellpadding='0' style='margin:32px 0;'>
    <tr>
      <td align='center'>
        <table cellspacing='0' cellpadding='0'>
          <tr>
            <td style='background:#00897B;border-radius:8px;padding:14px 32px;'>
              <a href='{$link}' style='color:#ffffff;font-family:Arial,sans-serif;font-size:15px;font-weight:bold;text-decoration:none;display:inline-block;'>Reset My Password</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
  <p style='color:#888;font-size:13px;'>Or copy this link: <a href='{$link}' style='color:#00897B;'>{$link}</a></p>
  <p style='color:#888;font-size:13px;'>This link expires in <strong>15 minutes</strong> and can only be used once.</p>
  <p style='color:#888;font-size:13px;'>If you did not request this, ignore this email — your account is safe.</p>
  <hr style='border:none;border-top:1px solid #eee;margin:24px 0;'>
  <p style='color:#bbb;font-size:11px;text-align:center;'>HIRAYA Innovation Marketplace</p>
</div>";
}

function _createRateLimitTable(PDO $pdo): void {
    $pdo->exec("CREATE TABLE IF NOT EXISTS login_rate_limits (
        id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        identifier   VARCHAR(255) NOT NULL,
        attempted_at DATETIME     NOT NULL,
        INDEX idx_identifier_time (identifier, attempted_at)
    ) ENGINE=InnoDB;");
}

function _userPayload(array $user): array {
    return [
        'id'            => $user['id'],
        'email'         => $user['email'],
        'first_name'    => $user['first_name'],
        'last_name'     => $user['last_name'],
        'username'      => $user['username'],
        'role'          => $user['role'],
        'kyc_status'    => $user['kyc_status']    ?? 'unverified',
        'user_status'   => (int)($user['user_status'] ?? 0),
        'avatar_base64' => $user['avatar_base64'] ?? null,
    ];
}