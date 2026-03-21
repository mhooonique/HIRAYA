<?php
// api/v1/config/mail_config.php

require_once __DIR__ . '/env.php';

define('MAIL_HOST',     env('MAIL_HOST',     'smtp.gmail.com'));
define('MAIL_PORT',     (int) env('MAIL_PORT', '587'));
define('MAIL_USERNAME', env('MAIL_USERNAME'));
define('MAIL_PASSWORD', env('MAIL_PASSWORD'));
define('MAIL_FROM',     env('MAIL_FROM'));
define('MAIL_NAME',     env('MAIL_NAME',     'HIRAYA Platform'));
