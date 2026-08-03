const vaccineService = require('../services/vaccination.service');
const { logAction } = require('../services/audit.service');
const { successResponse, errorResponse } = require('../utils/responseWrapper');

const createTemplate = async (req, res, next) => {
    try {
        const tpl = await vaccineService.createTemplate(req.body);
        await logAction(req.user.id, 'CREATE_VACCINE_TEMPLATE', 'VaccineTemplate', tpl.id, null, req);
        return successResponse(res, tpl, "Global protocol mapped successfully", 201);
    } catch(err) { next(err); }
};

const getTemplates = async (req, res, next) => {
    try {
        const tpls = await vaccineService.getTemplates();
        return successResponse(res, tpls, "Master rules returned", 200);
    } catch(err) { next(err); }
};

const generateSchedule = async (req, res, next) => {
    try {
        const sched = await vaccineService.generateScheduleForChild(req.params.childId);
        await logAction(req.user.id, 'SYNC_VACCINE_SCHEDULE', 'Child', req.params.childId, null, req);
        return successResponse(res, sched, "Vaccine map dynamically deployed and updated securely", 201);
    } catch(err) { next(err); }
};

const getSchedule = async (req, res, next) => {
    try {
        const sched = await vaccineService.getScheduleByChild(req.params.childId);
        return successResponse(res, sched, "Vaccine map retrieved securely", 200);
    } catch(err) { next(err); }
};

const updateVaccineEvent = async (req, res, next) => {
    try {
        // Parents may only check off a dose as COMPLETED, and only for their own children
        if (req.user.role === 'PARENT') {
            if (req.body.status !== 'COMPLETED') {
                return errorResponse(res, 'Parents may only mark a vaccine as COMPLETED', 403);
            }
            const { PrismaClient } = require('@prisma/client');
            const prisma = new PrismaClient();
            const parent = await prisma.parentProfile.findUnique({ where: { userId: req.user.id } });
            if (!parent) return errorResponse(res, 'No parent profile linked', 403);

            const owned = await prisma.vaccination.findFirst({
                where: { id: req.params.id, deletedAt: null, child: { parentId: parent.id } }
            });
            if (!owned) return errorResponse(res, 'You can only update vaccines for your own children', 403);
        }

        const vac = await vaccineService.updateVaccination(req.params.id, req.body);
        await logAction(req.user.id, 'UPDATE_VACCINE_STATUS', 'Vaccination', vac.id, { status: req.body.status }, req);
        return successResponse(res, vac, "Vaccine clinical state recorded", 200);
    } catch(err) { next(err); }
};

const registerVaccination = async (req, res, next) => {
    try {
        const vac = await vaccineService.registerVaccination({ ...req.body });
        await logAction(req.user.id, 'REGISTER_VACCINATION', 'Vaccination', vac.id, null, req);
        return successResponse(res, vac, "Vaccination registered successfully", 201);
    } catch(err) { next(err); }
};

const updateVaccinationNotes = async (req, res, next) => {
    try {
        const vac = await vaccineService.updateVaccinationNotes(req.params.id, req.body.notes);
        return successResponse(res, vac, "Notes updated", 200);
    } catch(err) { next(err); }
};

module.exports = { createTemplate, getTemplates, generateSchedule, getSchedule, updateVaccineEvent, registerVaccination, updateVaccinationNotes };
