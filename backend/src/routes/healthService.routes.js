const express = require('express');
const router = express.Router();
const controller = require('../controllers/healthService.controller');
const validateRequest = require('../middlewares/validateRequest');
const { createHealthServiceSchema, updateHealthServiceSchema } = require('../validators/healthService.validator');
const { authenticate } = require('../middlewares/authMiddleware');
const { requireFacilityScope } = require('../middlewares/facilityScope');

// Parent-readable: list active services for a specific facility (no facility scope required)
router.get('/by-facility/:facilityId', authenticate, controller.listByFacilityPublic);

router.get('/', authenticate, requireFacilityScope, controller.list);
router.get('/:id', authenticate, requireFacilityScope, controller.get);
router.post('/', authenticate, requireFacilityScope, validateRequest(createHealthServiceSchema), controller.create);
router.put('/:id', authenticate, requireFacilityScope, validateRequest(updateHealthServiceSchema), controller.update);
router.delete('/:id', authenticate, requireFacilityScope, controller.remove);

module.exports = router;
