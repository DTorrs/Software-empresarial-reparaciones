const pool = require('../../config/database');

module.exports = {
    getAllLocations: async () => {
        try {
            const [rows] = await pool.execute('SELECT * FROM locations ORDER BY name');
            return rows;
        } catch (error) {
            console.error('Error getting all locations:', error);
            throw error;
        }
    },
    
    getLocationById: async (locationId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT * FROM locations WHERE id = ?',
                [locationId]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error getting location by ID:', error);
            throw error;
        }
    },
    
    createLocation: async (locationData) => {
        try {
            const { name } = locationData;
            
            const [result] = await pool.execute(
                'INSERT INTO locations (name) VALUES (?)',
                [name]
            );
            
            if (result.insertId) {
                return await this.getLocationById(result.insertId);
            }
            
            return null;
        } catch (error) {
            console.error('Error creating location:', error);
            throw error;
        }
    },
    
    updateLocation: async (locationId, locationData) => {
        try {
            const { name } = locationData;
            
            const [result] = await pool.execute(
                'UPDATE locations SET name = ? WHERE id = ?',
                [name, locationId]
            );
            
            if (result.affectedRows > 0) {
                return await this.getLocationById(locationId);
            }
            
            return null;
        } catch (error) {
            console.error('Error updating location:', error);
            throw error;
        }
    },
    
    deleteLocation: async (locationId) => {
        try {
            const [result] = await pool.execute(
                'DELETE FROM locations WHERE id = ?',
                [locationId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error deleting location:', error);
            throw error;
        }
    },
    
    getTechniciansCountByLocation: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT l.id, l.name, COUNT(t.id) AS technicians_count ' +
                'FROM locations l ' +
                'LEFT JOIN technicians t ON l.id = t.location_id ' +
                'GROUP BY l.id, l.name ' +
                'ORDER BY l.name'
            );
            return rows;
        } catch (error) {
            console.error('Error getting technicians count by location:', error);
            throw error;
        }
    },
    
    getServicesCountByLocation: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT l.id, l.name, COUNT(s.id) AS services_count ' +
                'FROM locations l ' +
                'LEFT JOIN clients c ON l.id = c.location_id ' +
                'LEFT JOIN services s ON c.id = s.client_id ' +
                'GROUP BY l.id, l.name ' +
                'ORDER BY l.name'
            );
            return rows;
        } catch (error) {
            console.error('Error getting services count by location:', error);
            throw error;
        }
    },
    
    getLocationStatistics: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT l.id, l.name, ' +
                'COUNT(DISTINCT t.id) AS technicians_count, ' +
                'COUNT(DISTINCT s.id) AS services_count, ' +
                'SUM(CASE WHEN s.status = "completed" THEN 1 ELSE 0 END) AS completed_services, ' +
                'SUM(CASE WHEN s.is_warranty = 1 THEN 1 ELSE 0 END) AS warranty_services ' +
                'FROM locations l ' +
                'LEFT JOIN technicians t ON l.id = t.location_id ' +
                'LEFT JOIN clients c ON l.id = c.location_id ' +
                'LEFT JOIN services s ON c.id = s.client_id ' +
                'GROUP BY l.id, l.name ' +
                'ORDER BY l.name'
            );
            return rows;
        } catch (error) {
            console.error('Error getting location statistics:', error);
            throw error;
        }
    }
};