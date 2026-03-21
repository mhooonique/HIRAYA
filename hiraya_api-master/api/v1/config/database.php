<?php
// api/v1/config/database.php

require_once __DIR__ . '/env.php';

function getDB(): PDO {
    $host    = env('DB_HOST', 'localhost');
    $port    = env('DB_PORT', '3307');
    $db      = env('DB_NAME', 'db_hiraya');
    $user    = env('DB_USER', 'root');
    $pass    = env('DB_PASS', '');
    $charset = 'utf8mb4';

    $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=$charset";
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET SESSION wait_timeout=600, interactive_timeout=600",
    ];
    return new PDO($dsn, $user, $pass, $options);
}
