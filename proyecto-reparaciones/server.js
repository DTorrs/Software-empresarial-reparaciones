const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const config = require('./config/config');

// Rutas de los módulos
const authRoutes = require('./modules/auth/auth_routes');
const userRoutes = require('./modules/user/user_routes');
const locationRoutes = require('./modules/location/location_routes');
const clientRoutes = require('./modules/client/client_routes');
const serviceRoutes = require('./modules/service/service_routes');
const technicianRoutes = require('./modules/technician/technician_routes');
const paymentRoutes = require('./modules/payment/payment_routes');
const twilioRoutes = require('./modules/twilio/twilio_routes');

// Inicializar la aplicación Express
const app = express();

// Configurar middlewares
app.use(helmet()); // Seguridad HTTP
app.use(cors()); // Permitir solicitudes cross-origin
app.use(morgan('dev')); // Logging de solicitudes HTTP
app.use(express.json()); // Analizar solicitudes JSON
app.use(express.urlencoded({ extended: true })); // Analizar solicitudes URL-encoded

// Configurar directorio estático para uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Configurar rutas base para API
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/technicians', technicianRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/twilio', twilioRoutes);

// Ruta de bienvenida/status
app.get('/', (req, res) => {
    res.json({
        message: 'API de Sistema de Gestión de Servicios de Reparación',
        status: 'online',
        version: '1.0.0'
    });
});

// Middleware para manejo de rutas no encontradas
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        message: 'Ruta no encontrada'
    });
});

// Middleware para manejo de errores
app.use((err, req, res, next) => {
    console.error('Error no controlado:', err);
    res.status(500).json({
        success: false,
        message: 'Error interno del servidor',
        error: config.env === 'development' ? err.message : undefined
    });
});

// Iniciar el servidor
const PORT = config.port;
app.listen(PORT, () => {
    console.log(`Servidor ejecutándose en el puerto ${PORT}`);
    console.log(`Ambiente: ${config.env}`);
});

module.exports = app; // Para pruebas