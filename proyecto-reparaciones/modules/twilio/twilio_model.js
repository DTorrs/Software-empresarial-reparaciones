const pool = require('../../config/database');
const encryption = require('../../utils/encryption');

module.exports = {
    getAllMessages: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT tm.id, tm.service_id, tm.message_type, tm.message_content, ' +
                'tm.status, tm.sent_at, tm.created_at, s.device_type, s.device_brand, ' +
                'c.name as client_name ' +
                'FROM twilio_messages tm ' +
                'JOIN services s ON tm.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'ORDER BY tm.created_at DESC'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all Twilio messages:', error);
            throw error;
        }
    },
    
    getMessageById: async (messageId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT tm.id, tm.service_id, tm.message_type, tm.message_content, ' +
                'tm.status, tm.sent_at, tm.created_at, s.device_type, s.device_brand, ' +
                'c.name as client_name, c.phone_encrypted, c.phone_iv ' +
                'FROM twilio_messages tm ' +
                'JOIN services s ON tm.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE tm.id = ?',
                [messageId]
            );
            
            if (!rows.length) return null;
            
            const message = rows[0];
            
            // Desencriptar teléfono solo para uso interno
            message.client_phone = encryption.decrypt(message.phone_encrypted, message.phone_iv);
            
            // Eliminar datos encriptados
            delete message.phone_encrypted;
            delete message.phone_iv;
            
            return message;
        } catch (error) {
            console.error('Error getting Twilio message by ID:', error);
            throw error;
        }
    },
    
    getMessagesByService: async (serviceId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT id, message_type, message_content, status, sent_at, created_at ' +
                'FROM twilio_messages ' +
                'WHERE service_id = ? ' +
                'ORDER BY created_at DESC',
                [serviceId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting Twilio messages by service:', error);
            throw error;
        }
    },
    
    createMessage: async (messageData) => {
        try {
            const { service_id, message_type, message_content, status = 'pending' } = messageData;
            
            const [result] = await pool.execute(
                'INSERT INTO twilio_messages (service_id, message_type, message_content, status) ' +
                'VALUES (?, ?, ?, ?)',
                [service_id, message_type, message_content, status]
            );
            
            if (result.insertId) {
                return await this.getMessageById(result.insertId);
            }
            
            return null;
        } catch (error) {
            console.error('Error creating Twilio message:', error);
            throw error;
        }
    },
    
    updateMessageStatus: async (messageId, status, sentAt = null) => {
        try {
            let query = 'UPDATE twilio_messages SET status = ?';
            const params = [status];
            
            if (sentAt) {
                query += ', sent_at = ?';
                params.push(sentAt);
            } else if (status === 'sent') {
                query += ', sent_at = NOW()';
            }
            
            query += ' WHERE id = ?';
            params.push(messageId);
            
            const [result] = await pool.execute(query, params);
            
            if (result.affectedRows > 0) {
                return await this.getMessageById(messageId);
            }
            
            return null;
        } catch (error) {
            console.error('Error updating Twilio message status:', error);
            throw error;
        }
    },
    
    // Eliminar mensaje (con precaución)
    deleteMessage: async (messageId) => {
        try {
            const [result] = await pool.execute(
                'DELETE FROM twilio_messages WHERE id = ?',
                [messageId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error deleting Twilio message:', error);
            throw error;
        }
    },
    
    // Obtener mensajes pendientes para enviar
    getPendingMessages: async (limit = 10) => {
        try {
            const [rows] = await pool.execute(
                'SELECT tm.id, tm.service_id, tm.message_type, tm.message_content, ' +
                'c.phone_encrypted, c.phone_iv, c.name as client_name, ' +
                's.device_type, s.device_brand, s.issue_description ' +
                'FROM twilio_messages tm ' +
                'JOIN services s ON tm.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE tm.status = "pending" ' +
                'ORDER BY tm.created_at ASC ' +
                'LIMIT ?',
                [limit]
            );
            
            // Desencriptar teléfonos
            return rows.map(message => {
                message.client_phone = encryption.decrypt(message.phone_encrypted, message.phone_iv);
                delete message.phone_encrypted;
                delete message.phone_iv;
                return message;
            });
        } catch (error) {
            console.error('Error getting pending Twilio messages:', error);
            throw error;
        }
    },
    
    getMessageStatistics: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT ' +
                'COUNT(*) as total_messages, ' +
                'SUM(CASE WHEN status = "pending" THEN 1 ELSE 0 END) as pending_messages, ' +
                'SUM(CASE WHEN status = "sent" THEN 1 ELSE 0 END) as sent_messages, ' +
                'SUM(CASE WHEN status = "failed" THEN 1 ELSE 0 END) as failed_messages, ' +
                'SUM(CASE WHEN message_type = "welcome" THEN 1 ELSE 0 END) as welcome_messages, ' +
                'SUM(CASE WHEN message_type = "quote" THEN 1 ELSE 0 END) as quote_messages, ' +
                'SUM(CASE WHEN message_type = "reminder" THEN 1 ELSE 0 END) as reminder_messages, ' +
                'SUM(CASE WHEN message_type = "completion" THEN 1 ELSE 0 END) as completion_messages ' +
                'FROM twilio_messages'
            );
            return rows[0];
        } catch (error) {
            console.error('Error getting Twilio message statistics:', error);
            throw error;
        }
    }
};
