<?php
// api/v1/config/jwt.php

require_once __DIR__ . '/env.php';

define('JWT_SECRET', env('JWT_SECRET'));

function generateJWT(array $payload): string {
    $header = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload['iat'] = time();
    $payload['exp'] = time() + (60 * 60 * 24 * 30); // 30 days
    $payloadEncoded = base64_encode(json_encode($payload));
    $signature = base64_encode(
        hash_hmac('sha256', "$header.$payloadEncoded", JWT_SECRET, true)
    );
    return "$header.$payloadEncoded.$signature";
}

function verifyJWT(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$header, $payload, $signature] = $parts;
    $expectedSig = base64_encode(
        hash_hmac('sha256', "$header.$payload", JWT_SECRET, true)
    );
    if (!hash_equals($expectedSig, $signature)) return null;
    $data = json_decode(base64_decode($payload), true);
    if ($data['exp'] < time()) return null;
    return $data;
}

function getAuthUser(): ?array {
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? '';
    if (!str_starts_with($auth, 'Bearer ')) return null;
    $token = substr($auth, 7);
    return verifyJWT($token);
}
