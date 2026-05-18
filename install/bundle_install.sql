-- Bundle Manager for OpenCart 3.x + Strapi Integration
-- Run this SQL on your OpenCart database

-- Create bundles table
CREATE TABLE IF NOT EXISTS `oc_bundles` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create bundle_products table for detailed product associations
CREATE TABLE IF NOT EXISTS `oc_bundle_products` (
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
  KEY `product_id` (`product_id`),
  CONSTRAINT `fk_bundle_product_bundle` FOREIGN KEY (`bundle_id`) REFERENCES `oc_bundles` (`bundle_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bundle_product_product` FOREIGN KEY (`product_id`) REFERENCES `oc_product` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create settings table for module configuration
CREATE TABLE IF NOT EXISTS `oc_bundle_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(100) NOT NULL,
  `value` text,
  `serialized` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default settings
INSERT INTO `oc_bundle_settings` (`key`, `value`) VALUES
('api_url', 'http://localhost:1337/api'),
('api_enabled', '1'),
('cache_ttl', '3600'),
('show_on_product_page', '1'),
('default_title', 'Product Bundles')
ON DUPLICATE KEY UPDATE `id`=`id`;

-- Add order total extension for bundle discounts
CREATE TABLE IF NOT EXISTS `oc_bundles_order_discount` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `bundle_id` int(11) NOT NULL,
  `bundle_name` varchar(255) NOT NULL,
  `discount_amount` decimal(15,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;