<?php
class ModelModuleBundle extends Model {
    private $api_url;
    private $api_enabled;
    private $cache_ttl;
    
    public function __construct($registry) {
        parent::__construct($registry);
        
        // Load settings from database or use defaults
        $query = $this->db->query("SELECT `key`, `value` FROM " . DB_PREFIX . "bundle_settings WHERE `key` IN ('api_url', 'api_enabled', 'cache_ttl')");
        
        $settings = array();
        foreach ($query->rows as $row) {
            $settings[$row['key']] = $row['value'];
        }
        
        // Use defined constant or setting
        $this->api_url = defined('STRAPI_API_URL') ? STRAPI_API_URL : 
                        (!empty($settings['api_url']) ? $settings['api_url'] : 'http://localhost:1337/api');
        $this->api_enabled = !empty($settings['api_enabled']) ? true : false;
        $this->cache_ttl = !empty($settings['cache_ttl']) ? (int)$settings['cache_ttl'] : 3600;
    }

    public function getBundles($limit = 10, $category_id = 0) {
        $cache_key = 'bundle.list.' . $limit . '.' . $category_id;
        $cached = $this->cache->get($cache_key);
        if ($cached) {
            return $cached;
        }

        // Try Strapi API first if enabled
        if ($this->api_enabled) {
            $bundles = $this->getBundlesFromAPI($limit, $category_id);
            if (!empty($bundles)) {
                $this->cache->set($cache_key, $bundles);
                return $bundles;
            }
        }

        // Fallback to local database
        $bundles = $this->getBundlesFromDB($limit, $category_id);
        $this->cache->set($cache_key, $bundles);
        
        return $bundles;
    }

    private function getBundlesFromAPI($limit = 10, $category_id = 0) {
        $url = $this->api_url . '/bundles?pagination[limit]=' . (int)$limit . '&filters[isActive][$eq]=true&sort=sortOrder:asc';
        
        if ($category_id) {
            $url .= '&filters[categories][$contains]=' . (int)$category_id;
        }

        $context = stream_context_create(array(
            'http' => array(
                'timeout' => 5, 
                'ignore_errors' => true,
                'header' => "Accept: application/json\r\n"
            )
        ));
        
        $response = @file_get_contents($url, false, $context);
        
        if (!$response) {
            return array();
        }

        $result = json_decode($response, true);
        
        if (!empty($result['data'])) {
            $bundles = array();
            foreach ($result['data'] as $item) {
                $attributes = isset($item['attributes']) ? $item['attributes'] : $item;
                $bundles[] = array(
                    'id' => $item['id'] ?? 0,
                    'name' => $attributes['name'] ?? '',
                    'slug' => $attributes['slug'] ?? '',
                    'description' => $attributes['description'] ?? '',
                    'image' => $attributes['image'] ?? '',
                    'images' => $attributes['images'] ?? array(),
                    'original_price' => (float)($attributes['originalPrice'] ?? 0),
                    'bundle_price' => (float)($attributes['bundlePrice'] ?? 0),
                    'discount' => (float)($attributes['discountPercent'] ?? 0),
                    'products' => $attributes['products'] ?? array(),
                    'categories' => $attributes['categories'] ?? array(),
                    'stock' => (int)($attributes['stock'] ?? 0),
                    'sku' => $attributes['sku'] ?? ''
                );
            }
            return $bundles;
        }

        return array();
    }

    private function getBundlesFromDB($limit = 10, $category_id = 0) {
        $sql = "SELECT * FROM " . DB_PREFIX . "bundles WHERE status = 1";
        
        if ($category_id) {
            $sql .= " AND (categories LIKE '%\"" . (int)$category_id . "\"%' OR categories = '[]' OR categories = '' OR categories IS NULL)";
        }
        
        $sql .= " ORDER BY sort_order ASC, date_added DESC LIMIT " . (int)$limit;
        
        $query = $this->db->query($sql);
        
        $bundles = array();
        foreach ($query->rows as $row) {
            $products = json_decode($row['products'], true) ?: array();
            $categories = json_decode($row['categories'], true) ?: array();
            $images = json_decode($row['images'], true) ?: array();
            
            $bundles[] = array(
                'id' => $row['bundle_id'],
                'name' => $row['name'],
                'slug' => $row['slug'],
                'description' => $row['description'],
                'image' => $row['image'],
                'images' => $images,
                'original_price' => (float)$row['original_price'],
                'bundle_price' => (float)$row['bundle_price'],
                'discount' => (float)$row['discount_percent'],
                'products' => $products,
                'categories' => $categories,
                'stock' => (int)$row['stock'],
                'sku' => $row['sku']
            );
        }
        
        return $bundles;
    }

    public function getBundleById($bundle_id) {
        $cache_key = 'bundle.item.' . $bundle_id;
        $cached = $this->cache->get($cache_key);
        if ($cached) {
            return $cached;
        }

        // Try API first
        if ($this->api_enabled) {
            $bundle = $this->getBundleFromAPI($bundle_id);
            if ($bundle) {
                $this->cache->set($cache_key, $bundle);
                return $bundle;
            }
        }

        // Fallback to database
        $bundle = $this->getBundleFromDB($bundle_id);
        if ($bundle) {
            $this->cache->set($cache_key, $bundle);
        }
        
        return $bundle;
    }

    private function getBundleFromAPI($bundle_id) {
        $url = $this->api_url . '/bundles/' . (int)$bundle_id;
        
        $context = stream_context_create(array(
            'http' => array(
                'timeout' => 5, 
                'ignore_errors' => true,
                'header' => "Accept: application/json\r\n"
            )
        ));
        
        $response = @file_get_contents($url, false, $context);
        
        if ($response) {
            $result = json_decode($response, true);
            if (isset($result['data'])) {
                $attributes = $result['data']['attributes'] ?? $result['data'];
                $bundle = array(
                    'id' => $result['data']['id'] ?? $bundle_id,
                    'name' => $attributes['name'] ?? '',
                    'slug' => $attributes['slug'] ?? '',
                    'description' => $attributes['description'] ?? '',
                    'short_description' => $attributes['shortDescription'] ?? '',
                    'image' => $attributes['image'] ?? '',
                    'images' => $attributes['images'] ?? array(),
                    'original_price' => (float)($attributes['originalPrice'] ?? 0),
                    'bundle_price' => (float)($attributes['bundlePrice'] ?? 0),
                    'discount' => (float)($attributes['discountPercent'] ?? 0),
                    'products' => $attributes['products'] ?? array(),
                    'stock' => (int)($attributes['stock'] ?? 0),
                    'sku' => $attributes['sku'] ?? '',
                    'meta_title' => $attributes['metaTitle'] ?? '',
                    'meta_description' => $attributes['metaDescription'] ?? ''
                );
                return $bundle;
            }
        }

        return null;
    }

    private function getBundleFromDB($bundle_id) {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE bundle_id = '" . (int)$bundle_id . "' AND status = 1");
        
        if ($query->num_rows) {
            $row = $query->row;
            return array(
                'id' => $row['bundle_id'],
                'name' => $row['name'],
                'slug' => $row['slug'],
                'description' => $row['description'],
                'short_description' => $row['short_description'],
                'image' => $row['image'],
                'images' => json_decode($row['images'], true) ?: array(),
                'original_price' => (float)$row['original_price'],
                'bundle_price' => (float)$row['bundle_price'],
                'discount' => (float)$row['discount_percent'],
                'products' => json_decode($row['products'], true) ?: array(),
                'stock' => (int)$row['stock'],
                'sku' => $row['sku'],
                'meta_title' => $row['meta_title'] ?? '',
                'meta_description' => $row['meta_description'] ?? ''
            );
        }
        
        return null;
    }

    public function getProducts($product_ids) {
        if (empty($product_ids)) {
            return array();
        }

        $ids = array_filter(array_map('intval', $product_ids));
        
        if (empty($ids)) {
            return array();
        }
        
        $sql = "SELECT p.product_id, pd.name, p.model, p.price, p.image, p.quantity, p.status 
                FROM " . DB_PREFIX . "product p 
                LEFT JOIN " . DB_PREFIX . "product_description pd ON p.product_id = pd.product_id 
                WHERE p.product_id IN (" . implode(',', $ids) . ") 
                AND pd.language_id = '" . (int)$this->config->get('config_language_id') . "'";
        
        $query = $this->db->query($sql);
        
        $products = array();
        foreach ($query->rows as $row) {
            $products[$row['product_id']] = $row;
        }
        
        return $products;
    }

    public function getBundlesByProduct($product_id) {
        if ($this->api_enabled) {
            $url = $this->api_url . '/bundles/by-product/' . (int)$product_id;
            
            $context = stream_context_create(array(
                'http' => array(
                    'timeout' => 5, 
                    'ignore_errors' => true,
                    'header' => "Accept: application/json\r\n"
                )
            ));
            
            $response = @file_get_contents($url, false, $context);
            
            if ($response) {
                $result = json_decode($response, true);
                if (!empty($result['data'])) {
                    return $result['data'];
                }
            }
        }

        // Fallback to database
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE status = 1 AND products LIKE '%\"" . (int)$product_id . "\"%' ORDER BY sort_order ASC");
        
        $bundles = array();
        foreach ($query->rows as $row) {
            $row['products'] = json_decode($row['products'], true) ?: array();
            $bundles[] = $row;
        }
        
        return $bundles;
    }

    public function getTotalBundles($category_id = 0) {
        $sql = "SELECT COUNT(*) as total FROM " . DB_PREFIX . "bundles WHERE status = 1";
        
        if ($category_id) {
            $sql .= " AND (categories LIKE '%\"" . (int)$category_id . "\"%' OR categories = '[]' OR categories = '' OR categories IS NULL)";
        }
        
        $query = $this->db->query($sql);
        return (int)$query->row['total'];
    }

    public function getBundleSettings() {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundle_settings");
        
        $settings = array();
        foreach ($query->rows as $row) {
            $settings[$row['key']] = $row['value'];
        }
        
        return $settings;
    }

    public function setBundleSetting($key, $value) {
        $this->db->query("DELETE FROM " . DB_PREFIX . "bundle_settings WHERE `key` = '" . $this->db->escape($key) . "'");
        $this->db->query("INSERT INTO " . DB_PREFIX . "bundle_settings (`key`, value) VALUES ('" . $this->db->escape($key) . "', '" . $this->db->escape($value) . "')");
    }
}