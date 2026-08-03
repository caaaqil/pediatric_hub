const healthServiceService = require('../services/healthService.service');
const { logAction } = require('../services/audit.service');
const { successResponse, errorResponse } = require('../utils/responseWrapper');

const list = async (req, res, next) => {
  try {
    let facilityId = req.facilityId;
    if (req.user.role === 'ADMIN' && req.query.facilityId) {
      facilityId = req.query.facilityId;
    }
    if (!facilityId) return errorResponse(res, 'facilityId is required', 400);
    const items = await healthServiceService.listByFacility(facilityId);
    return successResponse(res, items, 'Health services fetched successfully');
  } catch (err) { next(err); }
};

const get = async (req, res, next) => {
  try {
    const svc = await healthServiceService.getById(req.params.id);
    if (req.user.role !== 'ADMIN' && svc.facilityId !== req.facilityId) {
      return errorResponse(res, 'You do not have access to this service', 403);
    }
    return successResponse(res, svc, 'Health service fetched successfully');
  } catch (err) { next(err); }
};

const create = async (req, res, next) => {
  try {
    let facilityId = req.facilityId;
    if (req.user.role === 'ADMIN' && req.body.facilityId) {
      facilityId = req.body.facilityId;
      delete req.body.facilityId;
    }
    if (!facilityId) return errorResponse(res, 'facilityId is required', 400);

    const svc = await healthServiceService.create(facilityId, req.body);
    await logAction(req.user.id, 'CREATE', 'HealthService', svc.id, null, req);
    return successResponse(res, svc, 'Health service created successfully', 201);
  } catch (err) { next(err); }
};

const update = async (req, res, next) => {
  try {
    const existing = await healthServiceService.getById(req.params.id);
    if (req.user.role !== 'ADMIN' && existing.facilityId !== req.facilityId) {
      return errorResponse(res, 'You do not have access to this service', 403);
    }
    const svc = await healthServiceService.update(req.params.id, req.body);
    await logAction(req.user.id, 'UPDATE', 'HealthService', svc.id, null, req);
    return successResponse(res, svc, 'Health service updated successfully');
  } catch (err) { next(err); }
};

const remove = async (req, res, next) => {
  try {
    const existing = await healthServiceService.getById(req.params.id);
    if (req.user.role !== 'ADMIN' && existing.facilityId !== req.facilityId) {
      return errorResponse(res, 'You do not have access to this service', 403);
    }
    await healthServiceService.remove(req.params.id);
    await logAction(req.user.id, 'DELETE', 'HealthService', req.params.id, null, req);
    return successResponse(res, null, 'Health service archived successfully');
  } catch (err) { next(err); }
};

const listByFacilityPublic = async (req, res, next) => {
  try {
    const { facilityId } = req.params;
    if (!facilityId) return errorResponse(res, 'facilityId is required', 400);
    const items = await healthServiceService.listByFacility(facilityId);
    const activeOnly = items.filter(s => s.isActive);
    return successResponse(res, activeOnly, 'Facility services fetched successfully');
  } catch (err) { next(err); }
};

module.exports = { list, get, create, update, remove, listByFacilityPublic };
