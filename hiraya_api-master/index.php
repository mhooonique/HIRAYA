<?php
// hiraya_api/index.php

require_once __DIR__ . '/api/v1/config/env.php';

// ── CORS ─────────────────────────────────────────────────────────────────────
$allowedOrigins = array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost')));
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

if (in_array($origin, $allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header('Access-Control-Allow-Credentials: true');
    header('Vary: Origin');
} else {
    // Reject preflight from unknown origins
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(403);
        exit;
    }
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/api/v1/config/database.php';
require_once __DIR__ . '/api/v1/config/jwt.php';
require_once __DIR__ . '/api/v1/endpoints/auth.php';
require_once __DIR__ . '/api/v1/endpoints/products.php';
require_once __DIR__ . '/api/v1/endpoints/users.php';
require_once __DIR__ . '/api/v1/endpoints/admin.php';
require_once __DIR__ . '/api/v1/endpoints/innovator.php';
require_once __DIR__ . '/api/v1/endpoints/notifications.php';
require_once __DIR__ . '/api/v1/endpoints/otp.php';
require_once __DIR__ . '/api/v1/endpoints/messages.php';
require_once __DIR__ . '/api/v1/endpoints/search.php';

$pdo    = getDB();
$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri    = preg_replace('#^/hiraya_api/api/v1#', '', $uri);
$uri    = rtrim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'];

// Split path into segments: /admin/users/5 → ['admin','users','5']
$segments = array_values(array_filter(explode('/', ltrim($uri, '/'))));
$base     = $segments[0] ?? '';
$sub      = $segments[1] ?? '';

switch ($base) {

    // ── Auth ──────────────────────────────────────────────────────────────────
    case 'auth':
        switch ($sub) {
            case 'login':          handleLogin($pdo);         break;
            case 'signup':
            case 'register':       handleSignup($pdo);        break;
            case 'google':         handleGoogleAuth($pdo);    break;
            case 'forgot-password':handleForgotPassword($pdo);break;
            case 'reset-password': handleResetPassword($pdo); break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'Auth route not found']);
        }
        break;

    // ── OTP ───────────────────────────────────────────────────────────────────
    case 'otp':
        switch ($sub) {
            case 'send':   handleSendOtp($pdo);   break;
            case 'verify': handleVerifyOtp($pdo); break;
            case 'resend': handleResendOtp($pdo); break;
            default:
                http_response_code(404);
                echo json_encode(['error' => 'OTP route not found']);
        }
        break;

    // ── Products ──────────────────────────────────────────────────────────────
    case 'products':
        handleProducts($pdo, $method, $segments);
        break;

    // ── Admin ─────────────────────────────────────────────────────────────────
    case 'admin':
        handleAdmin($pdo, $method, $segments);
        break;

    // ── Innovator ─────────────────────────────────────────────────────────────
    case 'innovator':
        handleInnovator($pdo, $method, $segments);
        break;

    // ── Users ─────────────────────────────────────────────────────────────────
    case 'users':
        handleUsers($pdo, $method, $segments);
        break;

    // ── Notifications ─────────────────────────────────────────────────────────
    case 'notifications':
        handleNotifications($pdo, $method, $segments);
        break;

    // ── Messages ───────────────────────────────────────────────────────────────
    case 'messages':
        handleMessages($pdo, $method, $segments);
        break;

    // ── Search ─────────────────────────────────────────────────────────────────
    case 'search':
        handleSearch($pdo, $method, $segments);
        break;

    default:
        http_response_code(404);
        echo json_encode(['error' => "Route not found: /$base"]);
}

function notFound(): void {
    http_response_code(404);
    echo json_encode(['error' => 'Route not found']);
}