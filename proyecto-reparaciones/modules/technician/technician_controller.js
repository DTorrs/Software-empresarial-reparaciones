const technicianModel = require('./technician_model');
const userModel = require('../user/user_model');
const responseHandler = require('../../utils/response_handler');

module.exports = {
    getAllTechnicians: async (req, res) => {
        try {
            const technicians = await technicianModel.getAllTechnicians();
            return responseHandler.success(res, technicians, 'Técnicos obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting all technicians:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechnicianById: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            return responseHandler.success(res, technician, 'Técnico obtenido exitosamente');
        } catch (error) {
            console.error('Error getting technician by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createTechnician: async (req, res) => {
        try {
            const { user_id, location_id } = req.body;
            
            if (!user_id || !location_id) {
                return responseHandler.error(res, 'ID de usuario y ID de ubicación son requeridos');
            }
            
            // Verificar si el usuario existe y es del rol adecuado
            const user = await userModel.getUserById(user_id);
            
            if (!user) {
                return responseHandler.notFound(res, 'Usuario no encontrado');
            }
            
            if (user.role !== 'technician') {
                return responseHandler.error(res, 'El usuario debe tener el rol de técnico');
            }
            
            // Verificar si ya existe un técnico para este usuario
            const existingTechnician = await technicianModel.getTechnicianByUserId(user_id);
            
            if (existingTechnician) {
                return responseHandler.error(res, 'Ya existe un técnico asociado a este usuario');
            }
            
            // Crear el técnico
            const technicianData = {
                user_id,
                location_id
            };
            
            const newTechnician = await technicianModel.createTechnician(technicianData);
            
            if (!newTechnician) {
                return responseHandler.error(res, 'Error al crear el técnico');
            }
            
            return responseHandler.success(res, newTechnician, 'Técnico creado exitosamente', 201);
        } catch (error) {
            console.error('Error creating technician:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateTechnician: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const existingTechnician = await technicianModel.getTechnicianById(technicianId);
            
            if (!existingTechnician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            const { location_id, is_available } = req.body;
            
            // Preparar datos para actualizar
            const technicianData = {};
            
            if (location_id !== undefined) technicianData.location_id = location_id;
            if (is_available !== undefined) technicianData.is_available = is_available;
            
            // Actualizar técnico
            const updatedTechnician = await technicianModel.updateTechnician(technicianId, technicianData);
            
            if (!updatedTechnician) {
                return responseHandler.error(res, 'Error al actualizar el técnico');
            }
            
            return responseHandler.success(res, updatedTechnician, 'Técnico actualizado exitosamente');
        } catch (error) {
            console.error('Error updating technician:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    deleteTechnician: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Verificar si tiene servicios asociados
            // Esta verificación podría hacerse con una consulta específica
            // pero para simplificar usamos el código de error de MySQL
            
            // Eliminar técnico
            const deleted = await technicianModel.deleteTechnician(technicianId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar el técnico');
            }
            
            return responseHandler.success(res, null, 'Técnico eliminado exitosamente');
        } catch (error) {
            console.error('Error deleting technician:', error);
            
            // Manejo de errores de integridad referencial
            if (error.code === 'ER_ROW_IS_REFERENCED') {
                return responseHandler.error(
                    res, 
                    'No se puede eliminar el técnico porque tiene servicios asociados.',
                    400
                );
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechniciansByLocation: async (req, res) => {
        try {
            const locationId = req.params.locationId;
            
            if (!locationId) {
                return responseHandler.error(res, 'ID de ubicación requerido');
            }
            
            const technicians = await technicianModel.getTechniciansByLocation(locationId);
            
            return responseHandler.success(res, technicians, 'Técnicos por ubicación obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting technicians by location:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getAvailableTechnicians: async (req, res) => {
        try {
            let technicians;
            
            if (req.query.locationId) {
                technicians = await technicianModel.getAvailableTechniciansByLocation(req.query.locationId);
            } else {
                technicians = await technicianModel.getAvailableTechnicians();
            }
            
            return responseHandler.success(res, technicians, 'Técnicos disponibles obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting available technicians:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechnicianServiceHistory: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Si el usuario es técnico, solo puede ver su propio historial
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver el historial de otros técnicos');
            }
            
            const serviceHistory = await technicianModel.getTechnicianServiceHistory(technicianId);
            
            return responseHandler.success(res, serviceHistory, 'Historial de servicios del técnico obtenido exitosamente');
        } catch (error) {
            console.error('Error getting technician service history:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechnicianCompletedServices: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Si el usuario es técnico, solo puede ver sus propios servicios
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver los servicios de otros técnicos');
            }
            
            const completedServices = await technicianModel.getTechnicianCompletedServices(technicianId);
            
            return responseHandler.success(res, completedServices, 'Servicios completados del técnico obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting technician completed services:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechnicianPerformance: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Si el usuario es técnico, solo puede ver su propio rendimiento
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver el rendimiento de otros técnicos');
            }
            
            const performance = await technicianModel.getTechnicianPerformance(technicianId);
            
            return responseHandler.success(res, performance, 'Rendimiento del técnico obtenido exitosamente');
        } catch (error) {
            console.error('Error getting technician performance:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateTechnicianCompletionRate: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Solo administradores pueden actualizar manualmente
            if (req.user.role !== 'admin') {
                return responseHandler.forbidden(res, 'Solo administradores pueden actualizar manualmente la tasa de finalización');
            }
            
            const completionRate = await technicianModel.updateTechnicianCompletionRate(technicianId);
            
            return responseHandler.success(
                res, 
                { technician_id: technicianId, completion_rate: completionRate }, 
                'Tasa de finalización actualizada exitosamente'
            );
        } catch (error) {
            console.error('Error updating technician completion rate:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    checkWarrantyPendingStatus: async (req, res) => {
        try {
            const technicianId = req.params.id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            const hasPendingWarranty = await technicianModel.checkWarrantyPendingStatus(technicianId);
            
            return responseHandler.success(
                res, 
                { technician_id: technicianId, has_pending_warranty: hasPendingWarranty }, 
                'Estado de garantías pendientes verificado exitosamente'
            );
        } catch (error) {
            console.error('Error checking warranty pending status:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechnicianDashboard: async (req, res) => {
        try {
            let technicianId;

            if (req.user.role === 'technician') {
                // Obtener el technician_id desde la tabla technicians usando el user_id del token
                const technician = await technicianModel.getTechnicianByUserId(req.user.id);
                if (!technician) {
                    return responseHandler.notFound(res, 'Técnico no encontrado para este usuario');
                }
                technicianId = technician.id;
            } else {
                technicianId = req.params.id;
            }

            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }

            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }

            // Si el usuario es técnico, solo puede ver su propio dashboard
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver el dashboard de otros técnicos');
            }

            const dashboardData = await technicianModel.getTechnicianDashboardData(technicianId);
            return responseHandler.success(res, dashboardData, 'Dashboard del técnico obtenido exitosamente');
        } catch (error) {
            console.error('Error getting technician dashboard:', error);
            return responseHandler.serverError(res, error);
        }
    },
};