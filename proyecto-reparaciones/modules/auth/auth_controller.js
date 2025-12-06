const jwt = require('jsonwebtoken');
const config = require('../../config/config');
const authModel = require('./auth_model');
const responseHandler = require('../../utils/response_handler');
const validators = require('../../utils/validators');

module.exports = {
    login: async (req, res) => {
        try {
            const { username, password } = req.body;
            
            // Validar campos requeridos
            if (!username || !password) {
                return responseHandler.error(res, 'Nombre de usuario y contraseña son requeridos');
            }
            
            // Buscar usuario por nombre de usuario
            const user = await authModel.findUserByUsername(username);
            
            if (!user) {
                return responseHandler.error(res, 'Credenciales inválidas', 401);
            }
            
            // Verificar si el usuario está activo
            if (!user.is_active) {
                return responseHandler.error(res, 'Su cuenta está desactivada. Contacte al administrador.', 403);
            }
            
            // Verificar contraseña
            const isPasswordValid = await authModel.comparePassword(password, user.password);
            
            if (!isPasswordValid) {
                return responseHandler.error(res, 'Credenciales inválidas', 401);
            }
            
            // Crear datos para el token JWT
            const tokenData = {
                id: user.id,
                username: user.username,
                email: user.email,
                name: user.name,
                role: user.role
            };
            
            // Si es técnico, obtener detalles adicionales
            if (user.role === 'technician') {
                const technicianDetails = await authModel.getTechnicianDetails(user.id);
                if (technicianDetails) {
                    tokenData.technician_id = technicianDetails.id;
                    tokenData.location_id = technicianDetails.location_id;
                    tokenData.location_name = technicianDetails.location_name;
                    tokenData.has_pending_warranty = technicianDetails.has_pending_warranty;
                }
            }
            
            // Generar token JWT
            const token = jwt.sign(tokenData, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
            
            // Responder con el token y datos del usuario (sin la contraseña)
            const { password: _, ...userWithoutPassword } = user;
            return responseHandler.success(res, { token, user: userWithoutPassword }, 'Inicio de sesión exitoso');
            
        } catch (error) {
            console.error('Error en login:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    register: async (req, res) => {
        try {
            const { username, password, email, name, role } = req.body;
            
            // Validar campos requeridos
            const validation = validators.validateRequiredFields(
                req.body, 
                ['username', 'password', 'email', 'name', 'role']
            );
            
            if (!validation.valid) {
                return responseHandler.error(res, validation.message);
            }
            
            // Validar email
            if (!validators.validateEmail(email)) {
                return responseHandler.error(res, 'Formato de email inválido');
            }
            
            // Verificar si el usuario ya existe
            const existingUser = await authModel.findUserByUsername(username);
            if (existingUser) {
                return responseHandler.error(res, 'El nombre de usuario ya está en uso');
            }
            
            // Verificar si el email ya existe
            const existingEmail = await authModel.findUserByEmail(email);
            if (existingEmail) {
                return responseHandler.error(res, 'El email ya está en uso');
            }
            
            // Verificar si el rol es válido
            const roleId = await authModel.getRoleIdByName(role);
            if (!roleId) {
                return responseHandler.error(res, 'Rol no válido');
            }
            
            // Crear el usuario
            const userData = {
                username,
                password,
                email,
                name,
                role_id: roleId
            };
            
            const newUser = await authModel.createUser(userData);
            
            if (!newUser) {
                return responseHandler.error(res, 'Error al crear el usuario');
            }
            
            // Responder con los datos del usuario (sin contraseña)
            const { password: _, ...userWithoutPassword } = newUser;
            return responseHandler.success(res, userWithoutPassword, 'Usuario registrado exitosamente', 201);
            
        } catch (error) {
            console.error('Error en register:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    verifyToken: async (req, res) => {
        try {
            // El middleware de autenticación ya verificó el token y puso los datos del usuario en req.user
            const userId = req.user.id;
            
            // Buscar el usuario en la base de datos
            const user = await authModel.findUserByUsername(req.user.username);
            
            if (!user) {
                return responseHandler.error(res, 'Usuario no encontrado', 404);
            }
            
            // Verificar si el usuario está activo
            if (!user.is_active) {
                return responseHandler.error(res, 'Su cuenta está desactivada', 403);
            }
            
            // Responder con los datos del usuario (sin contraseña)
            const { password: _, ...userWithoutPassword } = user;
            return responseHandler.success(res, userWithoutPassword, 'Token válido');
            
        } catch (error) {
            console.error('Error en verifyToken:', error);
            return responseHandler.serverError(res, error);
        }
    }
};