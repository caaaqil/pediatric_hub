const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { sendVerificationRequestEmail, sendCredentialsEmail } = require('../utils/emailService');

// Submit a new contact message (Public)
exports.submitContactMessage = async (req, res) => {
  try {
    const { firstName, lastName, email, subject, message } = req.body;

    if (!firstName || !lastName || !email || !subject || !message) {
      return res.status(400).json({ status: 'error', message: 'All fields are required' });
    }

    const contactMessage = await prisma.contactMessage.create({
      data: {
        firstName,
        lastName,
        email,
        subject,
        message,
      },
    });

    res.status(201).json({
      status: 'success',
      message: 'Message sent successfully',
      data: contactMessage,
    });
  } catch (error) {
    console.error('Submit Contact Message Error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to send message' });
  }
};

// Get all contact messages (Admin)
exports.getContactMessages = async (req, res) => {
  try {
    const messages = await prisma.contactMessage.findMany({
      orderBy: {
        createdAt: 'desc',
      },
    });

    res.status(200).json({
      status: 'success',
      data: messages,
    });
  } catch (error) {
    console.error('Get Contact Messages Error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to fetch messages' });
  }
};

// Mark message as read/unread (Admin)
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const { isRead } = req.body;

    const message = await prisma.contactMessage.update({
      where: { id },
      data: { isRead },
    });

    res.status(200).json({
      status: 'success',
      message: `Message marked as ${isRead ? 'read' : 'unread'}`,
      data: message,
    });
  } catch (error) {
    console.error('Mark Message Read Error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to update message' });
  }
};

// Request Parent Verification (Admin)
exports.requestVerification = async (req, res) => {
  try {
    const { id } = req.params;
    const message = await prisma.contactMessage.findUnique({ where: { id } });

    if (!message) {
      return res.status(404).json({ status: 'error', message: 'Message not found' });
    }

    const emailSent = await sendVerificationRequestEmail(message.email, message.firstName);

    if (emailSent) {
      res.status(200).json({ status: 'success', message: 'Verification email sent' });
    } else {
      res.status(500).json({ status: 'error', message: 'Failed to send verification email' });
    }
  } catch (error) {
    console.error('Request Verification Error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to request verification' });
  }
};

// Create Parent Account & Send Credentials (Admin)
exports.createParentAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const message = await prisma.contactMessage.findUnique({ where: { id } });

    if (!message) {
      return res.status(404).json({ status: 'error', message: 'Message not found' });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({ where: { email: message.email } });
    if (existingUser) {
      return res.status(400).json({ status: 'error', message: 'An account with this email already exists' });
    }

    // Generate random 10-char password
    const password = crypto.randomBytes(5).toString('hex');
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create User and ParentProfile
    const user = await prisma.user.create({
      data: {
        email: message.email,
        password: hashedPassword,
        role: 'PARENT',
        isEmailVerified: true, // Verified manually by admin
        parentProfile: {
          create: {
            firstName: message.firstName,
            lastName: message.lastName,
          }
        }
      }
    });

    const emailSent = await sendCredentialsEmail(message.email, message.firstName, password);

    if (emailSent) {
      res.status(201).json({ status: 'success', message: 'Parent account created and credentials sent' });
    } else {
      res.status(201).json({ status: 'success', message: 'Parent account created but failed to send credentials email' });
    }
  } catch (error) {
    console.error('Create Parent Account Error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to create parent account' });
  }
};
