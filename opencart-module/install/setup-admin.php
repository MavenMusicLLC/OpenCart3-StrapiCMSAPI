<?php
/**
 * OpenCart Admin Setup Script
 * Run via: php setup-admin.php
 */

$admin_user = 'admin';
$admin_pass = 'Geau@3x$';
$db_host = getenv('DB_HOST') ?: 'localhost';
$db_user = getenv('DB_USER') ?: 'ocdev1';
$db_pass = getenv('DB_PASS') ?: '';
$db_name = getenv('DB_NAME') ?: '';

// Generate salt and password
$salt = substr(token_hex(16), 0, 16);
$password = hash('sha512', $salt . $admin_pass);

// CLI args override env
if (isset($argv[1])) $db_name = $argv[1];
if (isset($argv[2])) $db_user = $argv[2];
if (isset($argv[3])) $db_pass = $argv[3];

if (empty($db_name)) {
    echo "Usage: php setup-admin.php [db_name] [db_user] [db_pass]\n";
    exit(1);
}

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if oc_user table exists
    $tables = $pdo->query("SHOW TABLES LIKE 'oc_user'")->fetchAll();
    if (empty($tables)) {
        echo "Error: oc_user table not found. Is OpenCart installed?\n";
        exit(1);
    }
    
    // Delete existing admin and create new one
    $pdo->exec("DELETE FROM `oc_user` WHERE `username` = 'admin'");
    
    $stmt = $pdo->prepare("INSERT INTO `oc_user` 
        (`user_group_id`, `username`, `salt`, `password`, `firstname`, `lastname`, `email`, `code`, `ip`, `status`, `date_added`)
        VALUES (1, ?, ?, ?, 'Admin', 'User', 'admin@example.com', '', '0.0.0.0', 1, NOW())");
    
    $stmt->execute([$admin_user, $salt, $password]);
    
    echo "Admin user created successfully!\n";
    echo "Username: $admin_user\n";
    echo "Password: $admin_pass\n";
    echo "Salt: $salt\n";
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
