const paymentModel = require('./payment_model');
const serviceModel = require('../service/service_model');
const technicianModel = require('../technician/technician_model');
const responseHandler = require('../../utils/response_handler');

module.exports = {
    getAllPaymentCalculations: async (req, res) => {
        try {
            const payments = await paymentModel.getAllPaymentCalculations();
            return responseHandler.success(res, payments, 'Cálculos de pago obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting all payment calculations:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getPaymentCalculationById: async (req, res) => {
        try {
            const paymentId = req.params.id;
            
            if (!paymentId) {
                return responseHandler.error(res, 'ID de pago requerido');
            }
            
            const payment = await paymentModel.getPaymentCalculationById(paymentId);
            
            if (!payment) {
                return responseHandler.notFound(res, 'Cálculo de pago no encontrado');
            }
            
            return responseHandler.success(res, payment, 'Cálculo de pago obtenido exitosamente');
        } catch (error) {
            console.error('Error getting payment calculation by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getPaymentsByTechnician: async (req, res) => {
        try {
            const technicianId = req.params.technicianId;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Si el usuario es técnico, solo puede ver sus propios pagos
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver los pagos de otros técnicos');
            }
            
            const payments = await paymentModel.getPaymentsByTechnician(technicianId);
            
            return responseHandler.success(res, payments, 'Pagos del técnico obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting payments by technician:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getPaymentsByDateRange: async (req, res) => {
        try {
            const { startDate, endDate } = req.query;
            
            if (!startDate || !endDate) {
                return responseHandler.error(res, 'Fecha de inicio y fin requeridas');
            }
            
            const payments = await paymentModel.getPaymentsByDateRange(startDate, endDate);
            
            return responseHandler.success(res, payments, 'Pagos por rango de fechas obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting payments by date range:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    calculatePaymentForService: async (req, res) => {
        try {
            const serviceId = req.params.serviceId;
            
            if (!serviceId) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(serviceId);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            if (service.status !== 'completed') {
                return responseHandler.error(res, 'Solo se puede calcular el pago para servicios completados');
            }
            
            if (!service.final_price) {
                return responseHandler.error(res, 'El servicio no tiene precio final establecido');
            }
            
            const payment = await paymentModel.calculatePaymentForService(serviceId);
            
            if (!payment) {
                return responseHandler.error(res, 'Error al calcular el pago');
            }
            
            return responseHandler.success(res, payment, 'Pago calculado exitosamente');
        } catch (error) {
            console.error('Error calculating payment for service:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    recalculateAllPayments: async (req, res) => {
        try {
            // Esta operación solo debe ser ejecutada por administradores
            if (req.user.role !== 'admin') {
                return responseHandler.forbidden(res, 'Solo administradores pueden recalcular todos los pagos');
            }
            
            const results = await paymentModel.recalculateAllPayments();
            
            return responseHandler.success(
                res, 
                { count: results.length, payments: results }, 
                'Pagos recalculados exitosamente'
            );
        } catch (error) {
            console.error('Error recalculating all payments:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getTechnicianPaymentSummary: async (req, res) => {
        try {
            const technicianId = req.params.technicianId;
            
            if (!technicianId) {
                return responseHandler.error(res, 'ID de técnico requerido');
            }
            
            // Verificar si el técnico existe
            const technician = await technicianModel.getTechnicianById(technicianId);
            
            if (!technician) {
                return responseHandler.notFound(res, 'Técnico no encontrado');
            }
            
            // Si el usuario es técnico, solo puede ver su propio resumen
            if (req.user.role === 'technician' && req.user.technician_id != technicianId) {
                return responseHandler.forbidden(res, 'No tiene permiso para ver el resumen de pagos de otros técnicos');
            }
            
            const summary = await paymentModel.getTechnicianPaymentSummary(technicianId);
            
            return responseHandler.success(res, summary, 'Resumen de pagos del técnico obtenido exitosamente');
        } catch (error) {
            console.error('Error getting technician payment summary:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getPaymentStatistics: async (req, res) => {
        try {
            const statistics = await paymentModel.getPaymentStatistics();
            
            return responseHandler.success(res, statistics, 'Estadísticas de pagos obtenidas exitosamente');
        } catch (error) {
            console.error('Error getting payment statistics:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getMyPayments: async (req, res) => {
        try {
            // Solo para técnicos
            if (req.user.role !== 'technician') {
                return responseHandler.forbidden(res, 'Esta ruta es solo para técnicos');
            }
            
            const technicianId = req.user.technician_id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'No tiene un perfil de técnico asociado');
            }
            
            const payments = await paymentModel.getPaymentsByTechnician(technicianId);
            
            return responseHandler.success(res, payments, 'Mis pagos obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting own payments:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getMyPaymentSummary: async (req, res) => {
        try {
            // Solo para técnicos
            if (req.user.role !== 'technician') {
                return responseHandler.forbidden(res, 'Esta ruta es solo para técnicos');
            }
            
            const technicianId = req.user.technician_id;
            
            if (!technicianId) {
                return responseHandler.error(res, 'No tiene un perfil de técnico asociado');
            }
            
            const summary = await paymentModel.getTechnicianPaymentSummary(technicianId);
            
            return responseHandler.success(res, summary, 'Mi resumen de pagos obtenido exitosamente');
        } catch (error) {
            console.error('Error getting own payment summary:', error);
            return responseHandler.serverError(res, error);
        }
    }
};