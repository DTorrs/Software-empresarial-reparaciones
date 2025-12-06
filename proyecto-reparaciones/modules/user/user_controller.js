const userModel = require('./user_model');
const responseHandler = require('../../utils/response_handler');
const validators = require('../../utils/validators');

module.exports = {
    getAllUsers: async (req, res) => {
        try {
            const users = await userModel.getAllUsers();
            return responseHandler.success(res, users, 'Usuarios obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting all users:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getUserById: async (req, res) => {
        try {
            const userId = req.params.id;
            
            if (!userId) {
                return responseHandler.error(res, 'ID de usuario requerido');
            }
            
            const user = await userModel.getUserById(userId);
            
            if (!user) {
                return responseHandler.notFound(res, 'Usuario no encontrado');
            }
            
            return responseHandler.success(res, user, 'Usuario obtenido exitosamente');
        } catch (error) {
            console.error('Error getting user by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createUser: async (req, res) => {
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
            
            // Obtener el ID del rol
            const roles = await userModel.getRoles();
            const roleObj = roles.find(r => r.name === role);
            
            if (!roleObj) {
                return responseHandler.error(res, 'Rol no válido');
            }
            
            // Crear usuario
            const userData = {
                username,
                password,
                email,
                name,
                role_id: roleObj.id
            };
            
            const newUser = await userModel.createUser(userData);
            
            if (!newUser) {
                return responseHandler.error(res, 'Error al crear el usuario');
            }
            
            return responseHandler.success(res, newUser, 'Usuario creado exitosamente', 201);
        } catch (error) {
            console.error('Error creating user:', error);
            
            // Manejo de errores de duplicidad
            if (error.code === 'ER_DUP_ENTRY') {
                if (error.message.includes('username')) {
                    return responseHandler.error(res, 'El nombre de usuario ya está en uso', 400);
                } else if (error.message.includes('email')) {
                    return responseHandler.error(res, 'El email ya está en uso', 400);
                }
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    updateUser: async (req, res) => {
        try {
            const userId = req.params.id;
            
            if (!userId) {
                return responseHandler.error(res, 'ID de usuario requerido');
            }
            
            // Verificar si el usuario existe
            const user = await userModel.getUserById(userId);
            
            if (!user) {
                return responseHandler.notFound(res, 'Usuario no encontrado');
            }
            
            // Procesar datos para actualizar
            const { username, email, name, role, password, is_active } = req.body;
            const updateData = {};
            
            if (username) updateData.username = username;
            if (email) updateData.email = email;
            if (name) updateData.name = name;
            if (password) updateData.password = password;
            if (is_active !== undefined) updateData.is_active = is_active;
            
            // Si hay un rol, obtener su ID
            if (role) {
                const roles = await userModel.getRoles();
                const roleObj = roles.find(r => r.name === role);
                
                if (!roleObj) {
                    return responseHandler.error(res, 'Rol no válido');
                }
                
                updateData.role_id = roleObj.id;
            }
            
            // Actualizar usuario
            const updatedUser = await userModel.updateUser(userId, updateData);
            
            if (!updatedUser) {
                return responseHandler.error(res, 'Error al actualizar el usuario');
            }
            
            return responseHandler.success(res, updatedUser, 'Usuario actualizado exitosamente');
        } catch (error) {
            console.error('Error updating user:', error);
            
            // Manejo de errores de duplicidad
            if (error.code === 'ER_DUP_ENTRY') {
                if (error.message.includes('username')) {
                    return responseHandler.error(res, 'El nombre de usuario ya está en uso', 400);
                } else if (error.message.includes('email')) {
                    return responseHandler.error(res, 'El email ya está en uso', 400);
                }
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    deleteUser: async (req, res) => {
        try {
            const userId = req.params.id;
            
            if (!userId) {
                return responseHandler.error(res, 'ID de usuario requerido');
            }
            
            // Verificar si el usuario existe
            const user = await userModel.getUserById(userId);
            
            if (!user) {
                return responseHandler.notFound(res, 'Usuario no encontrado');
            }
            
            // Eliminar usuario
            const deleted = await userModel.deleteUser(userId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar el usuario');
            }
            
            return responseHandler.success(res, null, 'Usuario eliminado exitosamente');
        } catch (error) {
            console.error('Error deleting user:', error);
            
            // Manejo de errores de integridad referencial
            if (error.code === 'ER_ROW_IS_REFERENCED') {
                return responseHandler.error(
                    res, 
                    'No se puede eliminar el usuario porque tiene registros asociados. Considere desactivarlo en su lugar.',
                    400
                );
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    updatePassword: async (req, res) => {
        try {
            const userId = req.params.id;
            const { password } = req.body;
            
            if (!userId) {
                return responseHandler.error(res, 'ID de usuario requerido');
            }
            
            if (!password) {
                return responseHandler.error(res, 'La nueva contraseña es requerida');
            }
            
            // Verificar si el usuario existe
            const user = await userModel.getUserById(userId);
            
            if (!user) {
                return responseHandler.notFound(res, 'Usuario no encontrado');
            }
            
            // Actualizar contraseña
            const updated = await userModel.updatePassword(userId, password);
            
            if (!updated) {
                return responseHandler.error(res, 'Error al actualizar la contraseña');
            }
            
            return responseHandler.success(res, null, 'Contraseña actualizada exitosamente');
        } catch (error) {
            console.error('Error updating password:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getUsersByRole: async (req, res) => {
        try {
            const { role } = req.params;
            
            if (!role) {
                return responseHandler.error(res, 'Rol requerido');
            }
            
            const users = await userModel.getUsersByRole(role);
            return responseHandler.success(res, users, `Usuarios con rol ${role} obtenidos exitosamente`);
        } catch (error) {
            console.error('Error getting users by role:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    changeUserStatus: async (req, res) => {
        try {
            const userId = req.params.id;
            const { is_active } = req.body;
            
            if (!userId) {
                return responseHandler.error(res, 'ID de usuario requerido');
            }
            
            if (is_active === undefined) {
                return responseHandler.error(res, 'Estado requerido');
            }
            
            // Verificar si el usuario existe
            const user = await userModel.getUserById(userId);
            
            if (!user) {
                return responseHandler.notFound(res, 'Usuario no encontrado');
            }
            
            // Cambiar estado
            const updated = await userModel.changeUserStatus(userId, is_active);
            
            if (!updated) {
                return responseHandler.error(res, 'Error al cambiar el estado del usuario');
            }
            
            const statusMsg = is_active ? 'activado' : 'desactivado';
            return responseHandler.success(res, null, `Usuario ${statusMsg} exitosamente`);
        } catch (error) {
            console.error('Error changing user status:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getRoles: async (req, res) => {
        try {
            const roles = await userModel.getRoles();
            return responseHandler.success(res, roles, 'Roles obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting roles:', error);
            return responseHandler.serverError(res, error);
        }
    }
};