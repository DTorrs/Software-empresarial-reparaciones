const pool = require('../../config/database');
const encryption = require('../../utils/encryption');

module.exports = {
    getAllClients: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT c.id, c.name, c.email, l.name as location_name, c.created_at, c.updated_at ' +
                'FROM clients c ' +
                'JOIN locations l ON c.location_id = l.id ' +
                'ORDER BY c.name'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all clients:', error);
            throw error;
        }
    },
    
    getClientById: async (clientId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT c.id, c.name, c.email, c.phone_encrypted, c.phone_iv, ' +
                'c.address_encrypted, c.address_iv, c.location_id, l.name as location_name, ' +
                'c.created_at, c.updated_at ' +
                'FROM clients c ' +
                'JOIN locations l ON c.location_id = l.id ' +
                'WHERE c.id = ?',
                [clientId]
            );
            
            if (!rows.length) return null;
            
            const client = rows[0];
            
            // Desencriptar teléfono y dirección solo para visualización interna
            client.phone = encryption.decrypt(client.phone_encrypted, client.phone_iv);
            client.address = encryption.decrypt(client.address_encrypted, client.address_iv);
            
            // Eliminar datos encriptados y IVs de la respuesta
            delete client.phone_encrypted;
            delete client.phone_iv;
            delete client.address_encrypted;
            delete client.address_iv;
            
            return client;
        } catch (error) {
            console.error('Error getting client by ID:', error);
            throw error;
        }
    },
    
    createClient: async (clientData) => {
        try {
            const { name, phone, email, address, location_id } = clientData;
            
            console.log("Datos recibidos:", clientData);
            console.log("Encryption key length:", require('../../config/config').encryptionKey.length);
            
            // Encriptar teléfono
            let phoneEncryption;
            try {
                phoneEncryption = encryption.encrypt(phone);
                console.log("Teléfono encriptado exitosamente");
            } catch (encryptError) {
                console.error("Error encriptando teléfono:", encryptError);
                throw new Error(`Error de encriptación para teléfono: ${encryptError.message}`);
            }
            
            // Encriptar dirección
            let addressEncryption;
            try {
                addressEncryption = encryption.encrypt(address);
                console.log("Dirección encriptada exitosamente");
            } catch (encryptError) {
                console.error("Error encriptando dirección:", encryptError);
                throw new Error(`Error de encriptación para dirección: ${encryptError.message}`);
            }
            
            console.log("Preparando consulta SQL");
            
            try {
                const [result] = await pool.execute(
                    'INSERT INTO clients (name, phone_encrypted, phone_iv, email, address_encrypted, address_iv, location_id) ' +
                    'VALUES (?, ?, ?, ?, ?, ?, ?)',
                    [
                        name,
                        phoneEncryption.encryptedData,
                        phoneEncryption.iv,
                        email || null,
                        addressEncryption.encryptedData,
                        addressEncryption.iv,
                        location_id
                    ]
                );
                
                console.log("Cliente insertado con ID:", result.insertId);
                
                if (result.insertId) {
                    return { 
                        id: result.insertId,
                        name,
                        phone,
                        email,
                        address,
                        location_id
                    };
                }
            } catch (dbError) {
                console.error("Error en la consulta SQL:", dbError);
                throw new Error(`Error de base de datos: ${dbError.message}`);
            }
            
            return null;
        } catch (error) {
            console.error('Error completo en createClient:', error);
            throw error;
        }
    },
    
    updateClient: async (clientId, clientData) => {
        try {
            const updates = [];
            const params = [];
            
            // Preparar actualizaciones para cada campo
            if (clientData.name !== undefined) {
                updates.push('name = ?');
                params.push(clientData.name);
            }
            
            if (clientData.email !== undefined) {
                updates.push('email = ?');
                params.push(clientData.email || null);
            }
            
            if (clientData.location_id !== undefined) {
                updates.push('location_id = ?');
                params.push(clientData.location_id);
            }
            
            // Manejar encriptación de teléfono si se proporciona
            if (clientData.phone !== undefined) {
                const phoneEncryption = encryption.encrypt(clientData.phone);
                updates.push('phone_encrypted = ?');
                params.push(phoneEncryption.encryptedData);
                updates.push('phone_iv = ?');
                params.push(phoneEncryption.iv);
            }
            
            // Manejar encriptación de dirección si se proporciona
            if (clientData.address !== undefined) {
                const addressEncryption = encryption.encrypt(clientData.address);
                updates.push('address_encrypted = ?');
                params.push(addressEncryption.encryptedData);
                updates.push('address_iv = ?');
                params.push(addressEncryption.iv);
            }
            
            // Verificar si hay actualizaciones
            if (updates.length === 0) {
                return await this.getClientById(clientId);
            }
            
            // Agregar el ID del cliente a los parámetros
            params.push(clientId);
            
            const [result] = await pool.execute(
                `UPDATE clients SET ${updates.join(', ')} WHERE id = ?`,
                params
            );
            
            if (result.affectedRows > 0) {
                return await this.getClientById(clientId);
            }
            
            return null;
        } catch (error) {
            console.error('Error updating client:', error);
            throw error;
        }
    },
    
    deleteClient: async (clientId) => {
        try {
            const [result] = await pool.execute(
                'DELETE FROM clients WHERE id = ?',
                [clientId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error deleting client:', error);
            throw error;
        }
    },
    
    findClientByPhone: async (phone) => {
        try {
            // No podemos buscar directamente por teléfono encriptado
            // Obtenemos todos los clientes y filtramos programáticamente
            const [rows] = await pool.execute(
                'SELECT id, name, phone_encrypted, phone_iv FROM clients'
            );
            
            // Buscar coincidencias desencriptando
            for (const client of rows) {
                const decryptedPhone = encryption.decrypt(client.phone_encrypted, client.phone_iv);
                if (decryptedPhone === phone) {
                    return {
                        id: client.id,
                        name: client.name,
                        phone: decryptedPhone
                    };
                }
            }
            
            return null;
        } catch (error) {
            console.error('Error finding client by phone:', error);
            throw error;
        }
    },
    
    getClientsByLocation: async (locationId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT c.id, c.name, c.email, l.name as location_name, c.created_at, c.updated_at ' +
                'FROM clients c ' +
                'JOIN locations l ON c.location_id = l.id ' +
                'WHERE c.location_id = ? ' +
                'ORDER BY c.name',
                [locationId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting clients by location:', error);
            throw error;
        }
    },
    
    getClientServiceHistory: async (clientId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                's.assigned_date, s.completed_date, u.name as technician_name ' +
                'FROM services s ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'WHERE s.client_id = ? ' +
                'ORDER BY s.created_at DESC',
                [clientId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting client service history:', error);
            throw error;
        }
    },
    
    getClientCount: async () => {
        try {
            const [rows] = await pool.execute('SELECT COUNT(*) as count FROM clients');
            return rows[0].count;
        } catch (error) {
            console.error('Error getting client count:', error);
            throw error;
        }
    },
    
    searchClients: async (searchTerm) => {
        try {
            const [rows] = await pool.execute(
                'SELECT c.id, c.name, c.email, l.name as location_name, c.created_at ' +
                'FROM clients c ' +
                'JOIN locations l ON c.location_id = l.id ' +
                'WHERE c.name LIKE ? OR c.email LIKE ? ' +
                'ORDER BY c.name',
                [`%${searchTerm}%`, `%${searchTerm}%`]
            );
            return rows;
        } catch (error) {
            console.error('Error searching clients:', error);
            throw error;
        }
    }
};