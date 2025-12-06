const express = require('express');
const router = express.Router();
const technicianController = require('./technician_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Rutas para administradores y secretarias
router.get('/', roleMiddleware.checkRole(['admin', 'secretary']), technicianController.getAllTechnicians);
router.post('/', roleMiddleware.isAdmin, technicianController.createTechnician);
router.put('/:id', roleMiddleware.isAdmin, technicianController.updateTechnician);
router.delete('/:id', roleMiddleware.isAdmin, technicianController.deleteTechnician);
router.get('/location/:locationId', roleMiddleware.checkRole(['admin', 'secretary']), technicianController.getTechniciansByLocation);
router.get('/available', roleMiddleware.checkRole(['admin', 'secretary']), technicianController.getAvailableTechnicians);
router.patch('/:id/completion-rate', roleMiddleware.isAdmin, technicianController.updateTechnicianCompletionRate);
router.get('/:id/warranty-status', roleMiddleware.checkRole(['admin', 'secretary']), technicianController.checkWarrantyPendingStatus);

// Rutas accesibles para técnicos (sobre sí mismos) o administradores/secretarias (sobre cualquier técnico)
router.get('/:id', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.id == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, technicianController.getTechnicianById);

router.get('/:id/services', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.id == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, technicianController.getTechnicianServiceHistory);

router.get('/:id/completed-services', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.id == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, technicianController.getTechnicianCompletedServices);

router.get('/:id/performance', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.id == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, technicianController.getTechnicianPerformance);

router.get('/:id/dashboard', (req, res, next) => {
    if (req.user.role === 'technician') {
        if (req.params.id == req.user.technician_id) {
            return next();
        }
        return roleMiddleware.checkRole(['admin', 'secretary'])(req, res, next);
    }
    return next();
}, technicianController.getTechnicianDashboard);

// Dashboard para el técnico autenticado
router.get('/dashboard/my', roleMiddleware.isTechnician, technicianController.getTechnicianDashboard);

module.exports = router;