const { z } = require('zod');

const createTemplateSchema = z.object({
  vaccineName: z.string().min(1),
  doseNumber: z.number().int().min(1),
  daysAfterBirth: z.number().int().min(0, "Must be valid aging constraint"),
  description: z.string().optional(),
  isMandatory: z.boolean().optional()
});

const updateVaccinationStatusSchema = z.object({
  status: z.enum(['UPCOMING', 'DUE', 'COMPLETED', 'MISSED']),
  administeredDate: z.string().datetime().optional()
});

const registerVaccinationSchema = z.object({
  childId: z.string().uuid(),
  vaccineName: z.string().min(1),
  doseNumber: z.union([z.number().int().min(1), z.string().transform(v => parseInt(v))]),
  scheduledDate: z.string().min(1),
});

module.exports = { createTemplateSchema, updateVaccinationStatusSchema, registerVaccinationSchema };
