const express = require('express');
const router = express.Router();
const paymentController = require('./payment_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Rutas para administradores y secretarias
router.get('/', roleMiddleware.checkRole(['admin', 'secretary']), paymentController.getAllPaymentCalculations);
router.get('/statistics', roleMiddleware.checkRole(['admin', 'secretary']), paymentController.getPaymentStatistics);
router.get('/date-range', roleMiddleware.checkRole(['admin', 'secretary']), paymentController.getPaymentsByDateRange);
router.post('/recalculate-all', roleMiddleware.isAdmin, paymentController.recalculateAllPayments);
router.post('/service/:serviceId', roleMiddleware.checkRole(['admin', 'secretary']), paymentController.calculatePaymentForService);
router.get('/:id', roleMiddleware.checkRole(['admin', 'secretary']), paymentController.getPaymentCalculationById);

// Rutas para técnicos (sobre sus propios pagos) o admin/secretarias
router.get('/technician/:technicianId', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.technicianId == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, paymentController.getPaymentsByTechnician);

router.get('/technician/:technicianId/summary', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.technicianId == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, paymentController.getTechnicianPaymentSummary);

// Rutas específicas para técnicos
router.get('/my/payments', roleMiddleware.isTechnician, paymentController.getMyPayments);
router.get('/my/summary', roleMiddleware.isTechnician, paymentController.getMyPaymentSummary);

module.exports = router;