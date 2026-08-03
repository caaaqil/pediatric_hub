const { z } = require('zod');

const createHealthServiceSchema = z.object({
  name: z.string().min(1).max(150),
  description: z.string().max(2000).optional().nullable(),
  price: z.number().nonnegative().optional().nullable(),
  isActive: z.boolean().optional()
});

const updateHealthServiceSchema = z.object({
  name: z.string().min(1).max(150).optional(),
  description: z.string().max(2000).optional().nullable(),
  price: z.number().nonnegative().optional().nullable(),
  isActive: z.boolean().optional()
});

module.exports = { createHealthServiceSchema, updateHealthServiceSchema };
