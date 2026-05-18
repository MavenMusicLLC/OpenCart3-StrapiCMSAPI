<?php
class ControllerCheckoutCartBundle extends Controller {
    public function addBundle() {
        $json = array();
        
        $this->load->language('checkout/cart');
        $this->load->model('module/bundle');
        
        $bundle_id = isset($this->request->post['bundle_id']) ? (int)$this->request->post['bundle_id'] : 0;
        
        if (!$bundle_id) {
            $json['error'] = $this->language->get('error_bundle_not_found');
            $this->response->addHeader('Content-Type: application/json');
            $this->response->setOutput(json_encode($json));
            return;
        }
        
        $bundle = $this->model_module_bundle->getBundleById($bundle_id);
        
        if (!$bundle) {
            $json['error'] = $this->language->get('error_bundle_not_found');
            $this->response->addHeader('Content-Type: application/json');
            $this->response->setOutput(json_encode($json));
            return;
        }
        
        if (!empty($bundle['products'])) {
            foreach ($bundle['products'] as $product) {
                $product_id = $product['productId'];
                $quantity = isset($product['quantity']) ? (int)$product['quantity'] : 1;
                $options = isset($product['options']) ? $product['options'] : array();
                
                $this->cart->add($product_id, $quantity, $options);
            }
        }
        
        $this->load->model('tool/image');
        $this->load->model('catalog/product');
        
        $json['success'] = sprintf($this->language->get('text_bundle_added'), $bundle['name']);
        $json['total'] = sprintf($this->language->get('text_items'), $this->cart->countProducts() . ' ' . ($this->cart->countProducts() > 1 ? 'items' : 'item'));
        
        unset($this->session->data['shipping_method']);
        unset($this->session->data['shipping_methods']);
        unset($this->session->data['payment_method']);
        unset($this->session->data['payment_methods']);
        unset($this->session->data['reward']);
        
        $this->response->addHeader('Content-Type: application/json');
        $this->response->setOutput(json_encode($json));
    }
    
    public function validateBundle() {
        $json = array();
        
        $this->load->language('checkout/cart');
        $this->load->model('module/bundle');
        
        $bundle_id = isset($this->request->post['bundle_id']) ? (int)$this->request->post['bundle_id'] : 0;
        
        $bundle = $this->model_module_bundle->getBundleById($bundle_id);
        
        if ($bundle && !empty($bundle['products'])) {
            $all_in_cart = true;
            $missing_products = array();
            
            foreach ($bundle['products'] as $product) {
                $cart_product = $this->cart->getProducts();
                $found = false;
                
                foreach ($cart_product as $cart_item) {
                    if ($cart_item['product_id'] == $product['productId']) {
                        $found = true;
                        break;
                    }
                }
                
                if (!$found) {
                    $all_in_cart = false;
                    $missing_products[] = $product['name'];
                }
            }
            
            if (!$all_in_cart) {
                $json['warning'] = sprintf($this->language->get('text_missing_products'), implode(', ', $missing_products));
            }
        }
        
        $this->response->addHeader('Content-Type: application/json');
        $this->response->setOutput(json_encode($json));
    }
}