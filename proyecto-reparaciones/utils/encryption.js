const crypto = require('crypto');
const config = require('../config/config');

// Clave de encriptación (32 caracteres para AES-256)
const key = Buffer.from(config.encryptionKey, 'utf8');

module.exports = {
    encrypt: (text) => {
        // Generar un vector de inicialización aleatorio
        const iv = crypto.randomBytes(16);
        
        // Crear el cifrador
        const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
        
        // Cifrar el texto
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        
        // Devolver el texto cifrado y el IV (necesario para descifrar)
        return {
            encryptedData: encrypted,
            iv: iv.toString('hex')
        };
    },
    
    decrypt: (encryptedData, iv) => {
        // Convertir el IV de vuelta a Buffer
        const ivBuffer = Buffer.from(iv, 'hex');
        
        // Crear el descifrador
        const decipher = crypto.createDecipheriv('aes-256-cbc', key, ivBuffer);
        
        // Descifrar el texto
        let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        
        return decrypted;
    }
};