const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointment.controller');
const validateRequest = require('../middlewares/validateRequest');
const { createAppointmentSchema, updateStatusSchema, availabilitySchema } = require('../validators/appointment.validator');
const { authenticate, authorize } = require('../middlewares/authMiddleware');

// Engine core
router.post('/', authenticate, authorize(['PARENT', 'ADMIN']), validateRequest(createAppointmentSchema), appointmentController.createAppointment);
router.get('/my-schedule', authenticate, appointmentController.getMySchedule);
router.get('/:id', authenticate, appointmentController.getAppointment);
// PARENT is allowed through here, but the controller restricts them to CANCELLED on their own children
router.patch('/:id/status', authenticate, authorize(['DOCTOR', 'FACILITY', 'ADMIN', 'PARENT']), validateRequest(updateStatusSchema), appointmentController.updateStatus);

// Subsystem core
router.post('/availability', authenticate, authorize(['DOCTOR', 'FACILITY', 'ADMIN']), validateRequest(availabilitySchema), appointmentController.createAvailability);
router.get('/availability/:doctorId', authenticate, appointmentController.getAvailabilityConfig);

module.exports = router;
