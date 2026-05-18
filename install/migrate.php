<?php
/**
 * Bundle Manager Migration Script for OpenCart 3.x
 * 
 * Run this script from the OpenCart root directory:
 * php install/migrate.php
 * 
 * This script:
 * - Creates bundle tables
 * - Adds required configuration
 * - Inserts sample data (optional)
 * - Checks Strapi connectivity
 */

// Bootstrap OpenCart
if (!file_exists('config.php')) {
    die("Error: Please run this script from the OpenCart root directory.\n");
}

require_once 'config.php';

// Database connection
$link = new mysqli(DB_HOSTNAME, DB_USERNAME, DB_PASSWORD, DB_DATABASE, DB_PORT);

if ($link->connect_error) {
    die("Database connection failed: " . $link->connect_error . "\n");
}

$link->set_charset("utf8mb4");

echo "========================================\n";
echo "  Bundle Manager Migration\n";
echo "========================================\n\n";

// 1. Create tables
echo "Creating bundle tables...\n";

$tables = [
    "CREATE TABLE IF NOT EXISTS `" . DB_PREFIX . "bundles` (
        `bundle_id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `slug` varchar(255) NOT NULL,
        `description` text,
        `short_description` varchar(500),
        `image` varchar(255),
        `images` text COMMENT 'JSON array of image URLs',
        `original_price` decimal(15,2) NOT NULL DEFAULT 0.00,
        `bundle_price` decimal(15,2) NOT NULL DEFAULT 0.00,
        `discount_percent` decimal(5,2) DEFAULT 0.00,
        `products` text NOT NULL COMMENT 'JSON array of {productId, name, price, quantity, image}',
        `categories` text COMMENT 'JSON array of category IDs',
        `stock` int(11) DEFAULT 0,
        `sku` varchar(100),
        `meta_title` varchar(255),
        `meta_description` varchar(500),
        `status` tinyint(1) NOT NULL DEFAULT 1,
        `sort_order` int(11) DEFAULT 0,
        `valid_from` datetime DEFAULT NULL,
        `valid_to` datetime DEFAULT NULL,
        `date_added` datetime NOT NULL,
        `date_modified` datetime NOT NULL,
        PRIMARY KEY (`bundle_id`),
        UNIQUE KEY `slug` (`slug`),
        KEY `status` (`status`),
        KEY `sort_order` (`sort_order`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
    
    "CREATE TABLE IF NOT EXISTS `" . DB_PREFIX . "bundle_products` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `bundle_id` int(11) NOT NULL,
        `product_id` int(11) NOT NULL,
        `product_name` varchar(255),
        `model` varchar(100),
        `quantity` int(3) NOT NULL DEFAULT 1,
        `price` decimal(15,2) DEFAULT 0.00,
        `image` varchar(255),
        `options` text COMMENT 'JSON of selected options',
        `sort_order` int(3) DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `bundle_id` (`bundle_id`),
        KEY `product_id` (`product_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
    
    "CREATE TABLE IF NOT EXISTS `" . DB_PREFIX . "bundle_settings` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `key` varchar(100) NOT NULL,
        `value` text,
        `serialized` tinyint(1) DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `key` (`key`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
];

foreach ($tables as $sql) {
    if ($link->query($sql) === TRUE) {
        echo "  [OK] Table created/updated\n";
    } else {
        echo "  [ERROR] " . $link->error . "\n";
    }
}

// 2. Add foreign key constraints (safely - will fail if products table doesn't exist)
echo "\nAdding constraints...\n";

$constraints = [
    "ALTER TABLE `" . DB_PREFIX . "bundle_products` 
     ADD CONSTRAINT `fk_bundle_product_bundle` 
     FOREIGN KEY (`bundle_id`) REFERENCES `" . DB_PREFIX . "bundles` (`bundle_id`) ON DELETE CASCADE",
    
    "ALTER TABLE `" . DB_PREFIX . "bundle_products` 
     ADD CONSTRAINT `fk_bundle_product_product` 
     FOREIGN KEY (`product_id`) REFERENCES `" . DB_PREFIX . "product` (`product_id`) ON DELETE CASCADE"
];

foreach ($constraints as $sql) {
    try {
        if ($link->query($sql) === TRUE) {
            echo "  [OK] Constraint added\n";
        }
    } catch (Exception $e) {
        echo "  [INFO] Constraint skipped: " . $e->getMessage() . "\n";
    }
}

// 3. Insert default settings
echo "\nInserting default settings...\n";

$settings = [
    ['api_url', 'http://localhost:1337/api'],
    ['api_enabled', '1'],
    ['cache_ttl', '3600'],
    ['show_on_product_page', '1'],
    ['default_title', 'Product Bundles'],
    ['auto_sync', '0']
];

$stmt = $link->prepare("INSERT INTO `" . DB_PREFIX . "bundle_settings` (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)");

foreach ($settings as $setting) {
    $stmt->bind_param("ss", $setting[0], $setting[1]);
    if ($stmt->execute()) {
        echo "  [OK] Setting: {$setting[0]} = {$setting[1]}\n";
    } else {
        echo "  [ERROR] {$link->error}\n";
    }
}

$stmt->close();

// 4. Add sample data (optional)
echo "\nDo you want to add sample bundle data? (y/n): ";
$handle = fopen("php://stdin", "r");
$line = fgets($handle);

if (trim(strtolower($line)) === 'y') {
    echo "Adding sample bundles...\n";
    
    // Sample Gaming PC Bundle
    $sample_bundles = [
        [
            'name' => 'Gaming PC Bundle - Entry Level',
            'slug' => 'gaming-pc-bundle-entry-level',
            'description' => '<p>Complete gaming PC bundle with everything you need to start gaming.</p>',
            'short_description' => 'Intel i5, RTX 3050, 16GB RAM, 1TB SSD',
            'image' => '',
            'images' => json_encode([]),
            'original_price' => 950.00,
            'bundle_price' => 899.00,
            'discount_percent' => 5.37,
            'products' => json_encode([
                ['productId' => '1', 'name' => 'Intel Core i5-12400F', 'price' => 250.00, 'quantity' => 1, 'image' => ''],
                ['productId' => '2', 'name' => 'ASUS RTX 3050 8GB', 'price' => 320.00, 'quantity' => 1, 'image' => ''],
                ['productId' => '3', 'name' => 'Corsair 16GB DDR4 3200MHz', 'price' => 80.00, 'quantity' => 2, 'image' => ''],
                ['productId' => '4', 'name' => '1TB NVMe SSD', 'price' => 120.00, 'quantity' => 1, 'image' => '']
            ]),
            'categories' => json_encode([1]),
            'stock' => 10,
            'sku' => 'BUNDLE-GAMING-001',
            'meta_title' => 'Gaming PC Bundle - Entry Level',
            'meta_description' => 'Complete gaming PC bundle at a discounted price',
            'status' => 1,
            'sort_order' => 1,
            'valid_from' => null,
            'valid_to' => null
        ],
        [
            'name' => 'Pro Workstation Bundle',
            'slug' => 'pro-workstation-bundle',
            'description' => '<p>Professional workstation for content creators and developers.</p>',
            'short_description' => 'AMD Ryzen 9, RTX 4070, 64GB RAM, 2TB SSD',
            'image' => '',
            'images' => json_encode([]),
            'original_price' => 2850.00,
            'bundle_price' => 2699.00,
            'discount_percent' => 5.30,
            'products' => json_encode([
                ['productId' => '5', 'name' => 'AMD Ryzen 9 7950X', 'price' => 550.00, 'quantity' => 1, 'image' => ''],
                ['productId' => '6', 'name' => 'NVIDIA RTX 4070 Ti', 'price' => 800.00, 'quantity' => 1, 'image' => ''],
                ['productId' => '7', 'name' => 'G.SKILL 64GB DDR5 6000MHz', 'price' => 300.00, 'quantity' => 2, 'image' => ''],
                ['productId' => '8', 'name' => '2TB NVMe Gen4 SSD', 'price' => 250.00, 'quantity' => 1, 'image' => '']
            ]),
            'categories' => json_encode([1]),
            'stock' => 5,
            'sku' => 'BUNDLE-PRO-001',
            'meta_title' => 'Pro Workstation Bundle',
            'meta_description' => 'Professional workstation bundle for creators',
            'status' => 1,
            'sort_order' => 2,
            'valid_from' => null,
            'valid_to' => null
        ]
    ];
    
    $stmt = $link->prepare("INSERT INTO `" . DB_PREFIX . "bundles` 
        (`name`, `slug`, `description`, `short_description`, `image`, `images`, `original_price`, `bundle_price`, `discount_percent`, `products`, `categories`, `stock`, `sku`, `meta_title`, `meta_description`, `status`, `sort_order`, `valid_from`, `valid_to`, `date_added`, `date_modified`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE 
        `name` = VALUES(`name`), `description` = VALUES(`description`), `bundle_price` = VALUES(`bundle_price`)");
    
    foreach ($sample_bundles as $bundle) {
        $stmt->bind_param(
            "ssssssdddssissssiiss",
            $bundle['name'], $bundle['slug'], $bundle['description'], $bundle['short_description'],
            $bundle['image'], $bundle['images'], $bundle['original_price'], $bundle['bundle_price'],
            $bundle['discount_percent'], $bundle['products'], $bundle['categories'],
            $bundle['stock'], $bundle['sku'], $bundle['meta_title'], $bundle['meta_description'],
            $bundle['status'], $bundle['sort_order'], $bundle['valid_from'], $bundle['valid_to']
        );
        
        if ($stmt->execute()) {
            echo "  [OK] Sample bundle: {$bundle['name']}\n";
        } else {
            echo "  [ERROR] " . $link->error . "\n";
        }
    }
    
    $stmt->close();
}

// 5. Check Strapi connectivity
echo "\nChecking Strapi connectivity...\n";
$strapi_url = 'http://localhost:1337/api/bundles';
$ch = curl_init($strapi_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($http_code == 200) {
    echo "  [OK] Strapi API is accessible at $strapi_url\n";
} else {
    echo "  [WARN] Strapi API not accessible (HTTP $http_code).\n";
    echo "         Make sure Strapi is running.\n";
}

// 6. Update config.php with Strapi API URL
echo "\nUpdating OpenCart config...\n";
$config_file = 'config.php';
$config_content = file_get_contents($config_file);

if (strpos($config_content, 'STRAPI_API_URL') === false) {
    $config_content .= "\n// Bundle Manager - Strapi API Integration\n";
    $config_content .= "define('STRAPI_API_URL', 'http://localhost:1337/api');\n";
    
    if (file_put_contents($config_file, $config_content)) {
        echo "  [OK] Added STRAPI_API_URL to config.php\n";
    } else {
        echo "  [WARN] Could not update config.php (permission issue?)\n";
    }
} else {
    echo "  [OK] STRAPI_API_URL already in config.php\n";
}

// Also update admin config
$admin_config = 'admin/config.php';
if (file_exists($admin_config)) {
    $admin_config_content = file_get_contents($admin_config);
    if (strpos($admin_config_content, 'STRAPI_API_URL') === false) {
        $admin_config_content .= "\n// Bundle Manager - Strapi API Integration\n";
        $admin_config_content .= "define('STRAPI_API_URL', 'http://localhost:1337/api');\n";
        file_put_contents($admin_config, $admin_config_content);
        echo "  [OK] Added STRAPI_API_URL to admin/config.php\n";
    }
}

// Close database connection
$link->close();

echo "\n========================================\n";
echo "  Migration Complete!\n";
echo "========================================\n";
echo "\nNext steps:\n";
echo "  1. Start Strapi: cd ../api-oc.noxhosting.cloud && npm start\n";
echo "  2. Go to Strapi Admin: http://localhost:1337/admin\n";
echo "  3. Create bundles in Strapi Content Manager\n";
echo "  4. Configure OpenCart: Extensions > Modules > Bundle Manager\n";
echo "  5. Add bundle module to your store layout\n";
echo "\nAPI Endpoints:\n";
echo "  GET  /api/bundles - List all bundles\n";
echo "  GET  /api/bundles/:id - Get bundle by ID\n";
echo "  GET  /api/bundles/by-slug/:slug - Get bundle by slug\n";
echo "  POST /api/bundles/sync - Sync from OpenCart\n";
echo "\n";