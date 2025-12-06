const responseHandler = require('../utils/response_handler');

module.exports = {
    checkRole: (roles) => {
        return (req, res, next) => {
            if (!req.user) {
                return responseHandler.unauthorized(res, 'Usuario no autenticado');
            }
            
            const hasRole = roles.some(role => role === req.user.role);
            
            if (!hasRole) {
                return responseHandler.forbidden(res, 'No tiene permisos para acceder a este recurso');
            }
            
            next();
        };
    },
    
    isAdmin: (req, res, next) => {
        if (!req.user || req.user.role !== 'admin') {
            return responseHandler.forbidden(res, 'Acceso restringido solo para administradores');
        }
        next();
    },
    
    isSecretary: (req, res, next) => {
        if (!req.user || (req.user.role !== 'secretary' && req.user.role !== 'admin')) {
            return responseHandler.forbidden(res, 'Acceso restringido para secretarias');
        }
        next();
    },
    
    isTechnician: (req, res, next) => {
        if (!req.user || req.user.role !== 'technician') {
            return responseHandler.forbidden(res, 'Acceso restringido solo para técnicos');
        }
        next();
    }
};