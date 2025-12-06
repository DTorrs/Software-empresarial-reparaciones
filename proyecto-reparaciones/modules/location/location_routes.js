const express = require('express');
const router = express.Router();
const locationController = require('./location_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Rutas para todas las ubicaciones (disponible para cualquier usuario autenticado)
router.get('/', locationController.getAllLocations);
router.get('/:id', locationController.getLocationById);

// Rutas para administración de ubicaciones (solo administradores)
router.post('/', roleMiddleware.isAdmin, locationController.createLocation);
router.put('/:id', roleMiddleware.isAdmin, locationController.updateLocation);
router.delete('/:id', roleMiddleware.isAdmin, locationController.deleteLocation);

// Rutas para estadísticas (administradores y secretarias)
router.get('/statistics/all', roleMiddleware.checkRole(['admin', 'secretary']), locationController.getLocationStatistics);
router.get('/statistics/technicians', roleMiddleware.checkRole(['admin', 'secretary']), locationController.getTechniciansCountByLocation);
router.get('/statistics/services', roleMiddleware.checkRole(['admin', 'secretary']), locationController.getServicesCountByLocation);

module.exports = router;