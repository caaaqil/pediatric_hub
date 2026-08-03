const { initiatePayment, getPayments, getPaymentById } = require('../services/payment.service');

const initiatePaymentHandler = async (req, res, next) => {
    try {
        const { accountNo, amount, description, appointmentId } = req.body;
        const { payment, errorMessage } = await initiatePayment(req.user.id, { accountNo, amount, description, appointmentId });
        const statusCode = payment.status === 'PAID' ? 201 : 402;
        res.status(statusCode).json({
            success: payment.status === 'PAID',
            data: payment,
            ...(errorMessage && { message: errorMessage }),
        });
    } catch (err) {
        next(err);
    }
};

const getPaymentsHandler = async (req, res, next) => {
    try {
        const payments = await getPayments(req.user.id, req.user.role);
        res.json({ data: payments });
    } catch (err) {
        next(err);
    }
};

const getPaymentByIdHandler = async (req, res, next) => {
    try {
        const payment = await getPaymentById(req.params.id, req.user.id, req.user.role);
        res.json({ data: payment });
    } catch (err) {
        next(err);
    }
};

module.exports = { initiatePaymentHandler, getPaymentsHandler, getPaymentByIdHandler };
