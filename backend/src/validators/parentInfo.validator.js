const { z } = require('zod');

const RELATIONSHIPS = ['FATHER', 'MOTHER', 'UNCLE', 'AUNT', 'MATERNAL_UNCLE', 'MATERNAL_AUNT', 'GUARDIAN', 'OTHER'];

const createParentInfoSchema = z.object({
  childId: z.string().uuid(),
  fullName: z.string().min(2).max(120),
  phoneNumber: z.string().min(5).max(30),
  address: z.string().min(2).max(255),
  healthStatus: z.string().max(2000).optional().nullable(),
  relationship: z.enum(RELATIONSHIPS)
});

const updateParentInfoSchema = z.object({
  fullName: z.string().min(2).max(120).optional(),
  phoneNumber: z.string().min(5).max(30).optional(),
  address: z.string().min(2).max(255).optional(),
  healthStatus: z.string().max(2000).optional().nullable(),
  relationship: z.enum(RELATIONSHIPS).optional()
});

module.exports = { createParentInfoSchema, updateParentInfoSchema, RELATIONSHIPS };
