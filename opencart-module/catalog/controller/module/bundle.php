<?php
class ControllerModuleBundle extends Controller {
    private $error = array();

    public function index($setting) {
        $this->load->language('module/bundle');
        $this->load->model('module/bundle');
        $this->load->model('tool/image');

        $data['heading_title'] = isset($setting['title']) ? $setting['title'] : $this->language->get('heading_title');
        $data['bundles'] = array();

        $bundles = $this->model_module_bundle->getBundles($setting['limit'], $setting['category_id']);

        foreach ($bundles as $bundle) {
            $products = array();
            if (!empty($bundle['products'])) {
                $product_ids = array_column($bundle['products'], 'productId');
                $product_data = $this->model_module_bundle->getProducts($product_ids);
                
                foreach ($bundle['products'] as $bp) {
                    if (isset($product_data[$bp['productId']])) {
                        $p = $product_data[$bp['productId']];
                        $products[] = array(
                            'product_id' => $p['product_id'],
                            'name' => $p['name'],
                            'price' => $this->currency->format($p['price'], $this->session->data['currency']),
                            'image' => $p['image'] ? $this->model_tool_image->resize($p['image'], 80, 80) : '',
                            'quantity' => $bp['quantity'],
                            'model' => $p['model']
                        );
                    }
                }
            }

            $discount = 0;
            if ($bundle['original_price'] > 0) {
                $discount = round((1 - $bundle['bundle_price'] / $bundle['original_price']) * 100);
            }

            $data['bundles'][] = array(
                'id' => $bundle['id'],
                'name' => $bundle['name'],
                'slug' => $bundle['slug'],
                'description' => utf8_substr(strip_tags(html_entity_decode($bundle['description'], ENT_QUOTES, 'UTF-8')), 0, 100) . '...',
                'original_price' => $this->currency->format($bundle['original_price'], $this->session->data['currency']),
                'bundle_price' => $this->currency->format($bundle['bundle_price'], $this->session->data['currency']),
                'discount' => $discount,
                'image' => $bundle['image'] ? $this->model_tool_image->resize($bundle['image'], 400, 300) : '',
                'products' => $products,
                'href' => $this->url->link('product/bundle', 'bundle_id=' . $bundle['id'])
            );
        }

        $data['position'] = isset($setting['position']) ? $setting['position'] : 'content_bottom';

        return $this->load->view('module/bundle', $data);
    }
}