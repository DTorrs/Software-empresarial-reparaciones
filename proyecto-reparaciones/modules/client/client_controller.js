const clientModel = require('./client_model');
const responseHandler = require('../../utils/response_handler');
const validators = require('../../utils/validators');

module.exports = {
    getAllClients: async (req, res) => {
        try {
            const clients = await clientModel.getAllClients();
            return responseHandler.success(res, clients, 'Clientes obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting all clients:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getClientById: async (req, res) => {
        try {
            const clientId = req.params.id;
            
            if (!clientId) {
                return responseHandler.error(res, 'ID de cliente requerido');
            }
            
            const client = await clientModel.getClientById(clientId);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            return responseHandler.success(res, client, 'Cliente obtenido exitosamente');
        } catch (error) {
            console.error('Error getting client by ID:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    createClient: async (req, res) => {
        try {
            console.log("Petición recibida para crear cliente:", req.body);
            
            const { name, phone, email, address, location_id } = req.body;
            
            // Validar campos requeridos
            if (!name || !phone || !address || !location_id) {
                return responseHandler.error(res, 'Nombre, teléfono, dirección y ubicación son campos requeridos');
            }
            
            // Crear cliente con manejo de errores específicos
            try {
                const newClient = await clientModel.createClient({
                    name, phone, email, address, location_id
                });
                
                if (!newClient) {
                    return responseHandler.error(res, 'Error al crear el cliente');
                }
                
                return responseHandler.success(res, newClient, 'Cliente creado exitosamente', 201);
            } catch (modelError) {
                console.error("Error específico al crear cliente:", modelError);
                return responseHandler.error(res, `Error específico: ${modelError.message}`, 400);
            }
        } catch (error) {
            console.error('Error general en createClient controller:', error);
            return responseHandler.serverError(res, `Detalle: ${error.message}`);
        }
    },
    
    updateClient: async (req, res) => {
        try {
            const clientId = req.params.id;
            
            if (!clientId) {
                return responseHandler.error(res, 'ID de cliente requerido');
            }
            
            // Verificar si el cliente existe
            const existingClient = await clientModel.getClientById(clientId);
            
            if (!existingClient) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            const { name, phone, email, address, location_id } = req.body;
            
            // Validar teléfono si está presente
            if (phone && !validators.validatePhone(phone)) {
                return responseHandler.error(res, 'Formato de teléfono inválido. Debe ser de 10 dígitos.');
            }
            
            // Validar email si está presente
            if (email && !validators.validateEmail(email)) {
                return responseHandler.error(res, 'Formato de email inválido');
            }
            
            // Verificar si el nuevo teléfono ya existe para otro cliente
            if (phone && phone !== existingClient.phone) {
                const clientWithPhone = await clientModel.findClientByPhone(phone);
                if (clientWithPhone && clientWithPhone.id !== parseInt(clientId)) {
                    return responseHandler.error(res, `Ya existe un cliente con este teléfono: ${clientWithPhone.name}`);
                }
            }
            
            // Preparar datos para actualizar
            const clientData = {};
            if (name !== undefined) clientData.name = name;
            if (phone !== undefined) clientData.phone = phone;
            if (email !== undefined) clientData.email = email;
            if (address !== undefined) clientData.address = address;
            if (location_id !== undefined) clientData.location_id = location_id;
            
            // Actualizar cliente
            const updatedClient = await clientModel.updateClient(clientId, clientData);
            
            if (!updatedClient) {
                return responseHandler.error(res, 'Error al actualizar el cliente');
            }
            
            return responseHandler.success(res, updatedClient, 'Cliente actualizado exitosamente');
        } catch (error) {
            console.error('Error updating client:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    deleteClient: async (req, res) => {
        try {
            const clientId = req.params.id;
            
            if (!clientId) {
                return responseHandler.error(res, 'ID de cliente requerido');
            }
            
            // Verificar si el cliente existe
            const client = await clientModel.getClientById(clientId);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Eliminar cliente
            const deleted = await clientModel.deleteClient(clientId);
            
            if (!deleted) {
                return responseHandler.error(res, 'Error al eliminar el cliente');
            }
            
            return responseHandler.success(res, null, 'Cliente eliminado exitosamente');
        } catch (error) {
            console.error('Error deleting client:', error);
            
            // Manejo de errores de integridad referencial
            if (error.code === 'ER_ROW_IS_REFERENCED') {
                return responseHandler.error(
                    res, 
                    'No se puede eliminar el cliente porque tiene servicios asociados.',
                    400
                );
            }
            
            return responseHandler.serverError(res, error);
        }
    },
    
    getClientServiceHistory: async (req, res) => {
        try {
            const clientId = req.params.id;
            
            if (!clientId) {
                return responseHandler.error(res, 'ID de cliente requerido');
            }
            
            // Verificar si el cliente existe
            const client = await clientModel.getClientById(clientId);
            
            if (!client) {
                return responseHandler.notFound(res, 'Cliente no encontrado');
            }
            
            // Obtener historial de servicios
            const serviceHistory = await clientModel.getClientServiceHistory(clientId);
            
            return responseHandler.success(res, serviceHistory, 'Historial de servicios obtenido exitosamente');
        } catch (error) {
            console.error('Error getting client service history:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    getClientsByLocation: async (req, res) => {
        try {
            const locationId = req.params.locationId;
            
            if (!locationId) {
                return responseHandler.error(res, 'ID de ubicación requerido');
            }
            
            const clients = await clientModel.getClientsByLocation(locationId);
            
            return responseHandler.success(res, clients, 'Clientes por ubicación obtenidos exitosamente');
        } catch (error) {
            console.error('Error getting clients by location:', error);
            return responseHandler.serverError(res, error);
        }
    },
    
    searchClients: async (req, res) => {
        try {
            const { term } = req.query;
            
            if (!term) {
                return responseHandler.error(res, 'Término de búsqueda requerido');
            }
            
            const clients = await clientModel.searchClients(term);
            
            return responseHandler.success(res, clients, 'Búsqueda de clientes exitosa');
        } catch (error) {
            console.error('Error searching clients:', error);
            return responseHandler.serverError(res, error);
        }
    }
};