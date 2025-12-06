const twilioModel = require('./twilio_model');
const serviceModel = require('../service/service_model');
const clientModel = require('../client/client_model');
const config = require('../../config/config');
const twilioConfig = require('../../config/twilio');
const responseHandler = require('../../utils/response_handler');
const encryption = require('../../utils/encryption');

module.exports = {
    getAllMessages: async (req, res) => {
        try {
            const messages = await twilioModel.getAllMessages();
            return responseHandler.success(res, messages, 'Mensajes de Twilio obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting all Twilio messages:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getMessageById: async (req, res) => {
        try {
            const messageId = req.params.id;
            
            if (!messageId) {
                return responseHandler.error(res, 'ID de mensaje requerido');
            }
            
            const message = await twilioModel.getMessageById(messageId);
            
            if (!message) {
                return responseHandler.notFound(res, 'Mensaje no encontrado');
            }
            
            return responseHandler.success(res, message, 'Mensaje obtenido exitosamente');
        } catch (error) {
            console.error('Error getting Twilio message by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getMessagesByService: async (req, res) => {
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
            
            const messages = await twilioModel.getMessagesByService(serviceId);
            
            return responseHandler.success(res, messages, 'Mensajes del servicio obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting Twilio messages by service:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createMessage: async (req, res) => {
        try {
            const { service_id, message_type, message_content } = req.body;
            
            // Validar campos requeridos
            if (!service_id || !message_type || !message_content) {
                return responseHandler.error(res, 'ID de servicio, tipo de mensaje y contenido son requeridos');
            }
            
            // Verificar tipo de mensaje válido
            if (!['welcome', 'quote', 'reminder', 'completion'].includes(message_type)) {
                return responseHandler.error(res, 'Tipo de mensaje no válido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Crear mensaje
            const messageData = {
                service_id,
                message_type,
                message_content,
                status: 'pending'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            
            if (!newMessage) {
                return responseHandler.error(res, 'Error al crear el mensaje');
            }
            
            return responseHandler.success(res, newMessage, 'Mensaje creado exitosamente', 201);
        } catch (error) {
            console.error('Error creating Twilio message:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    updateMessageStatus: async (req, res) => {
        try {
            const messageId = req.params.id;
            const { status, sent_at } = req.body;
            
            if (!messageId) {
                return responseHandler.error(res, 'ID de mensaje requerido');
            }
            
            if (!status || !['pending', 'sent', 'failed'].includes(status)) {
                return responseHandler.error(res, 'Estado no válido');
            }
            
            // Verificar si el mensaje existe
            const message = await twilioModel.getMessageById(messageId);
            
            if (!message) {
                return responseHandler.notFound(res, 'Mensaje no encontrado');
            }
            
            // Actualizar estado
            const updatedMessage = await twilioModel.updateMessageStatus(messageId, status, sent_at);
            
            if (!updatedMessage) {
                return responseHandler.error(res, 'Error al actualizar el estado del mensaje');
            }
            
            return responseHandler.success(res, updatedMessage, 'Estado del mensaje actualizado exitosamente');
        } catch (error) {
            console.error('Error updating Twilio message status:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    deleteMessage: async (req, res) => {
        try {
            const messageId = req.params.id;
            
            if (!messageId) {
                return responseHandler.error(res, 'ID de mensaje requerido');
            }
            
            // Verificar si el mensaje existe
            const message = await twilioModel.getMessageById(messageId);
            
            if (!message) {
                return responseHandler.notFound(res, 'Mensaje no encontrado');
            }
            
            // Eliminar mensaje
            const deleted = await twilioModel.deleteMessage(messageId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar el mensaje');
            }
            
            return responseHandler.success(res, null, 'Mensaje eliminado exitosamente');
        } catch (error) {
            console.error('Error deleting Twilio message:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getPendingMessages: async (req, res) => {
        try {
            const limit = req.query.limit ? parseInt(req.query.limit) : 10;
            
            const pendingMessages = await twilioModel.getPendingMessages(limit);
            
            return responseHandler.success(res, pendingMessages, 'Mensajes pendientes obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting pending Twilio messages:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getMessageStatistics: async (req, res) => {
        try {
            const statistics = await twilioModel.getMessageStatistics();
            
            return responseHandler.success(res, statistics, 'Estadísticas de mensajes obtenidas exitosamente');
        } catch (error) {
            console.error('Error getting Twilio message statistics:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    // Métodos para enviar mensajes específicos
    sendWelcomeMessage: async (req, res) => {
        try {
            const { service_id } = req.body;
            
            if (!service_id) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Obtener información del cliente
            const client = await clientModel.getClientById(service.client_id);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Construir mensaje de bienvenida
            const messageContent = `¡Hola ${client.name}! Bienvenido a nuestro servicio de reparación. ` +
                `Hemos registrado tu solicitud para tu ${service.device_type} ${service.device_brand}. ` +
                `Tu número de servicio es: #${service_id}. ` +
                `Te mantendremos informado sobre el proceso de reparación. ` +
                `¡Gracias por confiar en nosotros!`;
            
            // Crear registro de mensaje
            const messageData = {
                service_id,
                message_type: 'welcome',
                message_content,
                status: 'pending'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            
            if (!newMessage) {
                return responseHandler.error(res, 'Error al crear el mensaje de bienvenida');
            }
            
            // Opcional: Enviar inmediatamente el mensaje usando Twilio
            const sendResult = await this.processSendMessage(newMessage.id);
            
            return responseHandler.success(
                res, 
                { message: newMessage, send_result: sendResult }, 
                'Mensaje de bienvenida creado exitosamente',
                201
            );
        } catch (error) {
            console.error('Error sending welcome message:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    sendQuoteMessage: async (req, res) => {
        try {
            const { service_id } = req.body;
            
            if (!service_id) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            if (!service.estimated_price) {
                return responseHandler.error(res, 'El servicio no tiene un presupuesto establecido');
            }
            
            // Obtener información del cliente
            const client = await clientModel.getClientById(service.client_id);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Construir mensaje de presupuesto
            const messageContent = `Hola ${client.name}, el presupuesto para reparar tu ${service.device_type} ${service.device_brand} es de $${service.estimated_price}. ` +
                `Problema: ${service.issue_description}. ` +
                `Por favor, confirma si deseas que procedamos con la reparación. ` +
                `Para pagar, puedes realizar un depósito o transferencia a las siguientes cuentas: [DATOS DE CUENTAS]. ` +
                `Recuerda que si realizas el pago directamente con nosotros, obtendrás beneficios exclusivos como mantenimientos gratuitos o descuentos en futuras reparaciones. ` +
                `Tu número de servicio es: #${service_id}.`;
            
            // Crear registro de mensaje
            const messageData = {
                service_id,
                message_type: 'quote',
                message_content,
                status: 'pending'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            
            if (!newMessage) {
                return responseHandler.error(res, 'Error al crear el mensaje de presupuesto');
            }
            
            // Opcional: Enviar inmediatamente el mensaje usando Twilio
            const sendResult = await this.processSendMessage(newMessage.id);
            
            return responseHandler.success(
                res, 
                { message: newMessage, send_result: sendResult }, 
                'Mensaje de presupuesto creado exitosamente',
                201
            );
        } catch (error) {
            console.error('Error sending quote message:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    sendCompletionMessage: async (req, res) => {
        try {
            const { service_id } = req.body;
            
            if (!service_id) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            if (service.status !== 'completed') {
                return responseHandler.error(res, 'El servicio no está marcado como completado');
            }
            
            // Obtener información del cliente
            const client = await clientModel.getClientById(service.client_id);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Construir mensaje de finalización
            const messageContent = `¡Buenas noticias ${client.name}! Tu ${service.device_type} ${service.device_brand} ha sido reparado satisfactoriamente. ` +
                `Puedes pasar a recogerlo en [DIRECCIÓN DE RECOGIDA] o podemos coordinar la entrega. ` +
                `Tu número de servicio es: #${service_id}. Guárdalo para cualquier consulta futura. ` +
                `Recuerda que todos nuestros servicios incluyen garantía. Si tienes algún problema, contáctanos mencionando tu número de servicio. ` +
                `¡Gracias por confiar en nosotros!`;
            
            // Crear registro de mensaje
            const messageData = {
                service_id,
                message_type: 'completion',
                message_content,
                status: 'pending'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            
            if (!newMessage) {
                return responseHandler.error(res, 'Error al crear el mensaje de finalización');
            }
            
            // Opcional: Enviar inmediatamente el mensaje usando Twilio
            const sendResult = await this.processSendMessage(newMessage.id);
            
            return responseHandler.success(
                res, 
                { message: newMessage, send_result: sendResult }, 
                'Mensaje de finalización creado exitosamente',
                201
            );
        } catch (error) {
            console.error('Error sending completion message:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    sendPaymentReminder: async (req, res) => {
        try {
            const { service_id } = req.body;
            
            if (!service_id) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            if (!service.estimated_price && !service.final_price) {
                return responseHandler.error(res, 'El servicio no tiene un precio establecido');
            }
            
            const price = service.final_price || service.estimated_price;
            
            // Obtener información del cliente
            const client = await clientModel.getClientById(service.client_id);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Construir mensaje de recordatorio de pago
            const messageContent = `Hola ${client.name}, te recordamos que el costo de la reparación de tu ${service.device_type} ${service.device_brand} es de $${price}. ` +
                `Para aprovechar nuestros beneficios exclusivos como mantenimientos gratuitos o descuentos en futuras reparaciones, te recomendamos realizar el pago directamente a nuestras cuentas: [DATOS DE CUENTAS]. ` +
                `Tu número de servicio es: #${service_id}. ` +
                `Si ya realizaste el pago, por favor ignora este mensaje. ` +
                `¡Gracias por tu preferencia!`;
            
            // Crear registro de mensaje
            const messageData = {
                service_id,
                message_type: 'reminder',
                message_content,
                status: 'pending'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            
            if (!newMessage) {
                return responseHandler.error(res, 'Error al crear el recordatorio de pago');
            }
            
            // Opcional: Enviar inmediatamente el mensaje usando Twilio
            const sendResult = await this.processSendMessage(newMessage.id);
            
            return responseHandler.success(
                res, 
                { message: newMessage, send_result: sendResult }, 
                'Recordatorio de pago creado exitosamente',
                201
            );
        } catch (error) {
            console.error('Error sending payment reminder:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    sendWarrantyNotification: async (req, res) => {
        try {
            const { service_id } = req.body;
            
            if (!service_id) {
                return responseHandler.error(res, 'ID de servicio requerido');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            if (!service.is_warranty) {
                return responseHandler.error(res, 'El servicio no es una garantía');
            }
            
            // Obtener información del cliente
            const client = await clientModel.getClientById(service.client_id);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Construir mensaje de notificación de garantía
            const messageContent = `Hola ${client.name}, hemos registrado tu solicitud de garantía para tu ${service.device_type} ${service.device_brand}. ` +
                `Un técnico se pondrá en contacto contigo pronto para coordinar la visita. ` +
                `Tu número de servicio de garantía es: #${service_id}, asociado al servicio original #${service.original_service_id}. ` +
                `Recuerda que nuestras garantías cubren solo problemas relacionados con la reparación original. ` +
                `¡Gracias por tu confianza!`;
            
            // Crear registro de mensaje
            const messageData = {
                service_id,
                message_type: 'welcome', // Se usa el tipo 'welcome' para garantías también
                message_content,
                status: 'pending'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            
            if (!newMessage) {
                return responseHandler.error(res, 'Error al crear la notificación de garantía');
            }
            
            // Opcional: Enviar inmediatamente el mensaje usando Twilio
            const sendResult = await this.processSendMessage(newMessage.id);
            
            return responseHandler.success(
                res, 
                { message: newMessage, send_result: sendResult }, 
                'Notificación de garantía creada exitosamente',
                201
            );
        } catch (error) {
            console.error('Error sending warranty notification:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    // Método para enviar mensajes pendientes (para usar en un cron job)
    sendPendingMessages: async (req, res) => {
        try {
            const limit = req.query.limit ? parseInt(req.query.limit) : 10;
            
            const pendingMessages = await twilioModel.getPendingMessages(limit);
            
            if (pendingMessages.length === 0) {
                return responseHandler.success(res, [], 'No hay mensajes pendientes para enviar');
            }
            
            const results = [];
            
            // Enviar cada mensaje pendiente
            for (const message of pendingMessages) {
                try {
                    // Enviar el mensaje
                    const result = await this.processSendMessage(message.id);
                    results.push({ messageId: message.id, result });
                } catch (sendError) {
                    console.error(`Error sending message ${message.id}:`, sendError);
                    results.push({ messageId: message.id, error: sendError.message });
                    
                    // Marcar el mensaje como fallido
                    await twilioModel.updateMessageStatus(message.id, 'failed');
                }
            }
            
            return responseHandler.success(
                res, 
                { processed: results.length, results }, 
                'Procesamiento de mensajes pendientes completado'
            );
        } catch (error) {
            console.error('Error sending pending messages:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    // Método interno para procesar el envío de un mensaje
    processSendMessage: async (messageId) => {
        try {
            // Obtener detalles del mensaje
            const message = await twilioModel.getMessageById(messageId);
            
            if (!message) {
                throw new Error('Mensaje no encontrado');
            }
            
            if (message.status === 'sent') {
                return { status: 'already_sent', messageId };
            }
            
            // Enviar mensaje usando Twilio
            const sendResult = await twilioConfig.sendWhatsAppMessage(
                message.client_phone,
                message.message_content
            );
            
            if (sendResult.success) {
                // Actualizar estado del mensaje a enviado
                await twilioModel.updateMessageStatus(messageId, 'sent');
                return { status: 'sent', messageId, twilioMessageId: sendResult.messageId };
            } else {
                // Actualizar estado del mensaje a fallido
                await twilioModel.updateMessageStatus(messageId, 'failed');
                return { status: 'failed', messageId, error: sendResult.error };
            }
        } catch (error) {
            console.error(`Error processing send message ${messageId}:`, error);
            // Actualizar estado del mensaje a fallido
            await twilioModel.updateMessageStatus(messageId, 'failed');
            throw error;
        }
    },
    
    // Método para comunicación anónima entre técnico y cliente
    sendAnonymousMessage: async (req, res) => {
        try {
            const { service_id, message } = req.body;
            
            if (!service_id || !message) {
                return responseHandler.error(res, 'ID de servicio y mensaje son requeridos');
            }
            
            // Verificar si el servicio existe
            const service = await serviceModel.getServiceById(service_id);
            
            if (!service) {
                return responseHandler.notFound(res, 'Servicio no encontrado');
            }
            
            // Verificar si el usuario es el técnico asignado
            if (req.user.role === 'technician' && req.user.technician_id != service.technician_id) {
                return responseHandler.forbidden(res, 'No tiene permiso para enviar mensajes para este servicio');
            }
            
            // Obtener información del cliente
            const client = await clientModel.getClientById(service.client_id);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Preparar mensaje con información del técnico
            const technicianName = service.technician_name || 'El técnico';
            const prefixedMessage = `[${technicianName} - Servicio #${service_id}]: ${message}`;
            
            // Enviar mensaje a través de Twilio
            const sendResult = await twilioConfig.sendWhatsAppMessage(
                client.phone,
                prefixedMessage
            );
            
            if (!sendResult.success) {
                return responseHandler.error(res, `Error al enviar el mensaje: ${sendResult.error}`);
            }
            
            // Guardar el registro del mensaje enviado
            const messageData = {
                service_id,
                message_type: 'technician_message',
                message_content: prefixedMessage,
                status: 'sent'
            };
            
            const newMessage = await twilioModel.createMessage(messageData);
            await twilioModel.updateMessageStatus(newMessage.id, 'sent');
            
            return responseHandler.success(
                res, 
                { messageId: newMessage.id, twilioMessageId: sendResult.messageId }, 
                'Mensaje enviado exitosamente de forma anónima',
                200
            );
        } catch (error) {
            console.error('Error sending anonymous message:', error);
            return responseHandler.serverError(res, error);
        }
    }
};