const express = require('express');
const router = express.Router();
const contactController = require('../controllers/contact.controller');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

// Public route to submit a message
router.post('/', contactController.submitContactMessage);

// Admin routes to view and update messages
router.use(authenticate);
router.use(authorize(['ADMIN']));
router.get('/', contactController.getContactMessages);
router.patch('/:id', contactController.markAsRead);
router.post('/:id/request-verification', contactController.requestVerification);
router.post('/:id/create-account', contactController.createParentAccount);

module.exports = router;
