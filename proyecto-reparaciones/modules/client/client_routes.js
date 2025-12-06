const express = require('express');
const router = express.Router();
const clientController = require('./client_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Restringir acceso a administradores y secretarias
router.use(roleMiddleware.checkRole(['admin', 'secretary']));

// Rutas para cliente
router.get('/', clientController.getAllClients);
router.get('/search', clientController.searchClients);
router.get('/location/:locationId', clientController.getClientsByLocation);
router.get('/:id', clientController.getClientById);
router.get('/:id/services', clientController.getClientServiceHistory);
router.post('/', clientController.createClient);
router.put('/:id', clientController.updateClient);
router.delete('/:id', clientController.deleteClient);

module.exports = router;