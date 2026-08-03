const { z } = require('zod');

const messageSchema = z.object({
    message:  z.string().min(1).max(2000),
    language: z.enum(['so', 'en']).optional().default('so'),
});

const templateSchema = z.object({
  triggerKeyword: z.string().min(2),
  response: z.string().min(5)
});

module.exports = { messageSchema, templateSchema };
