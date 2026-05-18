#!/bin/bash
# Bundle Sync Script - Syncs bundles between OpenCart and Strapi
# Run via cron or webhook

STRAPI_URL="${STRAPI_URL:-http://localhost:1337}"
OPENCART_DB_HOST="${DB_HOST:-localhost}"
OPENCART_DB_NAME="${DB_NAME:-ocdev1}"
OPENCART_DB_USER="${DB_USER:-ocdev1}"
OPENCART_DB_PASS="${DB_PASSWORD:-}"

echo "Starting bundle sync..."
echo "Strapi URL: $STRAPI_URL"

# Get all bundles from OpenCart
BUNDLES=$(mysql -h "$OPENCART_DB_HOST" -u "$OPENCART_DB_USER" -p"$OPENCART_DB_PASS" "$OPENCART_DB_NAME" -N -e "
SELECT JSON_ARRAYAGG(
  JSON_OBJECT(
    'name', name,
    'slug', slug,
    'description', description,
    'shortDescription', short_description,
    'image', image,
    'images', images,
    'originalPrice', original_price,
    'bundlePrice', bundle_price,
    'discountPercent', discount_percent,
    'isActive', status = 1,
    'stock', stock,
    'sku', sku,
    'products', products,
    'categories', categories,
    'metaTitle', meta_title,
    'metaDescription', meta_description,
    'sortOrder', sort_order,
    'validFrom', valid_from,
    'validTo', valid_to
  )
) FROM oc_bundles WHERE status = 1;
" 2>/dev/null)

if [ "$BUNDLES" = "null" ] || [ -z "$BUNDLES" ]; then
    echo "No bundles found or error fetching bundles"
    exit 1
fi

# Sync to Strapi
RESPONSE=$(curl -s -X POST "$STRAPI_URL/api/bundles/sync" \
    -H "Content-Type: application/json" \
    -d "{\"bundles\": $BUNDLES}")

if echo "$RESPONSE" | grep -q "success"; then
    echo "Sync completed successfully"
else
    echo "Sync may have issues: $RESPONSE"
fi

echo "Bundle sync complete at $(date)"