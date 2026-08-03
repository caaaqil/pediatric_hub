const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const createChild = async (parentId, data) => {
  return prisma.child.create({
    data: { ...data, parentId }
  });
};

const getChildById = async (id) => {
  const child = await prisma.child.findUnique({
    where: { id },
    include: { medicalRecords: true, vaccinations: true, growthRecords: true }
  });
  if (!child || child.deletedAt) throw Object.assign(new Error('Child not found'), { statusCode: 404 });
  return child;
};

const getChildrenByParent = async (parentId) => {
  return prisma.child.findMany({
    where: { parentId, deletedAt: null }
  });
};

const getAllChildren = async (filter = {}) => {
  const where = { deletedAt: null, ...filter };
  return prisma.child.findMany({
    where,
    include: { parent: true }
  });
};

const getChildrenByFacility = async (facilityId) => {
  return prisma.child.findMany({
    where: {
      deletedAt: null,
      appointments: { some: { doctor: { facilityId } } }
    },
    include: { parent: true }
  });
};

const updateChild = async (id, data) => {
  return prisma.child.update({
    where: { id },
    data
  });
};

module.exports = { createChild, getChildById, getChildrenByParent, getChildrenByFacility, updateChild, getAllChildren };
