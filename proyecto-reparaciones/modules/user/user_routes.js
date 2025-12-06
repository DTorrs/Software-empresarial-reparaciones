const express = require('express');
const router = express.Router();
const userController = require('./user_controller');
const authMiddleware = require('../../middlewares/auth_middleware');
const roleMiddleware = require('../../middlewares/role_middleware');

// Middleware para todas las rutas
router.use(authMiddleware.authenticateJWT);

// Rutas accesibles solo para administradores
router.get('/', roleMiddleware.isAdmin, userController.getAllUsers);
router.post('/', roleMiddleware.isAdmin, userController.createUser);
router.get('/roles', roleMiddleware.isAdmin, userController.getRoles);
router.get('/role/:role', roleMiddleware.isAdmin, userController.getUsersByRole);
router.put('/:id', roleMiddleware.isAdmin, userController.updateUser);
router.delete('/:id', roleMiddleware.isAdmin, userController.deleteUser);
router.patch('/:id/password', roleMiddleware.isAdmin, userController.updatePassword);
router.patch('/:id/status', roleMiddleware.isAdmin, userController.changeUserStatus);

// Ruta accesible para el usuario autenticado o administrador
router.get('/:id', (req, res, next) => {
    // Si el ID solicitado es el mismo que el del usuario autenticado o es administrador
    if (req.params.id == req.user.id || req.user.role === 'admin') {
        return next();
    }
    return roleMiddleware.isAdmin(req, res, next);
}, userController.getUserById);

module.exports = router;