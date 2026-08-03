const express = require('express');
const router  = express.Router();
const cb      = require('../controllers/chatbot.controller');
const { authenticate, authorize } = require('../middlewares/authMiddleware');
const validateRequest = require('../middlewares/validateRequest');
const { messageSchema, templateSchema } = require('../validators/chatbot.validator');

const userRoles = ['PARENT', 'DOCTOR', 'ADMIN'];

// Session lifecycle
router.post('/session',                authenticate, authorize(userRoles), cb.initSession);
router.post('/:sessionId/close',       authenticate, cb.closeSession);

// History sidebar
router.get('/sessions',                authenticate, cb.getSessions);
router.get('/:sessionId/history',      authenticate, cb.getHistory);

// Messaging
router.post('/:sessionId/chat',        authenticate, validateRequest(messageSchema), cb.sendQuery);

// Admin templates
router.get('/templates',               authenticate, authorize(['ADMIN']), cb.listTemplates);
router.post('/templates',              authenticate, authorize(['ADMIN']), validateRequest(templateSchema), cb.manageTemplate);
router.delete('/templates/:id',        authenticate, authorize(['ADMIN']), cb.removeTemplate);

module.exports = router;
