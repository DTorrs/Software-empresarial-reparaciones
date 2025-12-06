const express = require('express');
const router = express.Router();
const twilioController = require('./twilio_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Rutas para administradores y secretarias
router.get('/', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.getAllMessages);
router.get('/statistics', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.getMessageStatistics);
router.get('/pending', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.getPendingMessages);
router.post('/send-pending', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.sendPendingMessages);
router.get('/:id', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.getMessageById);
router.patch('/:id/status', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.updateMessageStatus);
router.delete('/:id', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.deleteMessage);

// Rutas para mensajes por servicio (accesibles para técnicos si es su servicio)
router.get('/service/:serviceId', (req, res, next) => {
    // Si es admin o secretaria, permitir acceso
    if (['admin', 'secretary'].includes(req.user.role)) {
        return next();
    }
    
    // Si es técnico, verificar que sea su servicio (esto se verifica en el controlador)
    if (req.user.role === 'technician') {
        return next();
    }
    
    return responseHandler.forbidden(res, 'No tiene permiso para acceder a estos mensajes');
}, twilioController.getMessagesByService);

// Rutas para crear mensajes específicos
router.post('/welcome', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.sendWelcomeMessage);
router.post('/quote', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.sendQuoteMessage);
router.post('/completion', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.sendCompletionMessage);
router.post('/payment-reminder', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.sendPaymentReminder);
router.post('/warranty-notification', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.sendWarrantyNotification);
router.post('/message', roleMiddleware.checkRole(['admin', 'secretary']), twilioController.createMessage);

// Ruta para comunicación anónima (técnicos y administradores)
router.post('/anonymous-message', roleMiddleware.checkRole(['admin', 'secretary', 'technician']), twilioController.sendAnonymousMessage);

module.exports = router;