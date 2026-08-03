const express = require('express');
const router = express.Router();
const parentInfoController = require('../controllers/parentInfo.controller');
const validateRequest = require('../middlewares/validateRequest');
const { createParentInfoSchema, updateParentInfoSchema } = require('../validators/parentInfo.validator');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

router.get('/', authenticate, authorize(['PARENT', 'DOCTOR', 'ADMIN']), parentInfoController.list);
router.get('/:id', authenticate, authorize(['PARENT', 'DOCTOR', 'ADMIN']), parentInfoController.get);
router.post('/', authenticate, authorize(['PARENT', 'ADMIN']), validateRequest(createParentInfoSchema), parentInfoController.create);
router.put('/:id', authenticate, authorize(['PARENT', 'ADMIN']), validateRequest(updateParentInfoSchema), parentInfoController.update);
router.delete('/:id', authenticate, authorize(['PARENT', 'ADMIN']), parentInfoController.remove);

module.exports = router;
