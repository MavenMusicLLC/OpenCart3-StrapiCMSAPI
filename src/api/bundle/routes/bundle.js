'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

const defaultRouter = createCoreRouter('api::bundle.bundle');

module.exports = defaultRouter.addRoutes([
  {
    method: 'GET',
    path: '/bundles/by-product/:productId',
    handler: 'api::bundle.bundle.findByProduct',
    config: {
      auth: false,
      policies: [],
      middlewares: []
    }
  },
  {
    method: 'GET',
    path: '/bundles/by-slug/:slug',
    handler: 'api::bundle.bundle.findBySlug',
    config: {
      auth: false,
      policies: [],
      middlewares: []
    }
  },
  {
    method: 'GET',
    path: '/bundles/:id/calculate',
    handler: 'api::bundle.bundle.calculatePrice',
    config: {
      auth: false,
      policies: [],
      middlewares: []
    }
  },
  {
    method: 'POST',
    path: '/bundles/sync',
    handler: 'api::bundle.bundle.syncFromOpenCart',
    config: {
      auth: false,
      policies: [],
      middlewares: []
    }
  }
]);