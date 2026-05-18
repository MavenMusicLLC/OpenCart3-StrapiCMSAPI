<div class="container-fluid">
    <div class="panel panel-default">
        <div class="panel-heading">
            <h3 class="panel-title"><i class="fa fa-pencil"></i> <?php echo $heading_title; ?></h3>
        </div>
        <div class="panel-body">
            <form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data" id="form-bundle-manager" class="form-horizontal">
                <div class="form-group">
                    <label class="col-sm-2 control-label"><?php echo $entry_status; ?></label>
                    <div class="col-sm-10">
                        <select name="bundle_manager_status" class="form-control">
                            <?php if ($bundle_manager_status) { ?>
                            <option value="1" selected="selected"><?php echo $text_enabled; ?></option>
                            <option value="0"><?php echo $text_disabled; ?></option>
                            <?php } else { ?>
                            <option value="1"><?php echo $text_enabled; ?></option>
                            <option value="0" selected="selected"><?php echo $text_disabled; ?></option>
                            <?php } ?>
                        </select>
                    </div>
                </div>
                
                <div class="form-group">
                    <div class="col-sm-12">
                        <hr>
                        <h4>Strapi Bundle Management</h4>
                        <p>Manage your product bundles directly in Strapi CMS.</p>
                        <a href="<?php echo $strapi_url; ?>" target="_blank" class="btn btn-primary">
                            <i class="fa fa-external-link"></i> Open Strapi Admin Panel
                        </a>
                        <a href="<?php echo $strapi_url; ?>/plugins/content-type-builder" target="_blank" class="btn btn-info">
                            <i class="fa fa-cubes"></i> Content Type Builder
                        </a>
                    </div>
                </div>
                
                <div class="form-group">
                    <div class="col-sm-12">
                        <hr>
                        <h4>API Endpoints</h4>
                        <table class="table table-bordered">
                            <tr>
                                <td><strong>Get All Bundles:</strong></td>
                                <td><code>GET /api/bundles</code></td>
                            </tr>
                            <tr>
                                <td><strong>Get Bundle by ID:</strong></td>
                                <td><code>GET /api/bundles/:id</code></td>
                            </tr>
                            <tr>
                                <td><strong>Get Bundles by Product:</strong></td>
                                <td><code>GET /api/bundles/by-product/:productId</code></td>
                            </tr>
                            <tr>
                                <td><strong>Get Bundle by Slug:</strong></td>
                                <td><code>GET /api/bundles/by-slug/:slug</code></td>
                            </tr>
                        </table>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
<!-- Maven Music Network Branding -->
<div style="position: fixed; bottom: 10px; right: 10px; z-index: 9999; background: rgba(0,0,0,0.8); padding: 5px 10px; border-radius: 4px; border: 1px solid #d3b65f;">
  <a href="https://mavenmusic.network" target="_blank" title="Powered by Maven Music Network" style="text-decoration: none; display: flex; align-items: center; gap: 5px;">
    <img src="https://raw.githubusercontent.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI/main/assets/logo-maven-music.svg" alt="Maven Music Network" style="height: 24px; width: auto;">
    <span style="color: #d3b65f; font-size: 11px; font-family: Arial, sans-serif;">Powered by Maven Music Network</span>
  </a>
</div>