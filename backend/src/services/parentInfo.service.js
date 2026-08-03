const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const listByChild = async (childId) => {
  return prisma.parentInfo.findMany({
    where: { childId, deletedAt: null },
    orderBy: { createdAt: 'asc' }
  });
};

const getById = async (id) => {
  const record = await prisma.parentInfo.findUnique({
    where: { id },
    include: { child: { select: { id: true, firstName: true, lastName: true, parentId: true } } }
  });
  if (!record || record.deletedAt) {
    throw Object.assign(new Error('Parent information not found'), { statusCode: 404 });
  }
  return record;
};

const create = async (data) => {
  const child = await prisma.child.findUnique({ where: { id: data.childId } });
  if (!child || child.deletedAt) {
    throw Object.assign(new Error('Linked child not found'), { statusCode: 404 });
  }
  return prisma.parentInfo.create({ data });
};

const update = async (id, data) => {
  await getById(id);
  return prisma.parentInfo.update({ where: { id }, data });
};

const remove = async (id) => {
  await getById(id);
  return prisma.parentInfo.update({
    where: { id },
    data: { deletedAt: new Date() }
  });
};

module.exports = { listByChild, getById, create, update, remove };
