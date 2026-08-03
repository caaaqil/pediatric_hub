const nodemailer = require('nodemailer');

const getTransporter = () => {
    return nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: process.env.SMTP_EMAIL,
            pass: process.env.SMTP_PASSWORD
        }
    });
};

/**
 * Send OTP verification email for password reset
 * @param {string} toEmail - Recipient email address
 * @param {string} otp - 6-digit OTP code
 */
const sendOTPEmail = async (toEmail, otp) => {
    const mailOptions = {
        from: `"Pediatric Health Hub" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        subject: '🔐 Password Reset Verification Code — Pediatric Health Hub',
        html: `
            <div style="font-family: 'Segoe UI', Tahoma, sans-serif; max-width: 480px; margin: 0 auto; background: #0f172a; border-radius: 16px; overflow: hidden; border: 1px solid #1e293b;">
                <div style="background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); padding: 32px; text-align: center;">
                    <h1 style="color: white; font-size: 22px; margin: 0; font-weight: 800; letter-spacing: -0.5px;">🏥 Pediatric Health Hub</h1>
                    <p style="color: rgba(255,255,255,0.8); font-size: 13px; margin-top: 6px;">Secure Password Reset</p>
                </div>
                <div style="padding: 32px;">
                    <p style="color: #94a3b8; font-size: 14px; line-height: 1.7; margin-bottom: 24px;">
                        We received a request to reset your password. Use the verification code below to proceed. This code expires in <strong style="color: #f59e0b;">10 minutes</strong>.
                    </p>
                    <div style="background: #1e293b; border: 2px solid #334155; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
                        <p style="color: #64748b; font-size: 11px; text-transform: uppercase; letter-spacing: 3px; margin: 0 0 12px 0; font-weight: 700;">Your Verification Code</p>
                        <p style="color: #38bdf8; font-size: 36px; font-weight: 900; letter-spacing: 8px; margin: 0; font-family: 'Courier New', monospace;">${otp}</p>
                    </div>
                    <p style="color: #475569; font-size: 12px; line-height: 1.6;">
                        If you did not request this, please ignore this email. Your account remains secure.
                    </p>
                </div>
                <div style="background: #0c1322; padding: 16px; text-align: center; border-top: 1px solid #1e293b;">
                    <p style="color: #334155; font-size: 11px; margin: 0;">© 2026 Pediatric Health Hub · Encrypted & Secure</p>
                </div>
            </div>
        `
    };

    try {
        const info = await getTransporter().sendMail(mailOptions);
        console.log(`[EMAIL] OTP sent to ${toEmail}: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error('[EMAIL] Failed to send OTP:', error.message);
        // In development, log the OTP so testing isn't blocked
        if (process.env.NODE_ENV === 'development') {
            console.log(`[EMAIL-DEV-FALLBACK] OTP for ${toEmail}: ${otp}`);
        }
        return false;
    }
};

/**
 * Send Parent Verification Request
 * @param {string} toEmail - Recipient email address
 * @param {string} name - User's name
 */
const sendVerificationRequestEmail = async (toEmail, name) => {
    const mailOptions = {
        from: `"Pediatric Health Hub Support" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        replyTo: process.env.SMTP_EMAIL,
        subject: 'Required: Verify Your Parent Account Request — Pediatric Health Hub',
        html: `
            <div style="font-family: 'Segoe UI', Tahoma, sans-serif; max-width: 480px; margin: 0 auto; background: #0f172a; border-radius: 16px; overflow: hidden; border: 1px solid #1e293b;">
                <div style="background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); padding: 32px; text-align: center;">
                    <h1 style="color: white; font-size: 22px; margin: 0; font-weight: 800; letter-spacing: -0.5px;">🏥 Pediatric Health Hub</h1>
                    <p style="color: rgba(255,255,255,0.8); font-size: 13px; margin-top: 6px;">Identity Verification Required</p>
                </div>
                <div style="padding: 32px;">
                    <p style="color: #f8fafc; font-size: 16px; margin-bottom: 16px; font-weight: 600;">Hello ${name},</p>
                    <p style="color: #94a3b8; font-size: 14px; line-height: 1.7; margin-bottom: 24px;">
                        We received your request to create a Parent Account. To ensure the safety and privacy of our patients, we require a quick identity verification step.
                    </p>
                    <div style="background: #1e293b; border: 2px solid #334155; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 24px;">
                        <p style="color: #38bdf8; font-size: 14px; font-weight: 700; margin: 0;">
                            Please reply directly to this email and attach a valid form of identification (e.g. your ID or your child's birth certificate).
                        </p>
                    </div>
                    <p style="color: #475569; font-size: 12px; line-height: 1.6;">
                        Your documents will be handled securely and deleted immediately after verification. Once verified, your account credentials will be emailed to you.
                    </p>
                </div>
            </div>
        `
    };

    try {
        await getTransporter().sendMail(mailOptions);
        console.log(`[EMAIL] Verification request sent to ${toEmail}`);
        return true;
    } catch (error) {
        console.error('[EMAIL] Failed to send Verification request:', error.message);
        return false;
    }
};

/**
 * Send Parent Credentials
 * @param {string} toEmail - Recipient email address
 * @param {string} name - User's name
 * @param {string} password - Generated password
 */
const sendCredentialsEmail = async (toEmail, name, password) => {
    const mailOptions = {
        from: `"Pediatric Health Hub" <${process.env.SMTP_EMAIL}>`,
        to: toEmail,
        subject: '🎉 Your Parent Account is Ready — Pediatric Health Hub',
        html: `
            <div style="font-family: 'Segoe UI', Tahoma, sans-serif; max-width: 480px; margin: 0 auto; background: #0f172a; border-radius: 16px; overflow: hidden; border: 1px solid #1e293b;">
                <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 32px; text-align: center;">
                    <h1 style="color: white; font-size: 22px; margin: 0; font-weight: 800; letter-spacing: -0.5px;">🏥 Pediatric Health Hub</h1>
                    <p style="color: rgba(255,255,255,0.8); font-size: 13px; margin-top: 6px;">Account Verified & Created</p>
                </div>
                <div style="padding: 32px;">
                    <p style="color: #f8fafc; font-size: 16px; margin-bottom: 16px; font-weight: 600;">Welcome, ${name}!</p>
                    <p style="color: #94a3b8; font-size: 14px; line-height: 1.7; margin-bottom: 24px;">
                        Your identity has been verified and your parent account has been successfully created. You can now log in using the credentials below:
                    </p>
                    <div style="background: #1e293b; border: 2px solid #334155; border-radius: 12px; padding: 24px; margin-bottom: 24px;">
                        <p style="color: #94a3b8; font-size: 12px; margin: 0 0 8px 0;"><strong>Username / Email:</strong></p>
                        <p style="color: #f8fafc; font-size: 16px; margin: 0 0 16px 0;">${toEmail}</p>
                        <p style="color: #94a3b8; font-size: 12px; margin: 0 0 8px 0;"><strong>Temporary Password:</strong></p>
                        <p style="color: #38bdf8; font-size: 24px; font-weight: 900; letter-spacing: 2px; margin: 0; font-family: 'Courier New', monospace;">${password}</p>
                    </div>
                    <p style="color: #475569; font-size: 12px; line-height: 1.6; text-align: center;">
                        For your security, we strongly recommend changing your password after your first login.
                    </p>
                </div>
            </div>
        `
    };

    try {
        await getTransporter().sendMail(mailOptions);
        console.log(`[EMAIL] Credentials sent to ${toEmail}`);
        return true;
    } catch (error) {
        console.error('[EMAIL] Failed to send Credentials:', error.message);
        return false;
    }
};

module.exports = { sendOTPEmail, sendVerificationRequestEmail, sendCredentialsEmail };
