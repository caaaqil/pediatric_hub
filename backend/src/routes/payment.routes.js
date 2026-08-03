const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middlewares/authMiddleware');
const { initiatePaymentHandler, getPaymentsHandler, getPaymentByIdHandler } = require('../controllers/payment.controller');

router.use(authenticate);

router.post('/', authorize(['PARENT', 'ADMIN']), initiatePaymentHandler);
router.get('/', authorize(['PARENT', 'ADMIN']), getPaymentsHandler);
router.get('/:id', authorize(['PARENT', 'ADMIN']), getPaymentByIdHandler);

module.exports = router;
