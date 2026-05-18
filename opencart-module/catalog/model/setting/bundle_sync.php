<?php
class ModelSettingBundleSync extends Model {
    public function getBundles($data = array()) {
        $sql = "SELECT * FROM " . DB_PREFIX . "bundles WHERE status = 1";
        
        $sort_data = array(
            'name',
            'sort_order',
            'date_added'
        );

        if (isset($data['sort']) && in_array($data['sort'], $sort_data)) {
            $sql .= " ORDER BY " . $data['sort'];
        } else {
            $sql .= " ORDER BY sort_order ASC, date_added DESC";
        }

        if (isset($data['order']) && ($data['order'] == 'DESC')) {
            $sql .= " DESC";
        } else {
            $sql .= " ASC";
        }

        if (isset($data['start']) || isset($data['limit'])) {
            if ($data['start'] < 0) {
                $data['start'] = 0;
            }

            if ($data['limit'] < 1) {
                $data['limit'] = 20;
            }

            $sql .= " LIMIT " . (int)$data['start'] . "," . (int)$data['limit'];
        }

        $query = $this->db->query($sql);

        return $query->rows;
    }

    public function getBundle($bundle_id) {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE bundle_id = '" . (int)$bundle_id . "' AND status = 1");

        if ($query->num_rows) {
            $bundle = $query->row;
            $bundle['products'] = json_decode($bundle['products'], true) ?: array();
            $bundle['categories'] = json_decode($bundle['categories'], true) ?: array();
            $bundle['images'] = json_decode($bundle['images'], true) ?: array();
            return $bundle;
        }

        return null;
    }

    public function getBundleBySlug($slug) {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE slug = '" . $this->db->escape($slug) . "' AND status = 1");

        if ($query->num_rows) {
            $bundle = $query->row;
            $bundle['products'] = json_decode($bundle['products'], true) ?: array();
            $bundle['categories'] = json_decode($bundle['categories'], true) ?: array();
            return $bundle;
        }

        return null;
    }

    public function getTotalBundles($data = array()) {
        $sql = "SELECT COUNT(*) as total FROM " . DB_PREFIX . "bundles WHERE status = 1";
        
        $query = $this->db->query($sql);
        return $query->row['total'];
    }

    public function addBundle($data) {
        $fields = array(
            'name' => $data['name'],
            'slug' => isset($data['slug']) ? $this->slugify($data['name']) : $data['slug'],
            'description' => $data['description'] ?? '',
            'short_description' => $data['short_description'] ?? '',
            'image' => $data['image'] ?? '',
            'images' => json_encode($data['images'] ?? array()),
            'original_price' => $data['original_price'],
            'bundle_price' => $data['bundle_price'],
            'discount_percent' => $data['discount_percent'] ?? 0,
            'products' => json_encode($data['products']),
            'categories' => json_encode($data['categories'] ?? array()),
            'stock' => $data['stock'] ?? 0,
            'sku' => $data['sku'] ?? '',
            'meta_title' => $data['meta_title'] ?? '',
            'meta_description' => $data['meta_description'] ?? '',
            'status' => $data['status'] ?? 1,
            'sort_order' => $data['sort_order'] ?? 0,
            'valid_from' => $data['valid_from'] ?? null,
            'valid_to' => $data['valid_to'] ?? null,
            'date_added' => date('Y-m-d H:i:s'),
            'date_modified' => date('Y-m-d H:i:s')
        );

        $sql = "INSERT INTO " . DB_PREFIX . "bundles SET ";
        foreach ($fields as $key => $value) {
            $sql .= "`$key` = '" . (is_null($value) ? 'NULL' : $this->db->escape($value)) . "', ";
        }
        $sql = rtrim($sql, ', ');

        $this->db->query($sql);
        return $this->db->getLastId();
    }

    public function editBundle($bundle_id, $data) {
        $fields = array(
            'name' => $data['name'],
            'slug' => $data['slug'] ?? $this->slugify($data['name']),
            'description' => $data['description'] ?? '',
            'short_description' => $data['short_description'] ?? '',
            'image' => $data['image'] ?? '',
            'images' => json_encode($data['images'] ?? array()),
            'original_price' => $data['original_price'],
            'bundle_price' => $data['bundle_price'],
            'discount_percent' => $data['discount_percent'] ?? 0,
            'products' => json_encode($data['products']),
            'categories' => json_encode($data['categories'] ?? array()),
            'stock' => $data['stock'] ?? 0,
            'sku' => $data['sku'] ?? '',
            'meta_title' => $data['meta_title'] ?? '',
            'meta_description' => $data['meta_description'] ?? '',
            'status' => $data['status'] ?? 1,
            'sort_order' => $data['sort_order'] ?? 0,
            'valid_from' => $data['valid_from'] ?? null,
            'valid_to' => $data['valid_to'] ?? null,
            'date_modified' => date('Y-m-d H:i:s')
        );

        $sql = "UPDATE " . DB_PREFIX . "bundles SET ";
        foreach ($fields as $key => $value) {
            $sql .= "`$key` = '" . (is_null($value) ? 'NULL' : $this->db->escape($value)) . "', ";
        }
        $sql = rtrim($sql, ', ');
        $sql .= " WHERE bundle_id = '" . (int)$bundle_id . "'";

        $this->db->query($sql);
    }

    public function deleteBundle($bundle_id) {
        $this->db->query("DELETE FROM " . DB_PREFIX . "bundles WHERE bundle_id = '" . (int)$bundle_id . "'");
    }

    public function getBundlesByProduct($product_id) {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE status = 1 AND products LIKE '%\"" . (int)$product_id . "\"%' ORDER BY sort_order ASC");
        
        $bundles = array();
        foreach ($query->rows as $row) {
            $row['products'] = json_decode($row['products'], true) ?: array();
            $row['categories'] = json_decode($row['categories'], true) ?: array();
            $bundles[] = $row;
        }
        
        return $bundles;
    }

    public function getBundlesByCategory($category_id) {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE status = 1 AND (categories LIKE '%\"" . (int)$category_id . "\"%' OR categories = '[]' OR categories = '' OR categories IS NULL) ORDER BY sort_order ASC");
        
        $bundles = array();
        foreach ($query->rows as $row) {
            $row['products'] = json_decode($row['products'], true) ?: array();
            $bundles[] = $row;
        }
        
        return $bundles;
    }

    public function getSetting($key, $default = null) {
        $query = $this->db->query("SELECT value FROM " . DB_PREFIX . "bundle_settings WHERE `key` = '" . $this->db->escape($key) . "'");
        
        if ($query->num_rows) {
            return $query->row['value'];
        }
        
        return $default;
    }

    public function setSetting($key, $value) {
        $this->db->query("DELETE FROM " . DB_PREFIX . "bundle_settings WHERE `key` = '" . $this->db->escape($key) . "'");
        $this->db->query("INSERT INTO " . DB_PREFIX . "bundle_settings (`key`, value) VALUES ('" . $this->db->escape($key) . "', '" . $this->db->escape($value) . "')");
    }

    private function slugify($text) {
        $text = preg_replace('~[^\pL\d]+~u', '-', $text);
        $text = iconv('utf-8', 'us-ascii//TRANSLIT', $text);
        $text = preg_replace('~[^-\w]+~', '', $text);
        $text = trim($text, '-');
        $text = preg_replace('~-+~', '-', $text);
        $text = strtolower($text);

        if (empty($text)) {
            return 'bundle-' . time();
        }

        return $text;
    }

    public function syncToStrapi() {
        $strapi_url = $this->getSetting('api_url', 'http://localhost:1337');
        
        $bundles = $this->getBundles();
        
        $payload = array(
            'bundles' => array_map(function($bundle) {
                return array(
                    'name' => $bundle['name'],
                    'slug' => $bundle['slug'],
                    'description' => $bundle['description'],
                    'shortDescription' => $bundle['short_description'],
                    'image' => $bundle['image'],
                    'images' => json_decode($bundle['images'], true),
                    'originalPrice' => (float)$bundle['original_price'],
                    'bundlePrice' => (float)$bundle['bundle_price'],
                    'discountPercent' => (float)$bundle['discount_percent'],
                    'isActive' => (bool)$bundle['status'],
                    'stock' => (int)$bundle['stock'],
                    'sku' => $bundle['sku'],
                    'products' => json_decode($bundle['products'], true),
                    'categories' => json_decode($bundle['categories'], true),
                    'metaTitle' => $bundle['meta_title'],
                    'metaDescription' => $bundle['meta_description'],
                    'sortOrder' => (int)$bundle['sort_order'],
                    'validFrom' => $bundle['valid_from'],
                    'validTo' => $bundle['valid_to']
                );
            }, $bundles)
        );

        $context = stream_context_create(array(
            'http' => array(
                'method' => 'POST',
                'header' => "Content-Type: application/json\r\n",
                'content' => json_encode($payload),
                'timeout' => 30
            )
        ));

        $response = @file_get_contents($strapi_url . '/api/bundles/sync', false, $context);
        
        return $response !== false;
    }
}