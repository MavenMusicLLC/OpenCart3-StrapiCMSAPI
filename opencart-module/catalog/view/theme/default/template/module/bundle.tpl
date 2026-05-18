<?php echo $header; ?>
<div class="container">
  <ul class="breadcrumb">
    <?php foreach ($breadcrumbs as $breadcrumb) { ?>
    <li><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a></li>
    <?php } ?>
  </ul>
  <div class="row">
    <?php echo $column_left; ?>
    <?php if ($column_left && $column_right) { ?>
    <?php $class = 'col-sm-6'; ?>
    <?php } elseif ($column_left || $column_right) { ?>
    <?php $class = 'col-sm-9'; ?>
    <?php } else { ?>
    <?php $class = 'col-sm-12'; ?>
    <?php } ?>
    <div id="content" class="<?php echo $class; ?>">
      <?php if ($bundles) { ?>
      <div class="bundle-grid">
        <?php foreach ($bundles as $bundle) { ?>
        <div class="bundle-item">
          <div class="bundle-image">
            <?php if ($bundle['discount']) { ?>
            <span class="bundle-discount-badge">-<?php echo $bundle['discount']; ?>%</span>
            <?php } ?>
            <img src="<?php echo $bundle['image']; ?>" alt="<?php echo $bundle['name']; ?>" />
          </div>
          <div class="bundle-info">
            <h3 class="bundle-name"><?php echo $bundle['name']; ?></h3>
            <p class="bundle-description"><?php echo $bundle['description']; ?></p>
            
            <div class="bundle-products">
              <h4><?php echo $text_includes; ?></h4>
              <ul>
                <?php foreach ($bundle['products'] as $product) { ?>
                <li>
                  <img src="<?php echo $product['image']; ?>" alt="" />
                  <span><?php echo $product['name']; ?> x<?php echo $product['quantity']; ?></span>
                  <span class="product-price"><?php echo $product['price']; ?></span>
                </li>
                <?php } ?>
              </ul>
            </div>
            
            <div class="bundle-pricing">
              <span class="original-price"><strike><?php echo $bundle['original_price']; ?></strike></span>
              <span class="bundle-price"><?php echo $bundle['bundle_price']; ?></span>
            </div>
            
            <button type="button" class="btn btn-primary bundle-add-btn" onclick="addBundleToCart(<?php echo $bundle['id']; ?>)">
              <i class="fa fa-shopping-cart"></i> <?php echo $button_cart; ?>
            </button>
          </div>
        </div>
        <?php } ?>
      </div>
      <?php } else { ?>
      <p><?php echo $text_no_results; ?></p>
      <?php } ?>
    </div>
    <?php echo $column_right; ?>
  </div>
</div>
<script type="text/javascript">
function addBundleToCart(bundleId) {
    $.ajax({
        url: 'index.php?route=checkout/cart/addBundle',
        type: 'post',
        data: {bundle_id: bundleId},
        dataType: 'json',
        beforeSend: function() {
            $('#cart > button').button('loading');
        },
        complete: function() {
            $('#cart > button').button('reset');
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
        },
        error: function(xhr, ajaxOptions, thrownError) {
            alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
        }
    });
}
</script>
<!-- Maven Music Network Branding -->
<div style="position: fixed; bottom: 10px; right: 10px; z-index: 9999; background: rgba(0,0,0,0.8); padding: 5px 10px; border-radius: 4px; border: 1px solid #d3b65f;">
  <a href="https://mavenmusic.network" target="_blank" title="Powered by Maven Music Network" style="text-decoration: none; display: flex; align-items: center; gap: 5px;">
    <img src="https://raw.githubusercontent.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI/main/assets/logo-maven-music.svg" alt="Maven Music Network" style="height: 24px; width: auto;">
    <span style="color: #d3b65f; font-size: 11px; font-family: Arial, sans-serif;">Powered by Maven Music Network</span>
  </a>
</div>
<?php echo $footer; ?>