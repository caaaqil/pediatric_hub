const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const createTemplate = async (data) => prisma.vaccineTemplate.create({ data });
const getTemplates = async () => prisma.vaccineTemplate.findMany({ orderBy: { daysAfterBirth: 'asc' } });

const generateScheduleForChild = async (childId) => {
  const child = await prisma.child.findUnique({ where: { id: childId } });
  if (!child) throw Object.assign(new Error('Patient boundaries not located'), { statusCode: 404 });

  const templates = await prisma.vaccineTemplate.findMany();
  const existing = await prisma.vaccination.findMany({ where: { childId } });

  const existingMap = new Set(existing.map(v => `${v.vaccineName}-${v.doseNumber}`));

  const newVaccines = [];
  for (const t of templates) {
    if (!existingMap.has(`${t.vaccineName}-${t.doseNumber}`)) {
       // Extrapolate timestamp structurally based on age
       const scheduledDate = new Date(child.dateOfBirth.getTime() + t.daysAfterBirth * 24 * 60 * 60 * 1000);
       let status = 'UPCOMING';
       if(scheduledDate < new Date()) status = 'MISSED'; 
       
       newVaccines.push({
           childId,
           vaccineName: t.vaccineName,
           doseNumber: t.doseNumber,
           scheduledDate,
           status
       });
    }
  }

  // Atomically flush missing records
  if (newVaccines.length > 0) {
      await prisma.vaccination.createMany({ data: newVaccines });
  }

  return await prisma.vaccination.findMany({ where: { childId }, orderBy: { scheduledDate: 'asc' } });
};

const getScheduleByChild = async (childId) => {
   return prisma.vaccination.findMany({ where: { childId }, orderBy: { scheduledDate: 'asc' } });
};

const updateVaccination = async (id, data) => {
   if (data.status === 'COMPLETED' && !data.administeredDate) {
       data.administeredDate = new Date();
   }
   return prisma.vaccination.update({ where: { id }, data });
};

const registerVaccination = async ({ childId, vaccineName, doseNumber, scheduledDate }) => {
   const child = await prisma.child.findUnique({ where: { id: childId } });
   if (!child) throw Object.assign(new Error('Child not found'), { statusCode: 404 });

   const scheduled = scheduledDate ? new Date(scheduledDate) : new Date();
   const now = new Date();
   const diffDays = (now - scheduled) / (1000 * 60 * 60 * 24);
   let status = 'UPCOMING';
   if (diffDays > 7) status = 'MISSED';
   else if (diffDays >= 0) status = 'DUE';

   return prisma.vaccination.create({
       data: {
           childId,
           vaccineName,
           doseNumber: parseInt(doseNumber) || 1,
           scheduledDate: scheduled,
           status,
       }
   });
};

const updateVaccinationNotes = async (id, notes) => {
   // notes field requires regenerated Prisma client — re-enable after server restart + `prisma generate`
   // return prisma.vaccination.update({ where: { id }, data: { notes } });
   return prisma.vaccination.findUnique({ where: { id } });
};

module.exports = { createTemplate, getTemplates, generateScheduleForChild, getScheduleByChild, updateVaccination, registerVaccination, updateVaccinationNotes };
