const pool = require('../../config/database');

module.exports = {
    getAllTechnicians: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.name, u.email, u.is_active, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services, ' +
                't.created_at, t.updated_at ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'ORDER BY u.name'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all technicians:', error);
            throw error;
        }
    },
    
    getTechnicianById: async (technicianId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.id as user_id, u.name, u.email, u.username, u.is_active, ' +
                'l.id as location_id, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services, ' +
                't.created_at, t.updated_at ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.id = ?',
                [technicianId]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error getting technician by ID:', error);
            throw error;
        }
    },
    
    getTechnicianByUserId: async (userId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.id as user_id, u.name, u.email, u.username, u.is_active, ' +
                'l.id as location_id, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services, ' +
                't.created_at, t.updated_at ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.user_id = ?',
                [userId]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error getting technician by user ID:', error);
            throw error;
        }
    },
    
    createTechnician: async (technicianData) => {
        try {
            const { user_id, location_id } = technicianData;
            
            const [result] = await pool.execute(
                'INSERT INTO technicians (user_id, location_id) VALUES (?, ?)',
                [user_id, location_id]
            );
            
            if (result.insertId) {
                return await this.getTechnicianById(result.insertId);
            }
            
            return null;
        } catch (error) {
            console.error('Error creating technician:', error);
            throw error;
        }
    },
    
    updateTechnician: async (technicianId, technicianData) => {
        try {
            const updates = [];
            const params = [];
            
            if (technicianData.location_id !== undefined) {
                updates.push('location_id = ?');
                params.push(technicianData.location_id);
            }
            
            if (technicianData.is_available !== undefined) {
                updates.push('is_available = ?');
                params.push(technicianData.is_available);
            }
            
            if (updates.length === 0) {
                return await this.getTechnicianById(technicianId);
            }
            
            params.push(technicianId);
            
            const [result] = await pool.execute(
                `UPDATE technicians SET ${updates.join(', ')} WHERE id = ?`,
                params
            );
            
            if (result.affectedRows > 0) {
                return await this.getTechnicianById(technicianId);
            }
            
            return null;
        } catch (error) {
            console.error('Error updating technician:', error);
            throw error;
        }
    },
    
    deleteTechnician: async (technicianId) => {
        try {
            const [result] = await pool.execute(
                'DELETE FROM technicians WHERE id = ?',
                [technicianId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error deleting technician:', error);
            throw error;
        }
    },
    
    getTechniciansByLocation: async (locationId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.name, u.email, u.is_active, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services, ' +
                't.created_at, t.updated_at ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.location_id = ? ' +
                'ORDER BY u.name',
                [locationId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting technicians by location:', error);
            throw error;
        }
    },
    
    getAvailableTechnicians: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.name, u.email, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.is_available = 1 AND u.is_active = 1 ' +
                'ORDER BY l.name, t.has_pending_warranty, pending_services, u.name'
            );
            return rows;
        } catch (error) {
            console.error('Error getting available technicians:', error);
            throw error;
        }
    },
    
    getAvailableTechniciansByLocation: async (locationId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.name, u.email, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.location_id = ? AND t.is_available = 1 AND u.is_active = 1 ' +
                'ORDER BY t.has_pending_warranty, pending_services, u.name',
                [locationId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting available technicians by location:', error);
            throw error;
        }
    },
    
    updateTechnicianCompletionRate: async (technicianId) => {
        try {
            // Obtener estadísticas de completitud del técnico desde asignaciones cerradas
            const [stats] = await pool.execute(
                'SELECT SUM(services_count) as total_services, ' +
                'SUM(completed_count) as completed_services ' +
                'FROM service_assignments ' +
                'WHERE technician_id = ? AND is_closed = 1',
                [technicianId]
            );
            
            if (!stats[0].total_services) {
                // No hay datos, establecer por defecto 100%
                await pool.execute(
                    'UPDATE technicians SET completion_rate = 100 WHERE id = ?',
                    [technicianId]
                );
                return 100;
            }
            
            // Calcular porcentaje de completitud
            const completionRate = (stats[0].completed_services / stats[0].total_services) * 100;
            
            // Actualizar registro del técnico
            await pool.execute(
                'UPDATE technicians SET completion_rate = ? WHERE id = ?',
                [completionRate, technicianId]
            );
            
            return completionRate;
        } catch (error) {
            console.error('Error updating technician completion rate:', error);
            throw error;
        }
    },
    
    getTechnicianServiceHistory: async (technicianId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                's.payment_percentage, s.payment_amount, ' +
                's.assigned_date, s.completed_date, c.name as client_name, ' +
                'cl.name as client_location, ' +
                's.created_at, s.updated_at ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'JOIN locations cl ON c.location_id = cl.id ' +
                'WHERE s.technician_id = ? ' +
                'ORDER BY s.created_at DESC',
                [technicianId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting technician service history:', error);
            throw error;
        }
    },
    
    getTechnicianCompletedServices: async (technicianId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.final_price, s.payment_percentage, s.payment_amount, ' +
                's.completed_date, c.name as client_name ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE s.technician_id = ? AND s.status = "completed" ' +
                'ORDER BY s.completed_date DESC',
                [technicianId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting technician completed services:', error);
            throw error;
        }
    },
    
    getTechnicianPerformance: async (technicianId) => {
        try {
            // Obtener información general
            const [generalInfo] = await pool.execute(
                'SELECT ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = ? AND is_warranty = 0) as total_services, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = ? AND status = "completed" AND is_warranty = 0) as completed_services, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = ? AND is_warranty = 1) as warranty_services, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = ? AND status != "completed" AND is_warranty = 0) as pending_services, ' +
                'AVG(CASE WHEN s.status = "completed" THEN TIMESTAMPDIFF(HOUR, s.assigned_date, s.completed_date) ELSE NULL END) as avg_completion_time ' +
                'FROM technicians t ' +
                'LEFT JOIN services s ON t.id = s.technician_id ' +
                'WHERE t.id = ?',
                [technicianId, technicianId, technicianId, technicianId, technicianId]
            );
            
            // Obtener datos financieros
            const [financialInfo] = await pool.execute(
                'SELECT ' +
                'SUM(CASE WHEN s.status = "completed" THEN s.final_price ELSE 0 END) as total_revenue, ' +
                'SUM(CASE WHEN s.status = "completed" THEN s.payment_amount ELSE 0 END) as total_payment, ' +
                'AVG(CASE WHEN s.status = "completed" THEN s.payment_percentage ELSE NULL END) as avg_payment_percentage ' +
                'FROM services s ' +
                'WHERE s.technician_id = ? AND s.is_warranty = 0',
                [technicianId]
            );
            
            // Obtener datos de asignaciones
            const [assignmentsInfo] = await pool.execute(
                'SELECT ' +
                'COUNT(*) as total_assignments, ' +
                'AVG(completion_percentage) as avg_completion_percentage, ' +
                'SUM(CASE WHEN is_closed = 1 THEN 1 ELSE 0 END) as closed_assignments, ' +
                'SUM(CASE WHEN is_closed = 0 THEN 1 ELSE 0 END) as open_assignments ' +
                'FROM service_assignments ' +
                'WHERE technician_id = ?',
                [technicianId]
            );
            
            return {
                general: generalInfo[0],
                financial: financialInfo[0],
                assignments: assignmentsInfo[0]
            };
        } catch (error) {
            console.error('Error getting technician performance:', error);
            throw error;
        }
    },
    
    checkWarrantyPendingStatus: async (technicianId) => {
        try {
            // Verificar si hay garantías pendientes
            const [rows] = await pool.execute(
                'SELECT COUNT(*) as count FROM services ' +
                'WHERE technician_id = ? AND is_warranty = 1 AND status != "completed"',
                [technicianId]
            );
            
            const hasPendingWarranty = rows[0].count > 0;
            
            // Actualizar el estado de garantías pendientes
            await pool.execute(
                'UPDATE technicians SET has_pending_warranty = ? WHERE id = ?',
                [hasPendingWarranty ? 1 : 0, technicianId]
            );
            
            return hasPendingWarranty;
        } catch (error) {
            console.error('Error checking warranty pending status:', error);
            throw error;
        }
    },
    
    getTechnicianDashboardData: async (technicianId) => {
        try {
            // Referencia explícita al método del módulo
            const performance = await module.exports.getTechnicianPerformance(technicianId);

            // Obtener servicios pendientes
            const [pendingServices] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, ' +
                's.assigned_date, c.name as client_name, cl.name as client_location ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'JOIN locations cl ON c.location_id = cl.id ' +
                'WHERE s.technician_id = ? AND s.status != "completed" ' +
                'ORDER BY s.is_warranty DESC, s.assigned_date ASC',
                [technicianId]
            );

            // Obtener servicios completados recientemente
            const [recentCompletions] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.final_price, ' +
                's.payment_percentage, s.payment_amount, s.completed_date, c.name as client_name ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE s.technician_id = ? AND s.status = "completed" ' +
                'ORDER BY s.completed_date DESC LIMIT 5',
                [technicianId]
            );

            return {
                performance,
                pendingServices,
                recentCompletions
            };
        } catch (error) {
            console.error('Error getting technician dashboard data:', error);
            throw error;
        }
    },
};