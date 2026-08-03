const facilityService = require('../services/facility.service');
const { logAction } = require('../services/audit.service');
const { successResponse } = require('../utils/responseWrapper');

const getFacility = async (req, res, next) => {
  try {
    const facility = await facilityService.getFacilityById(req.params.id);
    return successResponse(res, facility, 'Facility fetched successfully');
  } catch (error) { next(error); }
};

const getFacilities = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, search = '' } = req.query;
    const result = await facilityService.getAllFacilities(Number(page), Number(limit), search);
    return successResponse(res, result, 'Facilities fetched successfully');
  } catch (error) { next(error); }
};

const createFacility = async (req, res, next) => {
    try {
        const facility = await facilityService.createFacility(req.body);
        await logAction(req.user.id, 'CREATE_PROFILE', 'FacilityProfile', facility.id, null, req);
        return successResponse(res, facility, 'Facility registered successfully', 201);
    } catch(err) { next(err); }
};

const deleteFacility = async (req, res, next) => {
    try {
        await facilityService.deleteFacility(req.params.id);
        await logAction(req.user.id, 'DELETE_PROFILE', 'FacilityProfile', req.params.id, null, req);
        return successResponse(res, null, 'Facility profile archived');
    } catch(err) { next(err); }
};

const updateFacility = async (req, res, next) => {
  try {
    const facility = await facilityService.updateFacility(req.params.id, req.body);
    await logAction(req.user.id, 'UPDATE_PROFILE', 'FacilityProfile', facility.id, null, req);
    return successResponse(res, facility, 'Facility updated successfully');
  } catch (error) { next(error); }
};

const getMyFacility = async (req, res, next) => {
  try {
    const facility = await facilityService.getMyFacility(req.user.id);
    return successResponse(res, facility, 'Facility fetched successfully');
  } catch (error) { next(error); }
};

const getMyFacilityScope = async (req, res, next) => {
  try {
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    const profile = await prisma.facilityProfile.findUnique({ where: { userId: req.user.id } });
    if (!profile) return require('../utils/responseWrapper').errorResponse(res, 'No facility profile linked', 404);

    const facilityId = profile.id;

    const [doctors, services, appointments, patients] = await Promise.all([
      prisma.doctorProfile.findMany({
        where: { facilityId, deletedAt: null },
        include: { user: { select: { email: true } } }
      }),
      prisma.healthService.findMany({
        where: { facilityId, deletedAt: null },
        orderBy: { createdAt: 'desc' }
      }),
      prisma.appointment.findMany({
        where: { doctor: { facilityId }, deletedAt: null },
        include: { child: { include: { parent: true } }, doctor: true },
        orderBy: { scheduledAt: 'desc' }
      }),
      prisma.child.findMany({
        where: {
          deletedAt: null,
          appointments: { some: { doctor: { facilityId } } }
        },
        include: { parent: true }
      })
    ]);

    return successResponse(res, {
      facility: profile,
      counts: {
        doctors: doctors.length,
        services: services.length,
        appointments: appointments.length,
        patients: patients.length
      },
      doctors,
      services,
      appointments,
      patients
    }, 'Facility scope fetched successfully');
  } catch (error) { next(error); }
};

module.exports = { getFacility, getFacilities, createFacility, deleteFacility, updateFacility, getMyFacility, getMyFacilityScope };
