const pool = require('../../config/database');

module.exports = {
    getAllPaymentCalculations: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT pc.id, pc.technician_id, pc.service_id, pc.service_price, pc.applied_percentage, ' +
                'pc.payment_amount, pc.calculation_date, u.name as technician_name, ' +
                's.device_type, s.device_brand, s.service_type, c.name as client_name ' +
                'FROM payment_calculations pc ' +
                'JOIN technicians t ON pc.technician_id = t.id ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN services s ON pc.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'ORDER BY pc.calculation_date DESC'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all payment calculations:', error);
            throw error;
        }
    },
    
    getPaymentCalculationById: async (paymentId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT pc.id, pc.technician_id, pc.service_id, pc.service_price, pc.applied_percentage, ' +
                'pc.payment_amount, pc.calculation_date, u.name as technician_name, ' +
                's.device_type, s.device_brand, s.service_type, s.issue_description, s.completed_date, ' +
                's.is_warranty, c.name as client_name ' +
                'FROM payment_calculations pc ' +
                'JOIN technicians t ON pc.technician_id = t.id ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN services s ON pc.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE pc.id = ?',
                [paymentId]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error getting payment calculation by ID:', error);
            throw error;
        }
    },
    
    getPaymentsByTechnician: async (technicianId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT pc.id, pc.service_id, pc.service_price, pc.applied_percentage, ' +
                'pc.payment_amount, pc.calculation_date, ' +
                's.device_type, s.device_brand, s.service_type, s.completed_date, c.name as client_name ' +
                'FROM payment_calculations pc ' +
                'JOIN services s ON pc.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE pc.technician_id = ? ' +
                'ORDER BY pc.calculation_date DESC',
                [technicianId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting payments by technician:', error);
            throw error;
        }
    },
    
    getPaymentsByDateRange: async (startDate, endDate) => {
        try {
            const [rows] = await pool.execute(
                'SELECT pc.id, pc.technician_id, pc.service_id, pc.service_price, pc.applied_percentage, ' +
                'pc.payment_amount, pc.calculation_date, u.name as technician_name, ' +
                's.device_type, s.device_brand, s.service_type, c.name as client_name ' +
                'FROM payment_calculations pc ' +
                'JOIN technicians t ON pc.technician_id = t.id ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN services s ON pc.service_id = s.id ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'WHERE pc.calculation_date BETWEEN ? AND ? ' +
                'ORDER BY pc.calculation_date DESC',
                [startDate, endDate]
            );
            return rows;
        } catch (error) {
            console.error('Error getting payments by date range:', error);
            throw error;
        }
    },
    
    calculatePaymentForService: async (serviceId) => {
        try {
            // Obtener información del servicio
            const [serviceRows] = await pool.execute(
                'SELECT s.id, s.technician_id, s.final_price, t.completion_rate ' +
                'FROM services s ' +
                'JOIN technicians t ON s.technician_id = t.id ' +
                'WHERE s.id = ? AND s.status = "completed"',
                [serviceId]
            );
            
            if (!serviceRows.length) {
                return null; // El servicio no existe o no está completado
            }
            
            const service = serviceRows[0];
            
            if (!service.final_price) {
                return null; // El servicio no tiene precio final
            }
            
            // Calcular porcentaje de pago según reglas de negocio
            let paymentPercentage;
            
            if (service.completion_rate >= 80) {
                paymentPercentage = 80; // 80% del valor del servicio
            } else if (service.completion_rate >= 70) {
                paymentPercentage = 70; // 70% del valor (reducción del 10%)
            } else {
                paymentPercentage = 60; // 60% del valor (reducción del 20%)
            }
            
            // Calcular monto de pago
            const paymentAmount = (service.final_price * paymentPercentage) / 100;
            
            // Guardar o actualizar el cálculo
            const [result] = await pool.execute(
                'INSERT INTO payment_calculations ' +
                '(technician_id, service_id, service_price, applied_percentage, payment_amount) ' +
                'VALUES (?, ?, ?, ?, ?) ' +
                'ON DUPLICATE KEY UPDATE ' +
                'service_price = VALUES(service_price), ' +
                'applied_percentage = VALUES(applied_percentage), ' +
                'payment_amount = VALUES(payment_amount), ' +
                'calculation_date = CURRENT_TIMESTAMP',
                [service.technician_id, serviceId, service.final_price, paymentPercentage, paymentAmount]
            );
            
            // Actualizar campos de pago en el servicio
            await pool.execute(
                'UPDATE services SET payment_percentage = ?, payment_amount = ? WHERE id = ?',
                [paymentPercentage, paymentAmount, serviceId]
            );
            
            // Obtener el registro de pago completo
            if (result.insertId) {
                return await this.getPaymentCalculationById(result.insertId);
            } else {
                const [paymentRows] = await pool.execute(
                    'SELECT id FROM payment_calculations WHERE service_id = ? AND technician_id = ?',
                    [serviceId, service.technician_id]
                );
                
                if (paymentRows.length) {
                    return await this.getPaymentCalculationById(paymentRows[0].id);
                }
            }
            
            return null;
        } catch (error) {
            console.error('Error calculating payment for service:', error);
            throw error;
        }
    },
    
    recalculateAllPayments: async () => {
        try {
            // Obtener todos los servicios completados con precio final
            const [serviceRows] = await pool.execute(
                'SELECT id FROM services WHERE status = "completed" AND final_price > 0'
            );
            
            const results = [];
            
            // Recalcular pago para cada servicio
            for (const service of serviceRows) {
                const payment = await this.calculatePaymentForService(service.id);
                if (payment) {
                    results.push(payment);
                }
            }
            
            return results;
        } catch (error) {
            console.error('Error recalculating all payments:', error);
            throw error;
        }
    },
    
    getTechnicianPaymentSummary: async (technicianId) => {
        try {
            // Obtener resumen de pagos
            const [summaryRows] = await pool.execute(
                'SELECT ' +
                'SUM(service_price) as total_service_value, ' +
                'SUM(payment_amount) as total_payment_amount, ' +
                'AVG(applied_percentage) as average_percentage, ' +
                'COUNT(*) as total_services, ' +
                'MIN(calculation_date) as first_payment_date, ' +
                'MAX(calculation_date) as last_payment_date ' +
                'FROM payment_calculations ' +
                'WHERE technician_id = ?',
                [technicianId]
            );
            
            // Obtener pagos del último mes
            const [recentRows] = await pool.execute(
                'SELECT ' +
                'SUM(payment_amount) as recent_payment_amount, ' +
                'COUNT(*) as recent_services ' +
                'FROM payment_calculations ' +
                'WHERE technician_id = ? AND ' +
                'calculation_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)',
                [technicianId]
            );
            
            return {
                summary: summaryRows[0],
                recent: recentRows[0]
            };
        } catch (error) {
            console.error('Error getting technician payment summary:', error);
            throw error;
        }
    },
    
    getPaymentStatistics: async () => {
        try {
            // Estadísticas generales
            const [generalStats] = await pool.execute(
                'SELECT ' +
                'COUNT(*) as total_payments, ' +
                'SUM(service_price) as total_service_value, ' +
                'SUM(payment_amount) as total_payment_amount, ' +
                'AVG(applied_percentage) as average_percentage ' +
                'FROM payment_calculations'
            );
            
            // Estadísticas por técnico (top 5)
            const [technicianStats] = await pool.execute(
                'SELECT ' +
                'pc.technician_id, ' +
                'u.name as technician_name, ' +
                'COUNT(*) as service_count, ' +
                'SUM(pc.payment_amount) as total_payment, ' +
                'AVG(pc.applied_percentage) as average_percentage ' +
                'FROM payment_calculations pc ' +
                'JOIN technicians t ON pc.technician_id = t.id ' +
                'JOIN users u ON t.user_id = u.id ' +
                'GROUP BY pc.technician_id, u.name ' +
                'ORDER BY total_payment DESC ' +
                'LIMIT 5'
            );
            
            // Estadísticas por mes (últimos 6 meses)
            const [monthlyStats] = await pool.execute(
                'SELECT ' +
                'DATE_FORMAT(calculation_date, "%Y-%m") as month, ' +
                'COUNT(*) as payment_count, ' +
                'SUM(service_price) as total_service_value, ' +
                'SUM(payment_amount) as total_payment_amount, ' +
                'AVG(applied_percentage) as average_percentage ' +
                'FROM payment_calculations ' +
                'WHERE calculation_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) ' +
                'GROUP BY month ' +
                'ORDER BY month DESC'
            );
            
            return {
                general: generalStats[0],
                topTechnicians: technicianStats,
                monthly: monthlyStats
            };
        } catch (error) {
            console.error('Error getting payment statistics:', error);
            throw error;
        }
    }
};