'use strict';

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::bundle.bundle', ({ strapi }) => ({
    async find(ctx) {
        const { query } = ctx;
        
        try {
            const entities = await strapi.entityService.findMany('api::bundle.bundle', {
                filters: {
                    isActive: true,
                    ...query.filters
                },
                sort: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
                populate: '*',
                ...query
            });
            
            return this.transformResponse(entities);
        } catch (error) {
            ctx.throw(500, error);
        }
    },

    async findByProduct(ctx) {
        const { productId } = ctx.params;
        
        try {
            const entities = await strapi.entityService.findMany('api::bundle.bundle', {
                filters: {
                    isActive: true
                },
                sort: [{ sortOrder: 'asc' }]
            });

            const bundles = entities.filter(bundle => {
                if (!bundle.products || !Array.isArray(bundle.products)) return false;
                return bundle.products.some(p => p.productId === productId);
            });

            return this.transformResponse(bundles);
        } catch (error) {
            ctx.throw(500, error);
        }
    },

    async findBySlug(ctx) {
        const { slug } = ctx.params;
        
        try {
            const entity = await strapi.entityService.findMany('api::bundle.bundle', {
                filters: { 
                    slug: slug,
                    isActive: true 
                }
            });

            if (!entity || entity.length === 0) {
                return ctx.notFound('Bundle not found');
            }

            return this.transformResponse(entity[0]);
        } catch (error) {
            ctx.throw(500, error);
        }
    },

    async syncFromOpenCart(ctx) {
        const { bundles } = ctx.request.body;
        
        if (!bundles || !Array.isArray(bundles)) {
            return ctx.badRequest('Invalid bundles data');
        }

        try {
            const results = {
                created: 0,
                updated: 0,
                errors: []
            };

            for (const bundle of bundles) {
                try {
                    const existing = await strapi.entityService.findMany('api::bundle.bundle', {
                        filters: { slug: bundle.slug }
                    });

                    if (existing.length > 0) {
                        await strapi.entityService.update('api::bundle.bundle', existing[0].id, {
                            data: {
                                name: bundle.name,
                                description: bundle.description,
                                shortDescription: bundle.shortDescription,
                                image: bundle.image,
                                images: bundle.images,
                                originalPrice: bundle.originalPrice,
                                bundlePrice: bundle.bundlePrice,
                                discountPercent: bundle.discountPercent,
                                isActive: bundle.isActive,
                                stock: bundle.stock,
                                sku: bundle.sku,
                                products: bundle.products,
                                categories: bundle.categories,
                                metaTitle: bundle.metaTitle,
                                metaDescription: bundle.metaDescription,
                                sortOrder: bundle.sortOrder || 0,
                                validFrom: bundle.validFrom,
                                validTo: bundle.validTo
                            }
                        });
                        results.updated++;
                    } else {
                        await strapi.entityService.create('api::bundle.bundle', {
                            data: {
                                name: bundle.name,
                                slug: bundle.slug,
                                description: bundle.description,
                                shortDescription: bundle.shortDescription,
                                image: bundle.image,
                                images: bundle.images,
                                originalPrice: bundle.originalPrice,
                                bundlePrice: bundle.bundlePrice,
                                discountPercent: bundle.discountPercent,
                                isActive: bundle.isActive ?? true,
                                stock: bundle.stock || 0,
                                sku: bundle.sku,
                                products: bundle.products,
                                categories: bundle.categories,
                                metaTitle: bundle.metaTitle,
                                metaDescription: bundle.metaDescription,
                                sortOrder: bundle.sortOrder || 0,
                                validFrom: bundle.validFrom,
                                validTo: bundle.validTo
                            }
                        });
                        results.created++;
                    }
                } catch (err) {
                    results.errors.push({ bundle: bundle.name, error: err.message });
                }
            }

            return this.transformResponse({ success: true, ...results });
        } catch (error) {
            ctx.throw(500, error);
        }
    },

    async calculatePrice(ctx) {
        const { bundleId } = ctx.params;
        
        try {
            const bundle = await strapi.entityService.findOne('api::bundle.bundle', parseInt(bundleId));
            
            if (!bundle) {
                return ctx.notFound('Bundle not found');
            }

            const originalPrice = parseFloat(bundle.originalPrice);
            const bundlePrice = parseFloat(bundle.bundlePrice);
            const discountPercent = bundle.discountPercent 
                ? parseFloat(bundle.discountPercent)
                : Math.round((1 - bundlePrice / originalPrice) * 100);

            return this.transformResponse({
                originalPrice,
                bundlePrice,
                discountPercent,
                savings: originalPrice - bundlePrice
            });
        } catch (error) {
            ctx.throw(500, error);
        }
    }
}));