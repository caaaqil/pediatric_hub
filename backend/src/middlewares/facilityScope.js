const { PrismaClient } = require('@prisma/client');
const { errorResponse } = require('../utils/responseWrapper');
const prisma = new PrismaClient();

/**
 * Attaches req.facilityId for FACILITY-role users, resolving from their FacilityProfile.
 * ADMIN sees everything. Any other role is blocked.
 */
const requireFacilityScope = async (req, res, next) => {
  try {
    if (!req.user) return errorResponse(res, 'Authentication required', 401);

    if (req.user.role === 'ADMIN') {
      req.facilityId = req.query.facilityId || null;
      return next();
    }

    if (req.user.role !== 'FACILITY') {
      return errorResponse(res, 'Facility administrator access only', 403);
    }

    const profile = await prisma.facilityProfile.findUnique({ where: { userId: req.user.id } });
    if (!profile || profile.deletedAt) {
      return errorResponse(res, 'No facility profile linked to this account', 403);
    }

    req.facilityId = profile.id;
    req.facilityProfile = profile;
    next();
  } catch (err) {
    return errorResponse(res, 'Failed to resolve facility scope', 500);
  }
};

module.exports = { requireFacilityScope };
