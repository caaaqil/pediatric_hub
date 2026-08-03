const parentInfoService = require('../services/parentInfo.service');
const { logAction } = require('../services/audit.service');
const { successResponse, errorResponse } = require('../utils/responseWrapper');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const assertCanAccessChild = async (user, childId) => {
  if (user.role === 'ADMIN' || user.role === 'DOCTOR') return true;
  if (user.role === 'PARENT') {
    const parent = await prisma.parentProfile.findUnique({ where: { userId: user.id } });
    if (!parent) return false;
    const child = await prisma.child.findUnique({ where: { id: childId } });
    return child && child.parentId === parent.id;
  }
  return false;
};

const list = async (req, res, next) => {
  try {
    const childId = req.query.childId;
    if (!childId) return errorResponse(res, 'childId query parameter is required', 400);

    const allowed = await assertCanAccessChild(req.user, childId);
    if (!allowed) return errorResponse(res, 'You do not have access to this child record', 403);

    const items = await parentInfoService.listByChild(childId);
    return successResponse(res, items, 'Parent records fetched successfully');
  } catch (err) { next(err); }
};

const get = async (req, res, next) => {
  try {
    const record = await parentInfoService.getById(req.params.id);
    const allowed = await assertCanAccessChild(req.user, record.childId);
    if (!allowed) return errorResponse(res, 'You do not have access to this parent record', 403);
    return successResponse(res, record, 'Parent record fetched successfully');
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    const allowed = await assertCanAccessChild(req.user, req.body.childId);
    if (!allowed) return errorResponse(res, 'You do not have access to this child record', 403);

    const record = await parentInfoService.create(req.body);
    await logAction(req.user.id, 'CREATE', 'ParentInfo', record.id, null, req);
    return successResponse(res, record, 'Parent record created successfully', 201);
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const existing = await parentInfoService.getById(req.params.id);
    const allowed = await assertCanAccessChild(req.user, existing.childId);
    if (!allowed) return errorResponse(res, 'You do not have access to this parent record', 403);

    const record = await parentInfoService.update(req.params.id, req.body);
    await logAction(req.user.id, 'UPDATE', 'ParentInfo', record.id, null, req);
    return successResponse(res, record, 'Parent record updated successfully');
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const existing = await parentInfoService.getById(req.params.id);
    const allowed = await assertCanAccessChild(req.user, existing.childId);
    if (!allowed) return errorResponse(res, 'You do not have access to this parent record', 403);

    await parentInfoService.remove(req.params.id);
    await logAction(req.user.id, 'DELETE', 'ParentInfo', req.params.id, null, req);
    return successResponse(res, null, 'Parent record deleted successfully');
  } catch (err) { next(err); }
};

module.exports = { list, get, create, update, remove };
