const { z } = require('zod');
const { strongPasswordSchema } = require('./auth.validator');

const FACILITY_TYPES = ['HOSPITAL', 'CLINIC'];

const createFacilitySchema = z.object({
  userId: z.string().uuid().optional(),
  email: z.string().email().optional(),
  password: strongPasswordSchema.optional(),
  name: z.string().min(1),
  address: z.string().min(1),
  phoneNumber: z.string().min(1),
  facilityType: z.enum(FACILITY_TYPES).optional(),
  isActive: z.boolean().optional()
});

const updateFacilitySchema = z.object({
  name: z.string().min(1).optional(),
  address: z.string().min(1).optional(),
  phoneNumber: z.string().min(1).optional(),
  facilityType: z.enum(FACILITY_TYPES).optional(),
  isActive: z.boolean().optional()
});

module.exports = { updateFacilitySchema, createFacilitySchema, FACILITY_TYPES };

