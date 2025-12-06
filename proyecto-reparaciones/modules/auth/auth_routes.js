const express = require('express');
const router = express.Router();
const authController = require('./auth_controller');
const authMiddleware = require('../../middlewares/auth_middleware');

// Rutas públicas
router.post('/login', authController.login);
router.post('/register', authController.register);

// Rutas protegidas
router.get('/verify', authMiddleware.authenticateJWT, authController.verifyToken);

module.exports = router;