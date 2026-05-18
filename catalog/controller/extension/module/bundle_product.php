<?php
class ControllerExtensionModuleBundleProduct extends Controller {
    private $api_url = 'http://localhost:1337/api';
    
    public function index($setting) {
        if (!$setting['status'] || !isset($this->request->get['product_id'])) {
            return '';
        }
        
        $this->load->language('extension/module/bundle_product');
        $this->load->model('module/bundle');
        $this->load->model('tool/image');
        
        $product_id = (int)$this->request->get['product_id'];
        
        $bundles = $this->model_module_bundle->getBundlesByProduct($product_id);
        
        if (empty($bundles)) {
            return '';
        }
        
        $data['bundles'] = array();
        
        foreach ($bundles as $bundle) {
            if (is_array($bundle)) {
                $bundle_id = $bundle['id'] ?? $bundle['bundle_id'] ?? 0;
                $bundle_name = $bundle['name'] ?? '';
                $bundle_slug = $bundle['slug'] ?? '';
                $bundle_desc = $bundle['description'] ?? '';
                $original_price = is_numeric($bundle['original_price'] ?? null) ? (float)$bundle['original_price'] : (float)($bundle['originalPrice'] ?? 0);
                $bundle_price = is_numeric($bundle['bundle_price'] ?? null) ? (float)$bundle['bundle_price'] : (float)($bundle['bundlePrice'] ?? 0);
                $image = $bundle['image'] ?? '';
                $products_data = $bundle['products'] ?? array();
            } else {
                continue;
            }
            
            $products = array();
            if (!empty($products_data)) {
                $product_ids = array_column($products_data, 'productId');
                $product_info = $this->model_module_bundle->getProducts($product_ids);
                
                foreach ($products_data as $bp) {
                    $pid = $bp['productId'] ?? 0;
                    $qty = $bp['quantity'] ?? 1;
                    
                    if (isset($product_info[$pid])) {
                        $p = $product_info[$pid];
                        $products[] = array(
                            'product_id' => $pid,
                            'name' => $p['name'] ?? ($bp['name'] ?? 'Product'),
                            'price' => $this->currency->format($p['price'] ?? 0, $this->session->data['currency']),
                            'price_value' => $p['price'] ?? 0,
                            'image' => !empty($p['image']) ? $this->model_tool_image->resize($p['image'], 80, 80) : '',
                            'quantity' => $qty,
                            'is_current' => ($pid == $product_id)
                        );
                    } else {
                        $products[] = array(
                            'product_id' => $pid,
                            'name' => $bp['name'] ?? 'Product',
                            'price' => $this->currency->format($bp['price'] ?? 0, $this->session->data['currency']),
                            'price_value' => $bp['price'] ?? 0,
                            'image' => '',
                            'quantity' => $qty,
                            'is_current' => ($pid == $product_id)
                        );
                    }
                }
            }
            
            $discount = 0;
            if ($original_price > 0 && $bundle_price > 0) {
                $discount = round((1 - $bundle_price / $original_price) * 100);
            }
            
            $data['bundles'][] = array(
                'id' => $bundle_id,
                'name' => $bundle_name,
                'slug' => $bundle_slug,
                'description' => utf8_substr(strip_tags(html_entity_decode($bundle_desc, ENT_QUOTES, 'UTF-8')), 0, 150),
                'original_price' => $this->currency->format($original_price, $this->session->data['currency']),
                'original_price_value' => $original_price,
                'bundle_price' => $this->currency->format($bundle_price, $this->session->data['currency']),
                'bundle_price_value' => $bundle_price,
                'discount' => $discount,
                'image' => $image ? $this->model_tool_image->resize($image, 400, 300) : '',
                'products' => $products,
                'href' => $this->url->link('product/bundle', 'bundle_id=' . $bundle_id)
            );
        }
        
        $data['heading_title'] = $setting['title'] ?: $this->language->get('heading_title');
        $data['show_on_product_page'] = isset($setting['show_on_product_page']) ? $setting['show_on_product_page'] : 1;
        $data['position'] = isset($setting['position']) ? $setting['position'] : 'content_bottom';
        
        return $this->load->view('extension/module/bundle_product', $data);
    }
}