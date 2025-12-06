const jwt = require('jsonwebtoken');
const config = require('../config/config');
const responseHandler = require('../utils/response_handler');

module.exports = {
    authenticateJWT: (req, res, next) => {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return responseHandler.unauthorized(res, 'Token de autenticación no proporcionado');
        }
        
        const token = authHeader.split(' ')[1];
        
        try {
            const decoded = jwt.verify(token, config.jwtSecret);
            req.user = decoded;
            next();
        } catch (error) {
            return responseHandler.unauthorized(res, 'Token inválido o expirado');
        }
    }
};