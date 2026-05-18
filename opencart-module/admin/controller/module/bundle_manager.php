<?php
class ControllerModuleBundleManager extends Controller {
    private $error = array();

    public function index() {
        $this->load->language('module/bundle_manager');
        $this->load->model('module/bundle_manager');
        $this->load->model('setting/setting');
        $this->document->setTitle($this->language->get('heading_title'));
        
        if (($this->request->server['REQUEST_METHOD'] == 'POST') && $this->validate()) {
            $this->model_setting_setting->editSetting('bundle_manager', $this->request->post);
            $this->session->data['success'] = $this->language->get('text_success');
            $this->response->redirect($this->url->link('module/bundle_manager', 'token=' . $this->session->data['token'], true));
        }
        
        $data['heading_title'] = $this->language->get('heading_title');
        $data['text_enabled'] = $this->language->get('text_enabled');
        $data['text_disabled'] = $this->language->get('text_disabled');
        $data['entry_status'] = $this->language->get('entry_status');
        $data['entry_api_url'] = $this->language->get('entry_api_url');
        $data['entry_api_enabled'] = $this->language->get('entry_api_enabled');
        $data['entry_cache_ttl'] = $this->language->get('entry_cache_ttl');
        $data['button_save'] = $this->language->get('button_save');
        $data['button_cancel'] = $this->language->get('button_cancel');
        $data['button_bundles'] = $this->language->get('button_bundles');
        $data['button_sync'] = $this->language->get('button_sync');
        $data['tab_general'] = $this->language->get('tab_general');
        $data['tab_bundles'] = $this->language->get('tab_bundles');
        $data['tab_api'] = $this->language->get('tab_api');
        
        if (isset($this->error['warning'])) {
            $data['error_warning'] = $this->error['warning'];
        } else {
            $data['error_warning'] = '';
        }
        
        if (isset($this->session->data['success'])) {
            $data['success'] = $this->session->data['success'];
            unset($this->session->data['success']);
        } else {
            $data['success'] = '';
        }
        
        $data['breadcrumbs'] = array();
        $data['breadcrumbs'][] = array(
            'text' => $this->language->get('text_home'),
            'href' => $this->url->link('common/dashboard', 'token=' . $this->session->data['token'], true)
        );
        $data['breadcrumbs'][] = array(
            'text' => $this->language->get('text_module'),
            'href' => $this->url->link('extension/module', 'token=' . $this->session->data['token'], true)
        );
        $data['breadcrumbs'][] = array(
            'text' => $this->language->get('heading_title'),
            'href' => $this->url->link('module/bundle_manager', 'token=' . $this->session->data['token'], true)
        );
        
        $data['action'] = $this->url->link('module/bundle_manager', 'token=' . $this->session->data['token'], true);
        $data['cancel'] = $this->url->link('extension/module', 'token=' . $this->session->data['token'], true);
        $data['bundles_link'] = $this->url->link('module/bundle_manager/bundles', 'token=' . $this->session->data['token'], true);
        $data['strapi_url'] = 'http://localhost:1337/admin';
        
        // Get settings
        $settings = $this->db->query("SELECT * FROM " . DB_PREFIX . "bundle_settings");
        $data['settings'] = array();
        foreach ($settings->rows as $row) {
            $data['settings'][$row['key']] = $row['value'];
        }
        
        $data['bundle_manager_status'] = $this->config->get('bundle_manager_status');
        
        $data['header'] = $this->load->controller('common/header');
        $data['column_left'] = $this->load->controller('common/column_left');
        $data['footer'] = $this->load->controller('common/footer');
        
        $this->response->setOutput($this->load->view('module/bundle_manager', $data));
    }
    
    public function bundles() {
        $this->load->language('module/bundle_manager');
        $this->load->model('module/bundle_manager');
        
        $this->document->setTitle($this->language->get('heading_title') . ' - ' . $this->language->get('text_bundles'));
        
        if (isset($this->request->get['page'])) {
            $page = $this->request->get['page'];
        } else {
            $page = 1;
        }
        
        $limit = 20;
        
        $data['bundles'] = array();
        $results = $this->model_module_bundle_manager->getBundles(array(
            'start' => ($page - 1) * $limit,
            'limit' => $limit
        ));
        
        foreach ($results as $result) {
            $data['bundles'][] = array(
                'bundle_id' => $result['bundle_id'],
                'name' => $result['name'],
                'slug' => $result['slug'],
                'original_price' => $result['original_price'],
                'bundle_price' => $result['bundle_price'],
                'status' => $result['status'] ? $this->language->get('text_enabled') : $this->language->get('text_disabled'),
                'date_added' => $result['date_added'],
                'edit' => $this->url->link('module/bundle_manager/edit', 'token=' . $this->session->data['token'] . '&bundle_id=' . $result['bundle_id'], true)
            );
        }
        
        $bundle_total = $this->model_module_bundle_manager->getTotalBundles();
        
        $pagination = new Pagination();
        $pagination->total = $bundle_total;
        $pagination->page = $page;
        $pagination->limit = $limit;
        $pagination->url = $this->url->link('module/bundle_manager/bundles', 'token=' . $this->session->data['token'] . '&page={page}', true);
        
        $data['pagination'] = $pagination->render();
        $data['results'] = sprintf($this->language->get('text_pagination'), ($bundle_total) ? (($page - 1) * $limit) + 1 : 0, ((($page - 1) * $limit) > ($bundle_total - $limit)) ? $bundle_total : ((($page - 1) * $limit) + $limit), $bundle_total, ceil($bundle_total / $limit));
        
        $data['heading_title'] = $this->language->get('heading_title');
        $data['text_list'] = $this->language->get('text_list');
        $data['text_no_results'] = $this->language->get('text_no_results');
        $data['text_confirm'] = $this->language->get('text_confirm');
        $data['column_name'] = $this->language->get('column_name');
        $data['column_price'] = $this->language->get('column_price');
        $data['column_status'] = $this->language->get('column_status');
        $data['column_date_added'] = $this->language->get('column_date_added');
        $data['column_action'] = $this->language->get('column_action');
        $data['button_add'] = $this->language->get('button_add');
        $data['button_delete'] = $this->language->get('button_delete');
        $data['button_edit'] = $this->language->get('button_edit');
        $data['button_filter'] = $this->language->get('button_filter');
        
        $data['add'] = $this->url->link('module/bundle_manager/add', 'token=' . $this->session->data['token'], true);
        $data['delete'] = $this->url->link('module/bundle_manager/delete', 'token=' . $this->session->data['token'], true);
        $data['back'] = $this->url->link('module/bundle_manager', 'token=' . $this->session->data['token'], true);
        
        if (isset($this->session->data['success'])) {
            $data['success'] = $this->session->data['success'];
            unset($this->session->data['success']);
        } else {
            $data['success'] = '';
        }
        
        $data['header'] = $this->load->controller('common/header');
        $data['column_left'] = $this->load->controller('common/column_left');
        $data['footer'] = $this->load->controller('common/footer');
        
        $this->response->setOutput($this->load->view('module/bundle_manager_list', $data));
    }
    
    public function add() {
        $this->load->language('module/bundle_manager');
        $this->load->model('module/bundle_manager');
        
        $this->document->setTitle($this->language->get('heading_title') . ' - ' . $this->language->get('text_add'));
        
        if (($this->request->server['REQUEST_METHOD'] == 'POST') && $this->validateForm()) {
            $this->model_module_bundle_manager->addBundle($this->request->post);
            $this->session->data['success'] = $this->language->get('text_success');
            $this->response->redirect($this->url->link('module/bundle_manager/bundles', 'token=' . $this->session->data['token'], true));
        }
        
        $this->getForm();
    }
    
    public function edit() {
        $this->load->language('module/bundle_manager');
        $this->load->model('module/bundle_manager');
        
        $this->document->setTitle($this->language->get('heading_title') . ' - ' . $this->language->get('text_edit'));
        
        if (($this->request->server['REQUEST_METHOD'] == 'POST') && $this->validateForm()) {
            $bundle_id = $this->request->get['bundle_id'];
            $this->model_module_bundle_manager->editBundle($bundle_id, $this->request->post);
            $this->session->data['success'] = $this->language->get('text_success');
            $this->response->redirect($this->url->link('module/bundle_manager/bundles', 'token=' . $this->session->data['token'], true));
        }
        
        $this->getForm();
    }
    
    public function delete() {
        $this->load->language('module/bundle_manager');
        $this->load->model('module/bundle_manager');
        
        if (isset($this->request->post['selected'])) {
            foreach ($this->request->post['selected'] as $bundle_id) {
                $this->model_module_bundle_manager->deleteBundle($bundle_id);
            }
            $this->session->data['success'] = $this->language->get('text_success_delete');
        }
        
        $this->response->redirect($this->url->link('module/bundle_manager/bundles', 'token=' . $this->session->data['token'], true));
    }
    
    protected function getForm() {
        $data['heading_title'] = $this->language->get('heading_title');
        $data['text_form'] = !isset($this->request->get['bundle_id']) ? $this->language->get('text_add') : $this->language->get('text_edit');
        $data['text_enabled'] = $this->language->get('text_enabled');
        $data['text_disabled'] = $this->language->get('text_disabled');
        $data['entry_name'] = $this->language->get('entry_name');
        $data['entry_description'] = $this->language->get('entry_description');
        $data['entry_short_description'] = $this->language->get('entry_short_description');
        $data['entry_image'] = $this->language->get('entry_image');
        $data['entry_original_price'] = $this->language->get('entry_original_price');
        $data['entry_bundle_price'] = $this->language->get('entry_bundle_price');
        $data['entry_discount_percent'] = $this->language->get('entry_discount_percent');
        $data['entry_products'] = $this->language->get('entry_products');
        $data['entry_categories'] = $this->language->get('entry_categories');
        $data['entry_stock'] = $this->language->get('entry_stock');
        $data['entry_sku'] = $this->language->get('entry_sku');
        $data['entry_status'] = $this->language->get('entry_status');
        $data['entry_sort_order'] = $this->language->get('entry_sort_order');
        $data['button_save'] = $this->language->get('button_save');
        $data['button_cancel'] = $this->language->get('button_cancel');
        
        if (isset($this->error['warning'])) {
            $data['error_warning'] = $this->error['warning'];
        } else {
            $data['error_warning'] = '';
        }
        
        if (isset($this->error['name'])) {
            $data['error_name'] = $this->error['name'];
        } else {
            $data['error_name'] = '';
        }
        
        if (isset($this->request->get['bundle_id'])) {
            $bundle_id = $this->request->get['bundle_id'];
            $data['action'] = $this->url->link('module/bundle_manager/edit', 'token=' . $this->session->data['token'] . '&bundle_id=' . $bundle_id, true);
            $bundle_info = $this->model_module_bundle_manager->getBundle($bundle_id);
            $data['bundle'] = $bundle_info;
        } else {
            $data['action'] = $this->url->link('module/bundle_manager/add', 'token=' . $this->session->data['token'], true);
            $data['bundle'] = array();
        }
        
        $data['cancel'] = $this->url->link('module/bundle_manager/bundles', 'token=' . $this->session->data['token'], true);
        $data['products'] = $this->model_module_bundle_manager->getProducts();
        $data['categories'] = $this->model_module_bundle_manager->getCategories();
        
        $data['header'] = $this->load->controller('common/header');
        $data['column_left'] = $this->load->controller('common/column_left');
        $data['footer'] = $this->load->controller('common/footer');
        
        $this->response->setOutput($this->load->view('module/bundle_manager_form', $data));
    }
    
    protected function validate() {
        if (!$this->user->hasPermission('modify', 'module/bundle_manager')) {
            $this->error['warning'] = $this->language->get('error_permission');
        }
        
        return !$this->error;
    }
    
    protected function validateForm() {
        if (!$this->user->hasPermission('modify', 'module/bundle_manager')) {
            $this->error['warning'] = $this->language->get('error_permission');
        }
        
        if (empty($this->request->post['name'])) {
            $this->error['name'] = $this->language->get('error_name');
        }
        
        return !$this->error;
    }
    
    public function install() {
        $this->load->model('module/bundle_manager');
        $this->model_module_bundle_manager->install();
        
        $this->load->model('setting/setting');
        $this->model_setting_setting->editSetting('bundle_manager', array('bundle_manager_status' => 1));
    }
    
    public function uninstall() {
        $this->load->model('module/bundle_manager');
        $this->model_module_bundle_manager->uninstall();
        
        $this->load->model('setting/setting');
        $this->model_setting_setting->deleteSetting('bundle_manager');
    }
}