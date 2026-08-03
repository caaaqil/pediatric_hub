const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const listByFacility = async (facilityId) => {
  return prisma.healthService.findMany({
    where: { facilityId, deletedAt: null },
    orderBy: { createdAt: 'desc' }
  });
};

const getById = async (id) => {
  const svc = await prisma.healthService.findUnique({ where: { id } });
  if (!svc || svc.deletedAt) {
    throw Object.assign(new Error('Health service not found'), { statusCode: 404 });
  }
  return svc;
};

const create = async (facilityId, data) => {
  return prisma.healthService.create({
    data: { ...data, facilityId }
  });
};

const update = async (id, data) => {
  await getById(id);
  return prisma.healthService.update({ where: { id }, data });
};

const remove = async (id) => {
  await getById(id);
  return prisma.healthService.update({
    where: { id },
    data: { deletedAt: new Date() }
  });
};

module.exports = { listByFacility, getById, create, update, remove };
