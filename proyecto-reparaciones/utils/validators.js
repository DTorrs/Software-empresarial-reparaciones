module.exports = {
    validateEmail: (email) => {
        const re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return !email || re.test(String(email).toLowerCase());
    },
    
    validatePhone: (phone) => {
        // Validar números de teléfono (10 dígitos)
        const re = /^\d{10}$/;
        return re.test(String(phone).replace(/\D/g, ''));
    },
    
    validateRequiredFields: (obj, fields) => {
        const missingFields = fields.filter(field => !obj[field]);
        if (missingFields.length > 0) {
            return {
                valid: false,
                message: `Campos requeridos: ${missingFields.join(', ')}`
            };
        }
        return { valid: true };
    }
};
