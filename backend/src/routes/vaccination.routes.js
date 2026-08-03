const express = require('express');
const router = express.Router();
const vaccineController = require('../controllers/vaccination.controller');
const validateRequest = require('../middlewares/validateRequest');
const { createTemplateSchema, updateVaccinationStatusSchema, registerVaccinationSchema } = require('../validators/vaccination.validator');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

// Admin Protocol Mappings
router.post('/templates', authenticate, authorize(['ADMIN']), validateRequest(createTemplateSchema), vaccineController.createTemplate);
router.get('/templates', authenticate, vaccineController.getTemplates);

// Child Instance Tracking
router.post('/child/:childId/generate', authenticate, authorize(['PARENT', 'DOCTOR', 'ADMIN']), vaccineController.generateSchedule);
router.get('/child/:childId', authenticate, vaccineController.getSchedule);

// Clinical Check-off
// PARENT is allowed through here, but the controller restricts them to COMPLETED on their own children
router.patch('/:id/status', authenticate, authorize(['DOCTOR', 'FACILITY', 'ADMIN', 'PARENT']), validateRequest(updateVaccinationStatusSchema), vaccineController.updateVaccineEvent);

// Direct registration (ad-hoc / already administered)
router.post('/', authenticate, authorize(['DOCTOR', 'FACILITY', 'ADMIN']), validateRequest(registerVaccinationSchema), vaccineController.registerVaccination);

// Notes update
router.patch('/:id/notes', authenticate, authorize(['DOCTOR', 'FACILITY', 'ADMIN']), vaccineController.updateVaccinationNotes);

module.exports = router;
