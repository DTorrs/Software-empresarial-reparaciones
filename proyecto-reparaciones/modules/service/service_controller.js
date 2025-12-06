const path = require('path');
const fs = require('fs');
const serviceModel = require('./service_model');
const clientModel = require('../client/client_model');
const twilioController = require('../twilio/twilio_controller');
const responseHandler = require('../../utils/response_handler');
const validators = require('../../utils/validators');
const uploadMiddleware = require('../../middlewares/upload_middleware');
const config = require('../../config/config');

module.exports = {
    getAllServices: async (req, res) => {
        try {
            const services = await serviceModel.getAllServices();
            return responseHandler.success(res, services, 'Servicios obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting all services:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getServiceById: async (req, res) => {
        try {
            const serviceId = req.params.id;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            return responseHandler.success(res, service, 'Servicio obtenido exitosamente');
        } catch (error) {
            console.error('Error getting service by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createService: async (req, res) => {
        try {
            const { 
                client_id, device_type, device_brand, issue_description, 
                service_type, is_warranty, original_service_id, technician_id 
            } = req.body;
            
            // Validar campos requeridos
            const validation = validators.validateRequiredFields(
                req.body,
                ['client_id', 'device_type', 'device_brand', 'issue_description', 'service_type']
            );
            
            if (!validation.valid) {
                return responseHandler.error(res, validation.message);
            }
            
            // Si es una garantía, verificar que original_service_id existe
            if (is_warranty && !original_service_id) {
                return responseHandler.error(res, 'Para servicios de garantía se requiere el ID del servicio original');
            }
            
            // Verificar que el cliente existe
            const client = await clientModel.getClientById(client_id);
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Crear el servicio
            const serviceData = {
                client_id,
                device_type,
                device_brand,
                issue_description,
                service_type,
                is_warranty: is_warranty || false,
                original_service_id: original_service_id || null,
                technician_id: technician_id || null,
                created_by: req.user.id
            };
            
            const newService = await serviceModel.createService(serviceData);
            
            if (!newService) {
                return responseHandler.error(res, 'Error al crear el servicio');
            }
            
            // Si se asignó un técnico, enviar notificación a Twilio
            if (technician_id) {
                // Aquí se implementaría la lógica para enviar notificación vía Twilio
                // twilioController.sendServiceAssignmentNotification(newService);
            }
            
            return responseHandler.success(res, newService, 'Servicio creado exitosamente', 201);
        } catch (error) {
            console.error('Error creating service:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateService: async (req, res) => {
        try {
            const serviceId = req.params.id;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const existingService = await serviceModel.getServiceById(serviceId);
            
            if (!existingService) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Extraer datos para actualización
            const { 
                device_type, device_brand, issue_description, service_type,
                status, estimated_price, final_price, is_warranty,
                original_service_id, technician_id
            } = req.body;
            
            // Preparar datos para actualizar
            const serviceData = {};
            
            if (device_type !== undefined) serviceData.device_type = device_type;
            if (device_brand !== undefined) serviceData.device_brand = device_brand;
            if (issue_description !== undefined) serviceData.issue_description = issue_description;
            if (service_type !== undefined) serviceData.service_type = service_type;
            if (status !== undefined) serviceData.status = status;
            if (estimated_price !== undefined) serviceData.estimated_price = estimated_price;
            if (final_price !== undefined) serviceData.final_price = final_price;
            if (is_warranty !== undefined) serviceData.is_warranty = is_warranty;
            if (original_service_id !== undefined) serviceData.original_service_id = original_service_id;
            if (technician_id !== undefined) serviceData.technician_id = technician_id;
            
            // Validar que si se cambia a garantía, se proporcione el ID del servicio original
            if (serviceData.is_warranty && !existingService.is_warranty && !serviceData.original_service_id && !existingService.original_service_id) {
                return responseHandler.error(res, 'Para servicios de garantía se requiere el ID del servicio original');
            }
            
            // Actualizar servicio
            const updatedService = await serviceModel.updateService(serviceId, serviceData);
            
            if (!updatedService) {
                return responseHandler.error(res, 'Error al actualizar el servicio');
            }
            
            // Si se cambió el técnico o el estado, enviar notificaciones apropiadas
            if ((technician_id !== undefined && technician_id !== existingService.technician_id) ||
                (status !== undefined && status !== existingService.status)) {
                // Aquí se implementaría la lógica para enviar notificaciones vía Twilio
                // twilioController.sendServiceUpdateNotification(updatedService);
            }
            
            // Si se completó el servicio y tiene precio final, calcular pago al técnico
            if (status === 'completed' && (final_price !== undefined || existingService.final_price) && updatedService.technician_id) {
                await serviceModel.calculateTechnicianPayment(updatedService.technician_id, serviceId);
            }
            
            return responseHandler.success(res, updatedService, 'Servicio actualizado exitosamente');
        } catch (error) {
            console.error('Error updating service:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    deleteService: async (req, res) => {
        try {
            const serviceId = req.params.id;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Verificar si hay servicios de garantía asociados a este servicio
            // Esto se haría con una consulta adicional, pero por brevedad lo omitimos aquí
            
            // Eliminar servicio
            const deleted = await serviceModel.deleteService(serviceId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar el servicio');
            }
            
            return responseHandler.success(res, null, 'Servicio eliminado exitosamente');
        } catch (error) {
            console.error('Error deleting service:', error);
            
            // Manejo de errores de integridad referencial
            if (error.code === 'ER_ROW_IS_REFERENCED') {
                return responseHandler.error(
                    res, 
                    'No se puede eliminar el servicio porque tiene garantías asociadas.',
                    400
                );
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    uploadServicePhoto: async (req, res) => {
        try {
            // El middleware de multer ya procesó la carga del archivo
            if (!req.file) {
                return responseHandler.error(res, 'No se proporcionó ningún archivo');
            }
            
            const serviceId = req.params.id;
            const photoType = req.body.photo_type;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            if (!photoType || !['before', 'after'].includes(photoType)) {
                return responseHandler.error(res, 'Tipo de foto inválido. Debe ser "before" o "after"');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                // Eliminar el archivo cargado
                fs.unlinkSync(req.file.path);
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Obtener la ruta relativa del archivo para guardar en la base de datos
            const relativePath = path.relative(path.join(__dirname, '../..'), req.file.path)
                .replace(/\\/g, '/'); // Normalizar separadores de ruta para sistemas Windows
            
            // Agregar la foto al servicio
            const photo = await serviceModel.addServicePhoto(serviceId, relativePath, photoType);
            
            if (!photo) {
                // Eliminar el archivo cargado
                fs.unlinkSync(req.file.path);
                return responseHandler.error(res, 'Error al guardar la foto');
            }
            
            // Si es la primera foto "before", actualizar el estado del servicio a "in_progress"
            if (photoType === 'before' && service.status === 'assigned') {
                await serviceModel.updateServiceStatus(serviceId, 'in_progress');
            }
            
            // Si es la primera foto "after", permitir marcar el servicio como completado
            // Esto solo es una preparación, no cambia automáticamente el estado
            
            return responseHandler.success(res, photo, 'Foto cargada exitosamente', 201);
        } catch (error) {
            console.error('Error uploading service photo:', error);
            
            // Si hay error, intentar eliminar el archivo si se cargó
            if (req.file && req.file.path) {
                try {
                    fs.unlinkSync(req.file.path);
                } catch (unlinkError) {
                    console.error('Error deleting file after upload error:', unlinkError);
                }
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    removeServicePhoto: async (req, res) => {
        try {
            const photoId = req.params.photoId;
            
            if (!photoId) {
                return responseHandler.error(res, 'ID de foto requerido');
            }
            
            // La eliminación del archivo físico se haría aquí, pero requeriría primero
            // obtener los detalles de la foto para conocer su ruta
            
            // Eliminar la foto de la base de datos
            const deleted = await serviceModel.removeServicePhoto(photoId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar la foto');
            }
            
            return responseHandler.success(res, null, 'Foto eliminada exitosamente');
        } catch (error) {
            console.error('Error removing service photo:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateServiceStatus: async (req, res) => {
        try {
            const serviceId = req.params.id;
            const { status } = req.body;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            if (!status) {
                return responseHandler.error(res, 'Estado requerido');
            }
            
            if (!['new', 'assigned', 'in_progress', 'completed', 'cancelled'].includes(status)) {
                return responseHandler.error(res, 'Estado no válido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Validar transiciones de estado
            if (status === 'assigned' && !service.technician_id) {
                return responseHandler.error(res, 'No se puede marcar como asignado sin un técnico');
            }
            
            if (status === 'in_progress' && (service.status !== 'assigned' || !service.technician_id)) {
                return responseHandler.error(res, 'Solo servicios asignados pueden pasar a en progreso');
            }
            
            if (status === 'completed') {
                // Verificar si es técnico y hay fotos de antes y después
                if (req.user.role === 'technician') {
                    if (!service.photos.before.length) {
                        return responseHandler.error(res, 'Se requieren fotos del equipo dañado antes de completar');
                    }
                    
                    if (!service.photos.after.length) {
                        return responseHandler.error(res, 'Se requieren fotos del equipo reparado antes de completar');
                    }
                    
                    if (!service.estimated_price) {
                        return responseHandler.error(res, 'Se requiere un presupuesto antes de completar');
                    }
                }
                
                if (!service.final_price) {
                    return responseHandler.error(res, 'Se requiere un precio final antes de completar');
                }
            }
            
            // Actualizar estado
            const updatedService = await serviceModel.updateServiceStatus(serviceId, status);
            
            if (!updatedService) {
                return responseHandler.error(res, 'Error al actualizar el estado del servicio');
            }
            
            // Si se completó y tiene precio final, calcular pago al técnico
            if (status === 'completed' && service.final_price && service.technician_id) {
                await serviceModel.calculateTechnicianPayment(service.technician_id, serviceId);
            }
            
            // Enviar notificación apropiada vía Twilio según el cambio de estado
            // twilioController.sendStatusUpdateNotification(updatedService);
            
            return responseHandler.success(res, updatedService, `Servicio marcado como ${status} exitosamente`);
        } catch (error) {
            console.error('Error updating service status:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    assignTechnician: async (req, res) => {
        try {
            const serviceId = req.params.id;
            const { technician_id } = req.body;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            if (!technician_id) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Verificar si el servicio ya está completado o cancelado
            if (['completed', 'cancelled'].includes(service.status)) {
                return responseHandler.error(res, 'No se puede asignar un técnico a un servicio completado o cancelado');
            }
            
            // Asignar técnico
            const updatedService = await serviceModel.assignTechnician(serviceId, technician_id);
            
            if (!updatedService) {
                return responseHandler.error(res, 'Error al asignar el técnico');
            }
            
            // Enviar notificación al técnico vía Twilio
            // twilioController.sendAssignmentNotification(updatedService);
            
            return responseHandler.success(res, updatedService, 'Técnico asignado exitosamente');
        } catch (error) {
            console.error('Error assigning technician:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateEstimatedPrice: async (req, res) => {
        try {
            const serviceId = req.params.id;
            const { price } = req.body;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            if (price === undefined || price < 0) {
                return responseHandler.error(res, 'Precio estimado inválido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Verificar si el usuario es el técnico asignado o un administrador/secretaria
            if (req.user.role === 'technician' && (!service.technician_id || req.user.technician_id !== service.technician_id)) {
                return responseHandler.forbidden(res, 'No tiene permiso para actualizar este servicio');
            }
            
            // Verificar si hay fotos de antes si el usuario es un técnico
            if (req.user.role === 'technician' && !service.photos.before.length) {
                return responseHandler.error(res, 'Debe subir fotos del equipo dañado antes de establecer el presupuesto');
            }
            
            // Actualizar precio estimado
            const updatedService = await serviceModel.updateEstimatedPrice(serviceId, price);
            
            if (!updatedService) {
                return responseHandler.error(res, 'Error al actualizar el precio estimado');
            }
            
            // Enviar notificación al cliente con el presupuesto vía Twilio
            // twilioController.sendQuoteNotification(updatedService);
            
            return responseHandler.success(res, updatedService, 'Precio estimado actualizado exitosamente');
        } catch (error) {
            console.error('Error updating estimated price:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateFinalPrice: async (req, res) => {
        try {
            const serviceId = req.params.id;
            const { price } = req.body;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            if (price === undefined || price < 0) {
                return responseHandler.error(res, 'Precio final inválido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Restricción: solo administradores y secretarias pueden establecer el precio final
            if (!['admin', 'secretary'].includes(req.user.role)) {
                return responseHandler.forbidden(res, 'No tiene permiso para establecer el precio final');
            }
            
            // Actualizar precio final
            const updatedService = await serviceModel.updateFinalPrice(serviceId, price);
            
            if (!updatedService) {
                return responseHandler.error(res, 'Error al actualizar el precio final');
            }
            
            // Si el servicio está completado y tiene técnico asignado, calcular pago
            if (service.status === 'completed' && service.technician_id) {
                await serviceModel.calculateTechnicianPayment(service.technician_id, serviceId);
            }
            
            return responseHandler.success(res, updatedService, 'Precio final actualizado exitosamente');
        } catch (error) {
            console.error('Error updating final price:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getServicesByTechnician: async (req, res) => {
        try {
            const technicianId = req.params.technicianId;
            const { status } = req.query;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Si el usuario es un técnico, solo puede ver sus propios servicios
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver servicios de otros técnicos');
            }
            
            const services = await serviceModel.getServicesByTechnician(technicianId, status);
            
            return responseHandler.success(res, services, 'Servicios del técnico obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting services by technician:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getServicesByLocation: async (req, res) => {
        try {
            const locationId = req.params.locationId;
            
            if (!locationId) {
                return responseHandler.error(res, 'ID de ubicación requerido');
            }
            
            const services = await serviceModel.getServicesByLocation(locationId);
            
            return responseHandler.success(res, services, 'Servicios por ubicación obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting services by location:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getServicesByStatus: async (req, res) => {
        try {
            const { status } = req.params;
            
            if (!status || !['new', 'assigned', 'in_progress', 'completed', 'cancelled'].includes(status)) {
                return responseHandler.error(res, 'Estado no válido');
            }
            
            const services = await serviceModel.getServicesByStatus(status);
            
            return responseHandler.success(res, services, `Servicios en estado ${status} obtenidos exitosamente`);
        } catch (error) {
            console.error('Error getting services by status:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getWarrantyServices: async (req, res) => {
        try {
            const services = await serviceModel.getWarrantyServices();
            
            return responseHandler.success(res, services, 'Servicios de garantía obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting warranty services:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getServiceStatistics: async (req, res) => {
        try {
            const statistics = await serviceModel.getServiceStatistics();
            
            return responseHandler.success(res, statistics, 'Estadísticas de servicios obtenidas exitosamente');
        } catch (error) {
            console.error('Error getting service statistics:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    searchServices: async (req, res) => {
        try {
            const { term } = req.query;
            
            if (!term) {
                return responseHandler.error(res, 'Término de búsqueda requerido');
            }
            
            const services = await serviceModel.searchServices(term);
            
            return responseHandler.success(res, services, 'Búsqueda de servicios exitosa');
        } catch (error) {
            console.error('Error searching services:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createWarrantyService: async (req, res) => {
        try {
            const { original_service_id } = req.body;
            
            if (!original_service_id) {
                return responseHandler.error(res, 'ID del servicio original requerido');
            }
            
            // Verificar si el servicio original existe
            const originalService = await serviceModel.getServiceById(original_service_id);
            
            if (!originalService) {
                return responseHandler.notFound(res, 'Servicio original no encontrado');
            }
            
            // Verificar si el servicio original está completado
            if (originalService.status !== 'completed') {
                return responseHandler.error(res, 'Solo se pueden crear garantías para servicios completados');
            }
            
            // Crear servicio de garantía
            const warrantyData = {
                client_id: originalService.client_id,
                device_type: originalService.device_type,
                device_brand: originalService.device_brand,
                issue_description: `Garantía del servicio #${original_service_id}: ${originalService.issue_description}`,
                service_type: originalService.service_type,
                is_warranty: true,
                original_service_id: original_service_id,
                technician_id: originalService.technician_id, // Asignar al mismo técnico
                created_by: req.user.id
            };
            
            const newWarrantyService = await serviceModel.createService(warrantyData);
            
            if (!newWarrantyService) {
                return responseHandler.error(res, 'Error al crear el servicio de garantía');
            }
            
            // Enviar notificación al técnico vía Twilio
            // twilioController.sendWarrantyNotification(newWarrantyService);
            
            return responseHandler.success(
                res,
                newWarrantyService,
                'Servicio de garantía creado exitosamente',
                201
            );
        } catch (error) {
            console.error('Error creating warranty service:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getAvailableTechnicians: async (req, res) => {
        try {
            const { location_id } = req.query;
            
            let technicians;
            
            if (location_id) {
                technicians = await serviceModel.getAvailableTechniciansByLocation(location_id);
            } else {
                technicians = await serviceModel.getAllAvailableTechnicians();
            }
            
            return responseHandler.success(res, technicians, 'Técnicos disponibles obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting available technicians:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    calculateTechnicianPayment: async (req, res) => {
        try {
            const serviceId = req.params.id;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            if (!service.technician_id) {
                return responseHandler.error(res, 'El servicio no tiene técnico asignado');
            }
            
            if (service.status !== 'completed') {
                return responseHandler.error(res, 'Solo se puede calcular el pago para servicios completados');
            }
            
            if (!service.final_price) {
                return responseHandler.error(res, 'El servicio no tiene precio final establecido');
            }
            
            // Calcular pago
            const payment = await serviceModel.calculateTechnicianPayment(service.technician_id, serviceId);
            
            if (!payment) {
                return responseHandler.error(res, 'Error al calcular el pago');
            }
            
            return responseHandler.success(res, payment, 'Pago calculado exitosamente');
        } catch (error) {
            console.error('Error calculating technician payment:', error);
            return responseHandler.serverError(res, error);
        }
    }
};