<div class="bundle-product-section" id="bundle-product-section">
  <h2 class="bundle-product-heading">
    <i class="fa fa-cubes"></i> <?php echo $heading_title; ?>
  </h2>
  
  <?php foreach ($bundles as $bundle) { ?>
  <div class="bundle-product-card">
    <div class="bundle-product-header">
      <?php if ($bundle['discount']) { ?>
      <span class="bundle-discount-badge">-<?php echo $bundle['discount']; ?>% OFF</span>
      <?php } ?>
      <h3 class="bundle-product-name"><?php echo $bundle['name']; ?></h3>
      <p class="bundle-product-description"><?php echo $bundle['description']; ?></p>
    </div>
    
    <div class="bundle-product-content">
      <div class="bundle-products-list">
        <h4><?php echo $text_includes; ?></h4>
        <table class="table bundle-products-table">
          <?php $total_separate = 0; ?>
          <?php foreach ($bundle['products'] as $product) { ?>
          <?php $total_separate += $product['price_value'] * $product['quantity']; ?>
          <tr class="<?php echo $product['is_current'] ? 'current-product' : ''; ?>">
            <td class="product-image">
              <?php if ($product['image']) { ?>
              <img src="<?php echo $product['image']; ?>" alt="<?php echo $product['name']; ?>" />
              <?php } else { ?>
              <div class="no-image"><i class="fa fa-cube"></i></div>
              <?php } ?>
            </td>
            <td class="product-details">
              <span class="product-name"><?php echo $product['name']; ?></span>
              <span class="product-quantity">x<?php echo $product['quantity']; ?></span>
              <?php if ($product['is_current']) { ?>
              <span class="current-badge"><?php echo $text_current_product; ?></span>
              <?php } ?>
            </td>
            <td class="product-price">
              <span class="product-price-value"><?php echo $product['price']; ?></span>
            </td>
          </tr>
          <?php } ?>
        </table>
      </div>
      
      <div class="bundle-pricing-panel">
        <div class="prices">
          <span class="original-price-label"><?php echo $text_separate_price; ?></span>
          <span class="original-price-value"><strike><?php echo $bundle['original_price']; ?></strike></span>
          
          <span class="bundle-price-label"><?php echo $text_bundle_price; ?></span>
          <span class="bundle-price-value"><?php echo $bundle['bundle_price']; ?></span>
          
          <span class="savings">
            <?php echo $text_you_save; ?> 
            <strong class="savings-amount"><?php echo round($bundle['original_price_value'] - $bundle['bundle_price_value']); ?> <?php echo $this->session->data['currency']; ?></strong>
          </span>
        </div>
        
        <div class="bundle-actions">
          <button type="button" class="btn btn-primary btn-lg bundle-add-btn" onclick="addProductBundleToCart(<?php echo $bundle['id']; ?>)">
            <i class="fa fa-shopping-cart"></i> <?php echo $button_add_bundle; ?>
          </button>
        </div>
      </div>
    </div>
  </div>
  <?php } ?>
</div>

<style>
.bundle-product-section {
  margin: 30px 0;
  padding: 20px;
  background: #f9f9f9;
  border-radius: 8px;
  border: 1px solid #e0e0e0;
}

.bundle-product-heading {
  font-size: 20px;
  margin-bottom: 20px;
  color: #333;
}

.bundle-product-card {
  background: #fff;
  border-radius: 8px;
  margin-bottom: 20px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.bundle-product-header {
  padding: 15px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  position: relative;
}

.bundle-discount-badge {
  position: absolute;
  top: 15px;
  right: 20px;
  background: #ff4444;
  color: #fff;
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: bold;
}

.bundle-product-name {
  margin: 0 0 5px 0;
  font-size: 18px;
}

.bundle-product-description {
  margin: 0;
  opacity: 0.9;
  font-size: 14px;
}

.bundle-product-content {
  display: flex;
  flex-wrap: wrap;
  padding: 20px;
}

.bundle-products-list {
  flex: 1;
  min-width: 300px;
}

.bundle-products-list h4 {
  margin: 0 0 15px 0;
  color: #333;
}

.bundle-products-table {
  margin: 0;
}

.bundle-products-table td {
  vertical-align: middle;
  border: none;
  border-bottom: 1px solid #eee;
  padding: 10px 5px;
}

.bundle-products-table tr:last-child td {
  border-bottom: none;
}

.bundle-products-table tr.current-product {
  background: #e8f5e9;
}

.product-image img {
  width: 60px;
  height: 60px;
  object-fit: cover;
  border-radius: 4px;
}

.no-image {
  width: 60px;
  height: 60px;
  background: #f0f0f0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  color: #999;
}

.product-details {
  padding-left: 10px;
}

.product-name {
  display: block;
  font-weight: 500;
  color: #333;
}

.product-quantity {
  color: #666;
  font-size: 13px;
}

.current-badge {
  display: inline-block;
  background: #4caf50;
  color: #fff;
  padding: 2px 8px;
  border-radius: 3px;
  font-size: 11px;
  margin-left: 5px;
}

.product-price {
  text-align: right;
  white-space: nowrap;
}

.product-price-value {
  font-weight: 600;
  color: #333;
}

.bundle-pricing-panel {
  width: 280px;
  padding: 20px;
  background: #f5f5f5;
  border-radius: 8px;
  text-align: center;
}

.prices {
  margin-bottom: 15px;
}

.original-price-label,
.bundle-price-label {
  display: block;
  font-size: 12px;
  color: #666;
  margin-top: 10px;
}

.original-price-value {
  color: #999;
  font-size: 14px;
}

.bundle-price-value {
  display: block;
  font-size: 28px;
  font-weight: bold;
  color: #667eea;
}

.savings {
  display: block;
  margin-top: 10px;
  color: #4caf50;
  font-size: 14px;
}

.savings-amount {
  font-weight: bold;
}

.bundle-add-btn {
  width: 100%;
  padding: 12px 24px;
  font-size: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 6px;
  transition: all 0.3s ease;
}

.bundle-add-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

@media (max-width: 768px) {
  .bundle-product-content {
    flex-direction: column;
  }
  
  .bundle-pricing-panel {
    width: 100%;
    margin-top: 20px;
  }
}
</style>

<script>
function addProductBundleToCart(bundleId) {
    $.ajax({
        url: 'index.php?route=checkout/cart/addBundle',
        type: 'post',
        data: {bundle_id: bundleId},
        dataType: 'json',
        beforeSend: function() {
            $('#bundle-product-section .bundle-add-btn').button('loading');
        },
        complete: function() {
            $('#bundle-product-section .bundle-add-btn').button('reset');
        },
        success: function(json) {
            if (json['redirect']) {
                location = json['redirect'];
            }
            if (json['success']) {
                $('#cart > button').html('<span id="cart-total"><i class="fa fa-shopping-cart"></i> ' + json['total'] + '</span>');
                $('#cart > ul').load('index.php?route=common/cart/info ul li');
                
                toastr.success(json['success']);
            }
            if (json['error']) {
                toastr.error(json['error']);
            }
        },
        error: function(xhr, ajaxOptions, thrownError) {
            alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
        }
    });
}
</script>