const cbService = require('../services/chatbot.service');
const { logAction } = require('../services/audit.service');
const { successResponse } = require('../utils/responseWrapper');

// POST /chatbot/session  — create or resume the active session
const initSession = async (req, res, next) => {
    try {
        const { forceNew = false, language = 'so' } = req.body;
        const sess = await cbService.createSession(req.user.id, forceNew === true, language);
        await logAction(req.user.id, 'START_CHATBOT', 'ChatbotSession', sess.id, null, req);
        return successResponse(res, sess, 'Session ready', 201);
    } catch (err) { next(err); }
};

// POST /chatbot/:sessionId/close  — archive session (called by "New Chat")
const closeSession = async (req, res, next) => {
    try {
        const sess = await cbService.closeSession(req.params.sessionId, req.user.id);
        return successResponse(res, sess, 'Session archived');
    } catch (err) { next(err); }
};

// GET /chatbot/sessions  — list archived sessions for history sidebar
const getSessions = async (req, res, next) => {
    try {
        const sessions = await cbService.getUserSessions(req.user.id);
        return successResponse(res, sessions, 'Sessions loaded');
    } catch (err) { next(err); }
};

// GET /chatbot/:sessionId/history  — messages for a session
const getHistory = async (req, res, next) => {
    try {
        const msgs = await cbService.getSessionMessages(req.params.sessionId, req.user.id);
        return successResponse(res, msgs, 'History loaded');
    } catch (err) { next(err); }
};

// POST /chatbot/:sessionId/chat  — send a message, get AI reply
const sendQuery = async (req, res, next) => {
    try {
        const { message, language = 'so' } = req.body;
        const aiResponse = await cbService.processMessage(
            req.params.sessionId,
            req.user.id,
            message,
            language
        );
        return successResponse(res, aiResponse, 'Reply ready');
    } catch (err) { next(err); }
};

// POST /chatbot/templates  — admin keyword override
const manageTemplate = async (req, res, next) => {
    try {
        const tpl = await cbService.upsertTemplate(req.body.triggerKeyword, req.body.response);
        await logAction(req.user.id, 'MANAGE_CHATBOT_FAQ', 'ChatbotTemplate', tpl.id, { trigger: req.body.triggerKeyword }, req);
        return successResponse(res, tpl, 'Template saved');
    } catch (err) { next(err); }
};

// GET /chatbot/templates  — admin keyword list
const listTemplates = async (req, res, next) => {
    try {
        const tpls = await cbService.listTemplates();
        return successResponse(res, tpls, 'Templates loaded');
    } catch (err) { next(err); }
};

// DELETE /chatbot/templates/:id  — admin keyword removal
const removeTemplate = async (req, res, next) => {
    try {
        await cbService.deleteTemplate(req.params.id);
        await logAction(req.user.id, 'DELETE_CHATBOT_FAQ', 'ChatbotTemplate', req.params.id, null, req);
        return successResponse(res, null, 'Template deleted');
    } catch (err) { next(err); }
};

module.exports = { initSession, closeSession, getSessions, getHistory, sendQuery, manageTemplate, listTemplates, removeTemplate };
