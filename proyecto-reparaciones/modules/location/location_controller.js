const locationModel = require('./location_model');
const responseHandler = require('../../utils/response_handler');

module.exports = {
    getAllLocations: async (req, res) => {
        try {
            const locations = await locationModel.getAllLocations();
            return responseHandler.success(res, locations, 'Ubicaciones obtenidas exitosamente');
        } catch (error) {
            console.error('Error getting all locations:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getLocationById: async (req, res) => {
        try {
            const locationId = req.params.id;
            
            if (!locationId) {
                return responseHandler.error(res, 'ID de ubicación requerido');
            }
            
            const location = await locationModel.getLocationById(locationId);
            
            if (!location) {
                return responseHandler.notFound(res, 'Ubicación no encontrada');
            }
            
            return responseHandler.success(res, location, 'Ubicación obtenida exitosamente');
        } catch (error) {
            console.error('Error getting location by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createLocation: async (req, res) => {
        try {
            const { name } = req.body;
            
            if (!name) {
                return responseHandler.error(res, 'Nombre de ubicación requerido');
            }
            
            const newLocation = await locationModel.createLocation({ name });
            
            if (!newLocation) {
                return responseHandler.error(res, 'Error al crear la ubicación');
            }
            
            return responseHandler.success(res, newLocation, 'Ubicación creada exitosamente', 201);
        } catch (error) {
            console.error('Error creating location:', error);
            
            // Manejo de errores de duplicidad
            if (error.code === 'ER_DUP_ENTRY') {
                return responseHandler.error(res, 'La ubicación ya existe', 400);
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    updateLocation: async (req, res) => {
        try {
            const locationId = req.params.id;
            const { name } = req.body;
            
            if (!locationId) {
                return responseHandler.error(res, 'ID de ubicación requerido');
            }
            
            if (!name) {
                return responseHandler.error(res, 'Nombre de ubicación requerido');
            }
            
            // Verificar si la ubicación existe
            const location = await locationModel.getLocationById(locationId);
            
            if (!location) {
                return responseHandler.notFound(res, 'Ubicación no encontrada');
            }
            
            // Actualizar ubicación
            const updatedLocation = await locationModel.updateLocation(locationId, { name });
            
            if (!updatedLocation) {
                return responseHandler.error(res, 'Error al actualizar la ubicación');
            }
            
            return responseHandler.success(res, updatedLocation, 'Ubicación actualizada exitosamente');
        } catch (error) {
            console.error('Error updating location:', error);
            
            // Manejo de errores de duplicidad
            if (error.code === 'ER_DUP_ENTRY') {
                return responseHandler.error(res, 'La ubicación ya existe', 400);
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    deleteLocation: async (req, res) => {
        try {
            const locationId = req.params.id;
            
            if (!locationId) {
                return responseHandler.error(res, 'ID de ubicación requerido');
            }
            
            // Verificar si la ubicación existe
            const location = await locationModel.getLocationById(locationId);
            
            if (!location) {
                return responseHandler.notFound(res, 'Ubicación no encontrada');
            }
            
            // Eliminar ubicación
            const deleted = await locationModel.deleteLocation(locationId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar la ubicación');
            }
            
            return responseHandler.success(res, null, 'Ubicación eliminada exitosamente');
        } catch (error) {
            console.error('Error deleting location:', error);
            
            // Manejo de errores de integridad referencial
            if (error.code === 'ER_ROW_IS_REFERENCED') {
                return responseHandler.error(
                    res, 
                    'No se puede eliminar la ubicación porque tiene registros asociados.',
                    400
                );
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    getLocationStatistics: async (req, res) => {
        try {
            const statistics = await locationModel.getLocationStatistics();
            return responseHandler.success(res, statistics, 'Estadísticas de ubicaciones obtenidas exitosamente');
        } catch (error) {
            console.error('Error getting location statistics:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechniciansCountByLocation: async (req, res) => {
        try {
            const counts = await locationModel.getTechniciansCountByLocation();
            return responseHandler.success(res, counts, 'Conteo de técnicos por ubicación obtenido exitosamente');
        } catch (error) {
            console.error('Error getting technicians count by location:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getServicesCountByLocation: async (req, res) => {
        try {
            const counts = await locationModel.getServicesCountByLocation();
            return responseHandler.success(res, counts, 'Conteo de servicios por ubicación obtenido exitosamente');
        } catch (error) {
            console.error('Error getting services count by location:', error);
            return responseHandler.serverError(res, error);
        }
    }
};