const express = require('express');
const router = express.Router();
const serviceController = require('./service_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');
const uploadMiddleware = require('../../middlewares/upload_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Rutas generales (accesibles para todos los roles autenticados)
router.get('/:id', serviceController.getServiceById);

// Rutas para administradores y secretarias
router.get('/', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.getAllServices);
router.post('/', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.createService);
router.put('/:id', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.updateService);
router.delete('/:id', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.deleteService);
router.patch('/:id/final-price', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.updateFinalPrice);
router.post('/warranty', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.createWarrantyService);
router.get('/technicians/available', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.getAvailableTechnicians);

// Rutas de búsqueda y filtrado (accesibles para administradores y secretarias)
router.get('/status/:status', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.getServicesByStatus);
router.get('/location/:locationId', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.getServicesByLocation);
router.get('/warranty/all', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.getWarrantyServices);
router.get('/statistics/all', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.getServiceStatistics);
router.get('/search', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.searchServices);

// Rutas para técnicos
router.get('/technician/:technicianId', (req, res, next) => {
    // Si el ID solicitado es el mismo que el del técnico autenticado o es admin/secretary
    if ((req.user.role === 'technician' && req.params.technicianId == req.user.technician_id) || 
        ['admin', 'secretary'].includes(req.user.role)) {
        return next();
    }
    return responseHandler.forbidden(res, 'No tiene permiso para ver servicios de otros técnicos');
}, serviceController.getServicesByTechnician);

// Actualizaciones de estado y asignación
router.patch('/:id/status', serviceController.updateServiceStatus);
router.patch('/:id/assign', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.assignTechnician);
router.patch('/:id/estimated-price', serviceController.updateEstimatedPrice);

// Rutas para fotos
router.post('/:id/photos', uploadMiddleware.uploadServicePhoto, serviceController.uploadServicePhoto);
router.delete('/photos/:photoId', roleMiddleware.checkRole(['admin', 'secretary', 'technician']), serviceController.removeServicePhoto);

// Cálculo de pagos
router.get('/:id/payment', roleMiddleware.checkRole(['admin', 'secretary']), serviceController.calculateTechnicianPayment);

module.exports = router;