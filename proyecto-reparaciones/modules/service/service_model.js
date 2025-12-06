const pool = require('../../config/database');

const serviceModel = {
    getAllServices: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                's.assigned_date, s.completed_date, c.name as client_name, ' +
                'CONCAT(u.name, " (", l.name, ")") as technician_info, ' +
                's.created_at, s.updated_at ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'LEFT JOIN locations l ON t.location_id = l.id ' +
                'ORDER BY s.created_at DESC'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all services:', error);
            throw error;
        }
    },
    
    getServiceById: async (serviceId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.*, c.name as client_name, c.phone_encrypted, c.phone_iv, ' +
                'c.address_encrypted, c.address_iv, c.location_id as client_location_id, ' +
                'cl.name as client_location_name, ' +
                'u.name as technician_name, t.location_id as technician_location_id, ' +
                'tl.name as technician_location_name, ' +
                'original.id as original_service_id, original.device_type as original_device_type ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'JOIN locations cl ON c.location_id = cl.id ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'LEFT JOIN locations tl ON t.location_id = tl.id ' +
                'LEFT JOIN services original ON s.original_service_id = original.id ' +
                'WHERE s.id = ?',
                [serviceId]
            );
            
            if (rows.length === 0) return null;
            
            const [photoRows] = await pool.execute(
                'SELECT id, photo_path, photo_type, uploaded_at FROM service_photos ' +
                'WHERE service_id = ? ORDER BY uploaded_at',
                [serviceId]
            );
            
            const service = rows[0];
            service.photos = {
                before: photoRows.filter(photo => photo.photo_type === 'before'),
                after: photoRows.filter(photo => photo.photo_type === 'after')
            };
            
            return service;
        } catch (error) {
            console.error('Error getting service by ID:', error);
            throw error;
        }
    },
    
    createService: async (serviceData) => {
        try {
            const {
                client_id,
                device_type,
                device_brand,
                issue_description,
                service_type,
                is_warranty,
                original_service_id,
                technician_id,
                created_by
            } = serviceData;
            
            const [result] = await pool.execute(
                'INSERT INTO services ' +
                '(client_id, device_type, device_brand, issue_description, service_type, ' +
                'status, is_warranty, original_service_id, technician_id, created_by) ' +
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                    client_id,
                    device_type,
                    device_brand,
                    issue_description,
                    service_type,
                    technician_id ? 'assigned' : 'new',
                    is_warranty ? 1 : 0,
                    original_service_id || null,
                    technician_id || null,
                    created_by
                ]
            );
            
            if (result.insertId) {
                // Si hay un técnico asignado, actualizar la fecha de asignación
                if (technician_id) {
                    await pool.execute(
                        'UPDATE services SET assigned_date = NOW() WHERE id = ?',
                        [result.insertId]
                    );
                    
                    if (is_warranty) {
                        await pool.execute(
                            'UPDATE technicians SET has_pending_warranty = 1 WHERE id = ?',
                            [technician_id]
                        );
                    }
                    
                    await serviceModel.updateServiceAssignmentCount(technician_id); // Cambiar this a serviceModel
                }
                
                return await serviceModel.getServiceById(result.insertId); // Cambiar this a serviceModel
            }
            
            return null;
        } catch (error) {
            console.error('Error creating service:', error);
            throw error;
        }
    },

    // Otros métodos también necesitan corrección si usan this.getServiceById
    updateService: async (serviceId, serviceData) => {
        try {
            const currentService = await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
            if (!currentService) return null;
            
            let query = 'UPDATE services SET ';
            const params = [];
            const updates = [];
            
            const fields = [
                'device_type', 'device_brand', 'issue_description', 'service_type',
                'status', 'estimated_price', 'final_price', 'is_warranty', 'original_service_id'
            ];
            
            fields.forEach(field => {
                if (serviceData[field] !== undefined) {
                    updates.push(`${field} = ?`);
                    params.push(serviceData[field]);
                }
            });
            
            if (serviceData.status === 'completed' && currentService.status !== 'completed') {
                updates.push('completed_date = NOW()');
                
                if (currentService.is_warranty && currentService.technician_id) {
                    const [pendingWarranties] = await pool.execute(
                        'SELECT COUNT(*) as count FROM services ' +
                        'WHERE technician_id = ? AND is_warranty = 1 AND status != "completed" AND id != ?',
                        [currentService.technician_id, serviceId]
                    );
                    
                    if (pendingWarranties[0].count === 0) {
                        await pool.execute(
                            'UPDATE technicians SET has_pending_warranty = 0 WHERE id = ?',
                            [currentService.technician_id]
                        );
                    }
                }
                
                if (currentService.technician_id) {
                    await serviceModel.updateServiceCompletionCount(currentService.technician_id); // Cambiar this a serviceModel
                }
            }
            
            if (serviceData.technician_id !== undefined && 
                serviceData.technician_id !== currentService.technician_id) {
                
                updates.push('technician_id = ?');
                params.push(serviceData.technician_id);
                
                if (serviceData.technician_id) {
                    updates.push('status = "assigned", assigned_date = NOW()');
                    
                    if (currentService.is_warranty) {
                        await pool.execute(
                            'UPDATE technicians SET has_pending_warranty = 1 WHERE id = ?',
                            [serviceData.technician_id]
                        );
                    }
                    
                    await serviceModel.updateServiceAssignmentCount(serviceData.technician_id); // Cambiar this a serviceModel
                } else {
                    updates.push('status = "new", assigned_date = NULL');
                }
                
                if (currentService.technician_id && currentService.is_warranty) {
                    const [pendingWarranties] = await pool.execute(
                        'SELECT COUNT(*) as count FROM services ' +
                        'WHERE technician_id = ? AND is_warranty = 1 AND status != "completed" AND id != ?',
                        [currentService.technician_id, serviceId]
                    );
                    
                    if (pendingWarranties[0].count === 0) {
                        await pool.execute(
                            'UPDATE technicians SET has_pending_warranty = 0 WHERE id = ?',
                            [currentService.technician_id]
                        );
                    }
                }
            }
            
            if (updates.length > 0) {
                query += updates.join(', ') + ' WHERE id = ?';
                params.push(serviceId);
                
                const [result] = await pool.execute(query, params);
                
                if (result.affectedRows > 0) {
                    return await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
                }
            } else {
                return currentService;
            }
            
            return null;
        } catch (error) {
            console.error('Error updating service:', error);
            throw error;
        }
    },

    // Asegurarse de corregir otros métodos que usan this
    deleteService: async (serviceId) => {
        try {
            await pool.execute(
                'DELETE FROM service_photos WHERE service_id = ?',
                [serviceId]
            );
            
            const [result] = await pool.execute(
                'DELETE FROM services WHERE id = ?',
                [serviceId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error deleting service:', error);
            throw error;
        }
    },

    // ... (otros métodos como addServicePhoto, removeServicePhoto, etc., también deben usar serviceModel si llaman a getServiceById)

    updateServiceStatus: async (serviceId, status) => {
        try {
            let query = 'UPDATE services SET status = ?';
            const params = [status];
            
            if (status === 'completed') {
                query += ', completed_date = NOW()';
            }
            
            query += ' WHERE id = ?';
            params.push(serviceId);
            
            const [result] = await pool.execute(query, params);
            
            if (result.affectedRows > 0) {
                if (status === 'completed') {
                    const service = await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
                    if (service && service.technician_id) {
                        await serviceModel.updateServiceCompletionCount(service.technician_id); // Cambiar this a serviceModel
                        
                        if (service.is_warranty) {
                            const [pendingWarranties] = await pool.execute(
                                'SELECT COUNT(*) as count FROM services ' +
                                'WHERE technician_id = ? AND is_warranty = 1 AND status != "completed" AND id != ?',
                                [service.technician_id, serviceId]
                            );
                            
                            if (pendingWarranties[0].count === 0) {
                                await pool.execute(
                                    'UPDATE technicians SET has_pending_warranty = 0 WHERE id = ?',
                                    [service.technician_id]
                                );
                            }
                        }
                    }
                }
                
                return await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
            }
            
            return null;
        } catch (error) {
            console.error('Error updating service status:', error);
            throw error;
        }
    },

    assignTechnician: async (serviceId, technicianId) => {
        try {
            const [result] = await pool.execute(
                'UPDATE services SET technician_id = ?, status = "assigned", assigned_date = NOW() WHERE id = ?',
                [technicianId, serviceId]
            );
            
            if (result.affectedRows > 0) {
                await serviceModel.updateServiceAssignmentCount(technicianId); // Cambiar this a serviceModel
                
                const service = await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
                if (service && service.is_warranty) {
                    await pool.execute(
                        'UPDATE technicians SET has_pending_warranty = 1 WHERE id = ?',
                        [technicianId]
                    );
                }
                
                return await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
            }
            
            return null;
        } catch (error) {
            console.error('Error assigning technician:', error);
            throw error;
        }
    },

    updateEstimatedPrice: async (serviceId, price) => {
        try {
            const [result] = await pool.execute(
                'UPDATE services SET estimated_price = ?, status = "in_progress" WHERE id = ?',
                [price, serviceId]
            );
            
            if (result.affectedRows > 0) {
                return await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
            }
            
            return null;
        } catch (error) {
            console.error('Error updating estimated price:', error);
            throw error;
        }
    },

    updateFinalPrice: async (serviceId, price) => {
        try {
            const [result] = await pool.execute(
                'UPDATE services SET final_price = ? WHERE id = ?',
                [price, serviceId]
            );
            
            if (result.affectedRows > 0) {
                return await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
            }
            
            return null;
        } catch (error) {
            console.error('Error updating final price:', error);
            throw error;
        }
    },

    // Métodos restantes no necesitan cambios a menos que usen this.getServiceById
    getServicesByTechnician: async (technicianId, status = null) => {
        try {
            let query = 'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                    's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                    's.assigned_date, s.completed_date, c.name as client_name, ' +
                    'cl.name as client_location, ' +
                    's.created_at, s.updated_at ' +
                    'FROM services s ' +
                    'JOIN clients c ON s.client_id = c.id ' +
                    'JOIN locations cl ON c.location_id = cl.id ' +
                    'WHERE s.technician_id = ? ';
            
            const params = [technicianId];
            
            if (status) {
                query += 'AND s.status = ? ';
                params.push(status);
            }
            
            query += 'ORDER BY s.created_at DESC';
            
            const [rows] = await pool.execute(query, params);
            return rows;
        } catch (error) {
            console.error('Error getting services by technician:', error);
            throw error;
        }
    },

    getServicesByLocation: async (locationId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                's.assigned_date, s.completed_date, c.name as client_name, ' +
                'u.name as technician_name, ' +
                's.created_at, s.updated_at ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'WHERE c.location_id = ? ' +
                'ORDER BY s.created_at DESC',
                [locationId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting services by location:', error);
            throw error;
        }
    },

    getServicesByStatus: async (status) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                's.assigned_date, s.completed_date, c.name as client_name, ' +
                'cl.name as client_location, ' +
                'u.name as technician_name, ' +
                'tl.name as technician_location, ' +
                's.created_at, s.updated_at ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'JOIN locations cl ON c.location_id = cl.id ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'LEFT JOIN locations tl ON t.location_id = tl.id ' +
                'WHERE s.status = ? ' +
                'ORDER BY s.created_at DESC',
                [status]
            );
            return rows;
        } catch (error) {
            console.error('Error getting services by status:', error);
            throw error;
        }
    },

    getWarrantyServices: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.estimated_price, s.final_price, ' +
                's.assigned_date, s.completed_date, c.name as client_name, ' +
                'cl.name as client_location, ' +
                'u.name as technician_name, ' +
                'tl.name as technician_location, ' +
                'orig.id as original_service_id, ' +
                's.created_at, s.updated_at ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'JOIN locations cl ON c.location_id = cl.id ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'LEFT JOIN locations tl ON t.location_id = tl.id ' +
                'LEFT JOIN services orig ON s.original_service_id = orig.id ' +
                'WHERE s.is_warranty = 1 ' +
                'ORDER BY s.created_at DESC'
            );
            return rows;
        } catch (error) {
            console.error('Error getting warranty services:', error);
            throw error;
        }
    },

    getServiceStatistics: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT ' +
                'COUNT(*) as total_services, ' +
                'SUM(CASE WHEN status = "new" THEN 1 ELSE 0 END) as new_services, ' +
                'SUM(CASE WHEN status = "assigned" THEN 1 ELSE 0 END) as assigned_services, ' +
                'SUM(CASE WHEN status = "in_progress" THEN 1 ELSE 0 END) as in_progress_services, ' +
                'SUM(CASE WHEN status = "completed" THEN 1 ELSE 0 END) as completed_services, ' +
                'SUM(CASE WHEN status = "cancelled" THEN 1 ELSE 0 END) as cancelled_services, ' +
                'SUM(CASE WHEN is_warranty = 1 THEN 1 ELSE 0 END) as warranty_services, ' +
                'SUM(CASE WHEN service_type = "repair" THEN 1 ELSE 0 END) as repair_services, ' +
                'SUM(CASE WHEN service_type = "maintenance" THEN 1 ELSE 0 END) as maintenance_services, ' +
                'AVG(CASE WHEN final_price > 0 THEN final_price ELSE NULL END) as average_price ' +
                'FROM services'
            );
            return rows[0];
        } catch (error) {
            console.error('Error getting service statistics:', error);
            throw error;
        }
    },

    searchServices: async (searchTerm) => {
        try {
            const [rows] = await pool.execute(
                'SELECT s.id, s.device_type, s.device_brand, s.issue_description, ' +
                's.service_type, s.status, s.is_warranty, s.estimated_price, s.final_price, ' +
                's.assigned_date, s.completed_date, c.name as client_name, ' +
                'u.name as technician_name, ' +
                's.created_at, s.updated_at ' +
                'FROM services s ' +
                'JOIN clients c ON s.client_id = c.id ' +
                'LEFT JOIN technicians t ON s.technician_id = t.id ' +
                'LEFT JOIN users u ON t.user_id = u.id ' +
                'WHERE s.device_type LIKE ? OR s.device_brand LIKE ? OR ' +
                's.issue_description LIKE ? OR c.name LIKE ? OR u.name LIKE ? ' +
                'ORDER BY s.created_at DESC',
                Array(5).fill(`%${searchTerm}%`)
            );
            return rows;
        } catch (error) {
            console.error('Error searching services:', error);
            throw error;
        }
    },

    updateServiceAssignmentCount: async (technicianId) => {
        try {
            const today = new Date().toISOString().slice(0, 10);
            
            const [assignmentRows] = await pool.execute(
                'SELECT * FROM service_assignments WHERE technician_id = ? AND assignment_date = ?',
                [technicianId, today]
            );
            
            if (assignmentRows.length === 0) {
                await pool.execute(
                    'INSERT INTO service_assignments (technician_id, assignment_date, services_count) ' +
                    'VALUES (?, ?, 1)',
                    [technicianId, today]
                );
            } else {
                await pool.execute(
                    'UPDATE service_assignments SET services_count = services_count + 1 ' +
                    'WHERE technician_id = ? AND assignment_date = ?',
                    [technicianId, today]
                );
            }
            
            return true;
        } catch (error) {
            console.error('Error updating service assignment count:', error);
            throw error;
        }
    },

    updateServiceCompletionCount: async (technicianId) => {
        try {
            const [assignmentRows] = await pool.execute(
                'SELECT * FROM service_assignments ' +
                'WHERE technician_id = ? AND is_closed = 0',
                [technicianId]
            );
            
            for (const assignment of assignmentRows) {
                const [assignedRows] = await pool.execute(
                    'SELECT COUNT(*) as count FROM services ' +
                    'WHERE technician_id = ? AND assigned_date >= ? AND assigned_date < DATE_ADD(?, INTERVAL 1 DAY)',
                    [technicianId, assignment.assignment_date, assignment.assignment_date]
                );
                
                const [completedRows] = await pool.execute(
                    'SELECT COUNT(*) as count FROM services ' +
                    'WHERE technician_id = ? AND status = "completed" ' +
                    'AND assigned_date >= ? AND assigned_date < DATE_ADD(?, INTERVAL 1 DAY)',
                    [technicianId, assignment.assignment_date, assignment.assignment_date]
                );
                
                const servicesCount = assignedRows[0].count;
                const completedCount = completedRows[0].count;
                const completionPercentage = servicesCount > 0 
                    ? (completedCount / servicesCount) * 100 
                    : 0;
                
                await pool.execute(
                    'UPDATE service_assignments SET ' +
                    'services_count = ?, completed_count = ?, completion_percentage = ? ' +
                    'WHERE id = ?',
                    [servicesCount, completedCount, completionPercentage, assignment.id]
                );
                
                const assignmentDate = new Date(assignment.assignment_date);
                const today = new Date();
                const daysDiff = Math.floor((today - assignmentDate) / (1000 * 60 * 60 * 24));
                
                if (daysDiff >= 3 || completedCount === servicesCount) {
                    await pool.execute(
                        'UPDATE service_assignments SET is_closed = 1 WHERE id = ?',
                        [assignment.id]
                    );
                }
            }
            
            const [totalStats] = await pool.execute(
                'SELECT ' +
                'SUM(services_count) as total_services, ' +
                'SUM(completed_count) as total_completed ' +
                'FROM service_assignments ' +
                'WHERE technician_id = ? AND is_closed = 1',
                [technicianId]
            );
            
            if (totalStats[0].total_services > 0) {
                const overallCompletionRate = 
                    (totalStats[0].total_completed / totalStats[0].total_services) * 100;
                
                await pool.execute(
                    'UPDATE technicians SET completion_rate = ? WHERE id = ?',
                    [overallCompletionRate, technicianId]
                );
            }
            
            return true;
        } catch (error) {
            console.error('Error updating service completion count:', error);
            throw error;
        }
    },

    calculateTechnicianPayment: async (technicianId, serviceId) => {
        try {
            const service = await serviceModel.getServiceById(serviceId); // Cambiar this a serviceModel
            if (!service || !service.final_price) return null;
            
            const [techRows] = await pool.execute(
                'SELECT completion_rate FROM technicians WHERE id = ?',
                [technicianId]
            );
            
            if (!techRows.length) return null;
            
            const completionRate = techRows[0].completion_rate;
            let paymentPercentage;
            
            if (completionRate >= 80) {
                paymentPercentage = 80;
            } else if (completionRate >= 70) {
                paymentPercentage = 70;
            } else {
                paymentPercentage = 60;
            }
            
            const paymentAmount = (service.final_price * paymentPercentage) / 100;
            
            const [result] = await pool.execute(
                'INSERT INTO payment_calculations ' +
                '(technician_id, service_id, service_price, applied_percentage, payment_amount) ' +
                'VALUES (?, ?, ?, ?, ?) ' +
                'ON DUPLICATE KEY UPDATE ' +
                'service_price = VALUES(service_price), ' +
                'applied_percentage = VALUES(applied_percentage), ' +
                'payment_amount = VALUES(payment_amount), ' +
                'calculation_date = CURRENT_TIMESTAMP',
                [technicianId, serviceId, service.final_price, paymentPercentage, paymentAmount]
            );
            
            await pool.execute(
                'UPDATE services SET payment_percentage = ?, payment_amount = ? WHERE id = ?',
                [paymentPercentage, paymentAmount, serviceId]
            );
            
            return {
                service_id: serviceId,
                technician_id: technicianId,
                service_price: service.final_price,
                completion_rate: completionRate,
                applied_percentage: paymentPercentage,
                payment_amount: paymentAmount
            };
        } catch (error) {
            console.error('Error calculating technician payment:', error);
            throw error;
        }
    },

    getAvailableTechniciansByLocation: async (locationId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.name, t.location_id, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.location_id = ? AND t.is_available = 1 AND u.is_active = 1 ' +
                'ORDER BY t.has_pending_warranty ASC, pending_services ASC, u.name ASC',
                [locationId]
            );
            return rows;
        } catch (error) {
            console.error('Error getting available technicians by location:', error);
            throw error;
        }
    },

    getAllAvailableTechnicians: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.id, u.name, t.location_id, l.name as location_name, ' +
                't.is_available, t.has_pending_warranty, t.completion_rate, ' +
                '(SELECT COUNT(*) FROM services WHERE technician_id = t.id AND status != "completed") as pending_services ' +
                'FROM technicians t ' +
                'JOIN users u ON t.user_id = u.id ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.is_available = 1 AND u.is_active = 1 ' +
                'ORDER BY l.name ASC, t.has_pending_warranty ASC, pending_services ASC, u.name ASC'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all available technicians:', error);
            throw error;
        }
    }
};

module.exports = serviceModel;