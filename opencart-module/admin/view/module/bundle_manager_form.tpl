<?php echo $header; ?><?php echo $column_left; ?>
<div id="content">
  <div class="page-header">
    <div class="container-fluid">
      <div class="pull-right">
        <button type="submit" form="form-bundle" data-toggle="tooltip" title="<?php echo $button_save; ?>" class="btn btn-primary"><i class="fa fa-save"></i></button>
        <a href="<?php echo $cancel; ?>" data-toggle="tooltip" title="<?php echo $button_cancel; ?>" class="btn btn-default"><i class="fa fa-reply"></i></a>
      </div>
      <h1><?php echo $heading_title; ?></h1>
      <ul class="breadcrumb">
        <?php foreach ($breadcrumbs as $breadcrumb) { ?>
        <li><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a></li>
        <?php } ?>
      </ul>
    </div>
  </div>
  <div class="container-fluid">
    <?php if ($error_warning) { ?>
    <div class="alert alert-danger alert-dismissible"><i class="fa fa-exclamation-circle"></i> <?php echo $error_warning; ?>
      <button type="button" class="close" data-dismiss="alert">&times;</button>
    </div>
    <?php } ?>
    <div class="panel panel-default">
      <div class="panel-heading">
        <h3 class="panel-title"><i class="fa fa-pencil"></i> <?php echo $text_form; ?></h3>
      </div>
      <div class="panel-body">
        <form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data" id="form-bundle" class="form-horizontal">
          <ul class="nav nav-tabs">
            <li class="active"><a href="#tab-general" data-toggle="tab"><?php echo $tab_general; ?></a></li>
            <li><a href="#tab-products" data-toggle="tab"><?php echo $entry_products; ?></a></li>
            <li><a href="#tab-data" data-toggle="tab"><?php echo $tab_data; ?></a></li>
          </ul>
          <div class="tab-content">
            <div class="tab-pane active" id="tab-general">
              <div class="form-group required">
                <label class="col-sm-2 control-label" for="input-name"><?php echo $entry_name; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="name" value="<?php echo isset($bundle['name']) ? $bundle['name'] : ''; ?>" placeholder="<?php echo $entry_name; ?>" id="input-name" class="form-control" />
                  <?php if ($error_name) { ?>
                  <div class="text-danger"><?php echo $error_name; ?></div>
                  <?php } ?>
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-description"><?php echo $entry_description; ?></label>
                <div class="col-sm-10">
                  <textarea name="description" placeholder="<?php echo $entry_description; ?>" id="input-description" class="form-control summernote"><?php echo isset($bundle['description']) ? $bundle['description'] : ''; ?></textarea>
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-short-description"><?php echo $entry_short_description; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="short_description" value="<?php echo isset($bundle['short_description']) ? $bundle['short_description'] : ''; ?>" placeholder="<?php echo $entry_short_description; ?>" id="input-short-description" class="form-control" />
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-image"><?php echo $entry_image; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="image" value="<?php echo isset($bundle['image']) ? $bundle['image'] : ''; ?>" placeholder="<?php echo $entry_image; ?>" id="input-image" class="form-control" />
                </div>
              </div>
            </div>
            <div class="tab-pane" id="tab-products">
              <div class="alert alert-info">
                <i class="fa fa-info-circle"></i> Add products with quantities to create the bundle
              </div>
              <table class="table table-bordered" id="bundle-products">
                <thead>
                  <tr>
                    <td>Product</td>
                    <td>Quantity</td>
                    <td>Price Override</td>
                    <td></td>
                  </tr>
                </thead>
                <tbody>
                  <?php if (!empty($bundle['products'])) { ?>
                  <?php foreach ($bundle['products'] as $index => $product) { ?>
                  <tr>
                    <td>
                      <select name="products[<?php echo $index; ?>][productId]" class="form-control">
                        <option value="">-- Select Product --</option>
                        <?php foreach ($products as $p) { ?>
                        <option value="<?php echo $p['product_id']; ?>" <?php echo ($p['product_id'] == $product['productId']) ? 'selected' : ''; ?>>
                          <?php echo $p['name']; ?> (<?php echo $p['price']; ?>)
                        </option>
                        <?php } ?>
                      </select>
                    </td>
                    <td><input type="number" name="products[<?php echo $index; ?>][quantity]" value="<?php echo $product['quantity']; ?>" class="form-control" /></td>
                    <td><input type="text" name="products[<?php echo $index; ?>][price]" value="<?php echo $product['price']; ?>" class="form-control" /></td>
                    <td><button type="button" onclick="$(this).closest('tr').remove();" class="btn btn-danger"><i class="fa fa-minus"></i></button></td>
                  </tr>
                  <?php } ?>
                  <?php } ?>
                </tbody>
                <tfoot>
                  <tr>
                    <td colspan="4" class="text-right">
                      <button type="button" onclick="addProduct();" class="btn btn-primary"><i class="fa fa-plus"></i> Add Product</button>
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
            <div class="tab-pane" id="tab-data">
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-original-price"><?php echo $entry_original_price; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="original_price" value="<?php echo isset($bundle['original_price']) ? $bundle['original_price'] : '0.00'; ?>" placeholder="<?php echo $entry_original_price; ?>" id="input-original-price" class="form-control" />
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-bundle-price"><?php echo $entry_bundle_price; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="bundle_price" value="<?php echo isset($bundle['bundle_price']) ? $bundle['bundle_price'] : '0.00'; ?>" placeholder="<?php echo $entry_bundle_price; ?>" id="input-bundle-price" class="form-control" />
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-discount"><?php echo $entry_discount_percent; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="discount_percent" value="<?php echo isset($bundle['discount_percent']) ? $bundle['discount_percent'] : '0'; ?>" placeholder="<?php echo $entry_discount_percent; ?>" id="input-discount" class="form-control" />
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-stock"><?php echo $entry_stock; ?></label>
                <div class="col-sm-10">
                  <input type="number" name="stock" value="<?php echo isset($bundle['stock']) ? $bundle['stock'] : '0'; ?>" placeholder="<?php echo $entry_stock; ?>" id="input-stock" class="form-control" />
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-sku"><?php echo $entry_sku; ?></label>
                <div class="col-sm-10">
                  <input type="text" name="sku" value="<?php echo isset($bundle['sku']) ? $bundle['sku'] : ''; ?>" placeholder="<?php echo $entry_sku; ?>" id="input-sku" class="form-control" />
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-status"><?php echo $entry_status; ?></label>
                <div class="col-sm-10">
                  <select name="status" id="input-status" class="form-control">
                    <option value="1" <?php echo (isset($bundle['status']) && $bundle['status'] == 1) ? 'selected' : ''; ?>><?php echo $text_enabled; ?></option>
                    <option value="0" <?php echo (isset($bundle['status']) && $bundle['status'] == 0) ? 'selected' : ''; ?>><?php echo $text_disabled; ?></option>
                  </select>
                </div>
              </div>
              <div class="form-group">
                <label class="col-sm-2 control-label" for="input-sort-order"><?php echo $entry_sort_order; ?></label>
                <div class="col-sm-10">
                  <input type="number" name="sort_order" value="<?php echo isset($bundle['sort_order']) ? $bundle['sort_order'] : '0'; ?>" placeholder="<?php echo $entry_sort_order; ?>" id="input-sort-order" class="form-control" />
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>
<script>
var product_row = <?php echo isset($bundle['products']) ? count($bundle['products']) : 0; ?>;

function addProduct() {
  var html = '<tr>';
  html += '  <td>';
  html += '    <select name="products[' + product_row + '][productId]" class="form-control">';
  html += '      <option value="">-- Select Product --</option>';
  <?php foreach ($products as $p) { ?>
  html += '      <option value="<?php echo $p['product_id']; ?>"><?php echo addslashes($p['name']); ?> (<?php echo $p['price']; ?>)</option>';
  <?php } ?>
  html += '    </select>';
  html += '  </td>';
  html += '  <td><input type="number" name="products[' + product_row + '][quantity]" value="1" class="form-control" /></td>';
  html += '  <td><input type="text" name="products[' + product_row + '][price]" value="" class="form-control" placeholder="Use product price" /></td>';
  html += '  <td><button type="button" onclick="$(this).closest(\'tr\').remove();" class="btn btn-danger"><i class="fa fa-minus"></i></button></td>';
  html += '</tr>';
  
  $('#bundle-products tbody').append(html);
  product_row++;
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