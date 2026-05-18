# ⚡ API Reference

## OpenCart Module API

### Loading the Model

```php
$this->load->model('module/bundle');
```

### Methods

#### getBundles()

Retrieve all active bundles.

```php
$bundles = $this->model_module_bundle->getBundles($limit = 10, $category_id = 0);
```

**Parameters:**
| Name | Type | Default | Description |
|------|------|---------|-------------|
| limit | int | 10 | Maximum number of bundles to return |
| category_id | int | 0 | Filter by category (0 = all) |

**Returns:** Array of bundle arrays

```php
[
    [
        'id' => 1,
        'name' => 'Gaming PC Bundle',
        'slug' => 'gaming-pc-bundle',
        'description' => '...',
        'image' => 'image.jpg',
        'original_price' => 950.00,
        'bundle_price' => 899.00,
        'discount' => 5.37,
        'products' => [...],
        'stock' => 10,
        'sku' => 'BUNDLE-001'
    ],
    // ...
]
```

---

#### getBundleById()

Get a specific bundle by ID.

```php
$bundle = $this->model_module_bundle->getBundleById($bundle_id);
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| bundle_id | int | Bundle ID |

**Returns:** Bundle array or null

---

#### getBundlesByProduct()

Find bundles containing a specific product.

```php
$bundles = $this->model_module_bundle->getBundlesByProduct($product_id);
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| product_id | int | Product ID |

**Returns:** Array of bundle arrays

---

#### getProducts()

Get product details for given product IDs.

```php
$products = $this->model_module_bundle->getProducts($product_ids);
```

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| product_ids | array | Array of product IDs |

**Returns:** Associative array keyed by product ID

---

#### getTotalBundles()

Get total number of active bundles.

```php
$total = $this->model_module_bundle->getTotalBundles($category_id = 0);
```

---

## Strapi REST API

### Base URL

```
http://localhost:1337/api
```

### Authentication

By default, all bundle endpoints are public. To enable authentication:

1. Go to Strapi Admin → Settings → Users & Permissions Plugin → Roles
2. Edit "Public" role
3. Set permissions for Bundle content type

### Endpoints

#### GET /bundles

List all bundles.

**Query Parameters:**

| Parameter | Example | Description |
|-----------|---------|-------------|
| pagination[limit] | 10 | Number of results |
| filters[isActive] | true | Filter by status |
| sort | sortOrder:asc | Sort order |

**Example Request:**
```bash
curl "http://localhost:1337/api/bundles?pagination[limit]=10&filters[isActive][$eq]=true"
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "attributes": {
        "name": "Gaming PC Bundle",
        "slug": "gaming-pc-bundle",
        "originalPrice": 950.00,
        "bundlePrice": 899.00,
        "discountPercent": 5.37,
        "isActive": true,
        "products": [
          {
            "productId": "1",
            "name": "Intel Core i5-12400F",
            "price": 250.00,
            "quantity": 1
          }
        ]
      }
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "pageSize": 10,
      "pageCount": 1,
      "total": 5
    }
  }
}
```

---

#### GET /bundles/:id

Get bundle by ID.

**Example:**
```bash
curl "http://localhost:1337/api/bundles/1"
```

---

#### GET /bundles/by-slug/:slug

Get bundle by slug.

**Example:**
```bash
curl "http://localhost:1337/api/bundles/by-slug/gaming-pc-bundle"
```

---

#### GET /bundles/by-product/:productId

Get bundles containing a product.

**Example:**
```bash
curl "http://localhost:1337/api/bundles/by-product/42"
```

---

#### GET /bundles/:id/calculate

Calculate bundle pricing.

**Response:**
```json
{
  "data": {
    "originalPrice": 950.00,
    "bundlePrice": 899.00,
    "discountPercent": 5.37,
    "savings": 51.00
  }
}
```

---

#### POST /bundles/sync

Sync bundles from OpenCart.

**Request Body:**
```json
{
  "bundles": [
    {
      "name": "Gaming PC Bundle",
      "slug": "gaming-pc-bundle",
      "description": "...",
      "originalPrice": 950.00,
      "bundlePrice": 899.00,
      "products": [...]
    }
  ]
}
```

**Response:**
```json
{
  "data": {
    "success": true,
    "created": 2,
    "updated": 3,
    "errors": []
  }
}
```

---

## Database Schema

### oc_bundles

| Column | Type | Description |
|--------|------|-------------|
| bundle_id | int(11) | Primary key |
| name | varchar(255) | Bundle name |
| slug | varchar(255) | URL-friendly identifier |
| description | text | HTML description |
| short_description | varchar(500) | Short summary |
| image | varchar(255) | Main image URL |
| images | text | JSON array of images |
| original_price | decimal(15,2) | Total individual prices |
| bundle_price | decimal(15,2) | Discounted price |
| discount_percent | decimal(5,2) | Discount percentage |
| products | text | JSON product array |
| categories | text | JSON category IDs |
| stock | int(11) | Available quantity |
| sku | varchar(100) | Unique SKU |
| status | tinyint(1) | Active=1, Inactive=0 |
| sort_order | int(11) | Display priority |
| valid_from | datetime | Optional start date |
| valid_to | datetime | Optional end date |
| date_added | datetime | Creation date |
| date_modified | datetime | Last update |

### oc_bundle_products

| Column | Type | Description |
|--------|------|-------------|
| id | int(11) | Primary key |
| bundle_id | int(11) | Reference to bundle |
| product_id | int(11) | Reference to product |
| product_name | varchar(255) | Product name |
| model | varchar(100) | Product model |
| quantity | int(3) | Quantity in bundle |
| price | decimal(15,2) | Price override |
| image | varchar(255) | Product image |
| options | text | JSON options |
| sort_order | int(3) | Display order |

### oc_bundle_settings

| Column | Type | Description |
|--------|------|-------------|
| id | int(11) | Primary key |
| key | varchar(100) | Setting key |
| value | text | Setting value |
| serialized | tinyint(1) | Is serialized |

---

## Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| 404 | Bundle not found | Check bundle ID |
| 500 | Server error | Check logs |
| 403 | Permission denied | Check API permissions |
| 400 | Bad request | Check request format |

---

<div align="center">

**[← Back to Main README](../README.md)**

</div>