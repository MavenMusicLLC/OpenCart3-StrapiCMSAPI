'use strict';

module.exports = {
  async findActiveBundles() {
    const now = new Date().toISOString();
    
    return strapi.entityService.findMany('api::bundle.bundle', {
      filters: {
        isActive: true,
        $or: [
          { validFrom: { $null: true } },
          { validFrom: { $lte: now } }
        ],
        $or: [
          { validTo: { $null: true } },
          { validTo: { $gte: now } }
        ]
      },
      sort: [{ sortOrder: 'asc' }, { createdAt: 'desc' }]
    });
  },

  async findBundlesByProduct(productId) {
    const bundles = await strapi.entityService.findMany('api::bundle.bundle', {
      filters: {
        isActive: true
      },
      sort: [{ sortOrder: 'asc' }]
    });

    return bundles.filter(bundle => {
      if (!bundle.products || !Array.isArray(bundle.products)) return false;
      return bundle.products.some(p => p.productId === productId);
    });
  },

  async createOrUpdate(slug, data) {
    const existing = await strapi.entityService.findMany('api::bundle.bundle', {
      filters: { slug }
    });

    if (existing.length > 0) {
      return strapi.entityService.update('api::bundle.bundle', existing[0].id, { data });
    }

    return strapi.entityService.create('api::bundle.bundle', { data: { ...data, slug } });
  },

  async syncAll(bundles) {
    const results = { created: 0, updated: 0, errors: [] };

    for (const bundle of bundles) {
      try {
        const result = await this.createOrUpdate(bundle.slug, bundle);
        if (result.createdAt === result.updatedAt) {
          results.created++;
        } else {
          results.updated++;
        }
      } catch (error) {
        results.errors.push({ slug: bundle.slug, error: error.message });
      }
    }

    return results;
  }
};