const { PrismaClient } = require('@prisma/client');
const crypto = require('crypto');
const prisma = new PrismaClient();

/**
 * WaafiPay merchant credentials — this is the account that RECEIVES the money.
 *
 * Change the wallet money is paid into by setting these in `backend/.env`:
 *
 *   WAAFIPAY_MERCHANT_UID=...
 *   WAAFIPAY_API_USER_ID=...
 *   WAAFIPAY_API_KEY=...
 *
 * The values must come from WaafiPay/Hormuud for the merchant account you own;
 * a plain EVC Plus phone number is not enough. The fallbacks below keep the
 * original account working until the .env values are filled in.
 *
 * Read at call time (not module load) because dotenv runs during the require
 * chain, so module-level reads are not guaranteed to see these yet.
 */
const waafiConfig = () => ({
    url: process.env.WAAFIPAY_URL || 'https://api.waafipay.net/asm',
    merchantUid: process.env.WAAFIPAY_MERCHANT_UID || 'M0910291',
    apiUserId: process.env.WAAFIPAY_API_USER_ID || '1000416',
    apiKey: process.env.WAAFIPAY_API_KEY || 'API-675418888AHX',
});

const initiatePayment = async (userId, { accountNo, amount, description, appointmentId }) => {
    const referenceId = crypto.randomUUID().replace(/-/g, '').slice(0, 16);
    const invoiceId = crypto.randomUUID().replace(/-/g, '').slice(0, 16);

    const payment = await prisma.payment.create({
        data: {
            userId,
            appointmentId: appointmentId || null,
            amount,
            currency: 'USD',
            status: 'PENDING',
            accountNo,
            referenceId,
            invoiceId,
            description: description || 'Pediatric Health Hub — Appointment Payment',
        },
    });

    const timestamp = Date.now().toString();
    const waafi = waafiConfig();

    const payload = {
        schemaVersion: '1.0',
        requestId: referenceId,
        timestamp,
        channelName: 'WEB',
        serviceName: 'API_PURCHASE',
        serviceParams: {
            merchantUid: waafi.merchantUid,
            apiUserId: waafi.apiUserId,
            apiKey: waafi.apiKey,
            paymentMethod: 'mwallet_account',
            payerInfo: { accountNo },
            transactionInfo: {
                referenceId,
                invoiceId,
                amount,
                currency: 'USD',
                description: description || 'Pediatric Health Hub — Appointment Payment',
            },
        },
    };

    let transactionId = null;
    let finalStatus = 'FAILED';
    let errorMessage = 'Payment was declined. Please check your EVC Plus balance and try again.';

    try {
        const res = await fetch(waafi.url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        const data = await res.json();

        if (data.responseCode === '2001' || data.params?.state === 'APPROVED') {
            finalStatus = 'PAID';
            errorMessage = null;
            transactionId = data.params?.transactionId || data.params?.issuerTransactionId || null;
        } else {
            const code = data.responseCode || data.errorCode || '';
            const msg  = data.responseMsg || '';
            if (code === '5310' || msg === 'RCS_USER_REJECTED') {
                errorMessage = 'Payment not approved. Open your EVC Plus app and approve the payment prompt, then try again.';
            } else if (code === '5061' || msg.includes('balance') || msg.includes('insufficient')) {
                errorMessage = 'Insufficient EVC Plus balance. Please top up and try again.';
            } else if (code === '5032' || msg.includes('missing')) {
                errorMessage = 'Invalid payment request. Please try again.';
            } else if (data.params?.description) {
                errorMessage = data.params.description;
            }
            console.error('[Payment] WaafiPay declined:', code, msg);
        }
    } catch (err) {
        console.error('[Payment] WaafiPay API error:', err.message);
        errorMessage = 'Could not reach payment provider. Please try again.';
    }

    const updated = await prisma.payment.update({
        where: { id: payment.id },
        data: { status: finalStatus, transactionId },
    });

    return { payment: updated, errorMessage };
};

const getPayments = async (userId, role) => {
    const where = role === 'ADMIN' ? {} : { userId };
    return prisma.payment.findMany({
        where,
        include: { user: { select: { email: true, parentProfile: { select: { firstName: true, lastName: true } } } } },
        orderBy: { createdAt: 'desc' },
    });
};

const getPaymentById = async (id, userId, role) => {
    const payment = await prisma.payment.findUnique({ where: { id } });
    if (!payment) throw Object.assign(new Error('Payment not found'), { statusCode: 404 });
    if (role !== 'ADMIN' && payment.userId !== userId)
        throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    return payment;
};

module.exports = { initiatePayment, getPayments, getPaymentById };
