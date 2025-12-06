require('dotenv').config();

module.exports = {
    port: process.env.PORT || 3000,
    jwtSecret: process.env.JWT_SECRET || 'your-secret-key',
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '24h',
    encryptionKey: process.env.ENCRYPTION_KEY || 'your-32-character-encryption-key',
    uploadDir: process.env.UPLOAD_DIR || 'uploads/services',
    maxServicesPerTechnician: process.env.MAX_SERVICES_PER_TECHNICIAN || 5,
    maxCompletionDays: process.env.MAX_COMPLETION_DAYS || 3,
    basePaymentPercentage: process.env.BASE_PAYMENT_PERCENTAGE || 80, // 80%
    env: process.env.NODE_ENV || 'development'
};