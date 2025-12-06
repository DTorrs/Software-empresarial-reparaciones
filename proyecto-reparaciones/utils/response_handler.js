module.exports = {
    success: (res, data = null, message = 'Operación exitosa', statusCode = 200) => {
        return res.status(statusCode).json({
            success: true,
            message,
            data
        });
    },
    
    error: (res, message = 'Error en la operación', statusCode = 400, errors = null) => {
        return res.status(statusCode).json({
            success: false,
            message,
            errors
        });
    },
    
    unauthorized: (res, message = 'No autorizado') => {
        return res.status(401).json({
            success: false,
            message
        });
    },
    
    forbidden: (res, message = 'Acceso prohibido') => {
        return res.status(403).json({
            success: false,
            message
        });
    },
    
    notFound: (res, message = 'Recurso no encontrado') => {
        return res.status(404).json({
            success: false,
            message
        });
    },
    
    serverError: (res, error = null) => {
        console.error('Server error:', error);
        return res.status(500).json({
            success: false,
            message: 'Error interno del servidor'
        });
    }
};