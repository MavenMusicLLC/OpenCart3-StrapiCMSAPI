<?php
class ModelModuleBundleManager extends Model {
    public function install() {
        // Tables will be created via migration script
        // This is called when the module is installed via OpenCart admin
        
        // Add permissions for the module
        $this->load->model('user/user_group');
        $this->model_user_user_group->addPermission($this->user->getGroupId(), 'access', 'module/bundle_manager');
        $this->model_user_user_group->addPermission($this->user->getGroupId(), 'modify', 'module/bundle_manager');
        
        // Insert default settings
        $this->db->query("INSERT INTO " . DB_PREFIX . "bundle_settings (`key`, `value`) VALUES 
            ('api_url', 'http://localhost:1337/api'),
            ('api_enabled', '1'),
            ('cache_ttl', '3600'),
            ('show_on_product_page', '1'),
            ('default_title', 'Product Bundles')
        ON DUPLICATE KEY UPDATE `id`=`id`");
    }
    
    public function uninstall() {
        // Don't drop tables on uninstall to preserve data
        // Use uninstall.sql manually if needed
    }
    
    public function getBundles($data = array()) {
        $sql = "SELECT * FROM " . DB_PREFIX . "bundles WHERE 1=1";
        
        if (!empty($data['filter_name'])) {
            $sql .= " AND name LIKE '%" . $this->db->escape($data['filter_name']) . "%'";
        }
        
        if (isset($data['filter_status']) && !is_null($data['filter_status'])) {
            $sql .= " AND status = '" . (int)$data['filter_status'] . "'";
        }
        
        $sort_data = array(
            'name',
            'sort_order',
            'status',
            'date_added'
        );

        if (isset($data['sort']) && in_array($data['sort'], $sort_data)) {
            $sql .= " ORDER BY " . $data['sort'];
        } else {
            $sql .= " ORDER BY sort_order";
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
    
    public function getTotalBundles($data = array()) {
        $sql = "SELECT COUNT(*) AS total FROM " . DB_PREFIX . "bundles WHERE 1=1";
        
        if (!empty($data['filter_name'])) {
            $sql .= " AND name LIKE '%" . $this->db->escape($data['filter_name']) . "%'";
        }
        
        if (isset($data['filter_status']) && !is_null($data['filter_status'])) {
            $sql .= " AND status = '" . (int)$data['filter_status'] . "'";
        }
        
        $query = $this->db->query($sql);
        return $query->row['total'];
    }
    
    public function getBundle($bundle_id) {
        $query = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundles WHERE bundle_id = '" . (int)$bundle_id . "'");

        if ($query->num_rows) {
            $bundle = $query->row;
            $bundle['products'] = json_decode($bundle['products'], true) ?: array();
            $bundle['categories'] = json_decode($bundle['categories'], true) ?: array();
            $bundle['images'] = json_decode($bundle['images'], true) ?: array();
            return $bundle;
        }
        
        return null;
    }
    
    public function addBundle($data) {
        $slug = $this->slugify($data['name']);
        
        $this->db->query("INSERT INTO " . DB_PREFIX . "bundles SET 
            name = '" . $this->db->escape($data['name']) . "',
            slug = '" . $this->db->escape($slug) . "',
            description = '" . $this->db->escape($data['description']) . "',
            short_description = '" . $this->db->escape($data['short_description']) . "',
            image = '" . $this->db->escape($data['image']) . "',
            images = '" . $this->db->escape(json_encode($data['images'] ?? array())) . "',
            original_price = '" . (float)$data['original_price'] . "',
            bundle_price = '" . (float)$data['bundle_price'] . "',
            discount_percent = '" . (float)($data['discount_percent'] ?? 0) . "',
            products = '" . $this->db->escape(json_encode($data['products'])) . "',
            categories = '" . $this->db->escape(json_encode($data['categories'] ?? array())) . "',
            stock = '" . (int)($data['stock'] ?? 0) . "',
            sku = '" . $this->db->escape($data['sku'] ?? '') . "',
            meta_title = '" . $this->db->escape($data['meta_title'] ?? '') . "',
            meta_description = '" . $this->db->escape($data['meta_description'] ?? '') . "',
            status = '" . (int)($data['status'] ?? 1) . "',
            sort_order = '" . (int)($data['sort_order'] ?? 0) . "',
            valid_from = " . (!empty($data['valid_from']) ? "'" . $data['valid_from'] . "'" : "NULL") . ",
            valid_to = " . (!empty($data['valid_to']) ? "'" . $data['valid_to'] . "'" : "NULL") . ",
            date_added = NOW(),
            date_modified = NOW()"
        );
        
        return $this->db->getLastId();
    }
    
    public function editBundle($bundle_id, $data) {
        $this->db->query("UPDATE " . DB_PREFIX . "bundles SET 
            name = '" . $this->db->escape($data['name']) . "',
            description = '" . $this->db->escape($data['description']) . "',
            short_description = '" . $this->db->escape($data['short_description']) . "',
            image = '" . $this->db->escape($data['image']) . "',
            images = '" . $this->db->escape(json_encode($data['images'] ?? array())) . "',
            original_price = '" . (float)$data['original_price'] . "',
            bundle_price = '" . (float)$data['bundle_price'] . "',
            discount_percent = '" . (float)($data['discount_percent'] ?? 0) . "',
            products = '" . $this->db->escape(json_encode($data['products'])) . "',
            categories = '" . $this->db->escape(json_encode($data['categories'] ?? array())) . "',
            stock = '" . (int)($data['stock'] ?? 0) . "',
            sku = '" . $this->db->escape($data['sku'] ?? '') . "',
            meta_title = '" . $this->db->escape($data['meta_title'] ?? '') . "',
            meta_description = '" . $this->db->escape($data['meta_description'] ?? '') . "',
            status = '" . (int)($data['status'] ?? 1) . "',
            sort_order = '" . (int)($data['sort_order'] ?? 0) . "',
            valid_from = " . (!empty($data['valid_from']) ? "'" . $data['valid_from'] . "'" : "NULL") . ",
            valid_to = " . (!empty($data['valid_to']) ? "'" . $data['valid_to'] . "'" : "NULL") . ",
            date_modified = NOW()
            WHERE bundle_id = '" . (int)$bundle_id . "'"
        );
    }
    
    public function deleteBundle($bundle_id) {
        $this->db->query("DELETE FROM " . DB_PREFIX . "bundles WHERE bundle_id = '" . (int)$bundle_id . "'");
    }
    
    public function getProducts() {
        $sql = "SELECT p.product_id, pd.name, p.price, p.image, p.status 
                FROM " . DB_PREFIX . "product p 
                LEFT JOIN " . DB_PREFIX . "product_description pd ON p.product_id = pd.product_id 
                WHERE pd.language_id = '" . (int)$this->config->get('config_language_id') . "'
                ORDER BY pd.name";
        
        $query = $this->db->query($sql);
        return $query->rows;
    }
    
    public function getCategories() {
        $sql = "SELECT c.category_id, cd.name 
                FROM " . DB_PREFIX . "category c 
                LEFT JOIN " . DB_PREFIX . "category_description cd ON c.category_id = cd.category_id 
                WHERE cd.language_id = '" . (int)$this->config->get('config_language_id') . "'
                ORDER BY cd.name";
        
        $query = $this->db->query($sql);
        return $query->rows;
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
}