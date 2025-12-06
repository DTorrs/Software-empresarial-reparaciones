const pool = require('../../config/database');
const bcrypt = require('bcryptjs');

module.exports = {
    findUserByUsername: async (username) => {
        try {
            const [rows] = await pool.execute(
                'SELECT u.*, r.name as role FROM users u JOIN roles r ON u.role_id = r.id WHERE u.username = ?',
                [username]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error finding user by username:', error);
            throw error;
        }
    },
    
    findUserByEmail: async (email) => {
        try {
            const [rows] = await pool.execute(
                'SELECT u.*, r.name as role FROM users u JOIN roles r ON u.role_id = r.id WHERE u.email = ?',
                [email]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error finding user by email:', error);
            throw error;
        }
    },
    
    createUser: async (userData) => {
        const { username, password, email, name, role_id } = userData;
        
        try {
            // Hashear la contraseña
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            
            const [result] = await pool.execute(
                'INSERT INTO users (username, password, email, name, role_id) VALUES (?, ?, ?, ?, ?)',
                [username, hashedPassword, email, name, role_id]
            );
            
            if (result.insertId) {
                const [rows] = await pool.execute(
                    'SELECT u.*, r.name as role FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = ?',
                    [result.insertId]
                );
                return rows[0];
            }
            
            return null;
        } catch (error) {
            console.error('Error creating user:', error);
            throw error;
        }
    },
    
    comparePassword: async (plainPassword, hashedPassword) => {
        return await bcrypt.compare(plainPassword, hashedPassword);
    },
    
    getRoleIdByName: async (roleName) => {
        try {
            const [rows] = await pool.execute(
                'SELECT id FROM roles WHERE name = ?',
                [roleName]
            );
            return rows.length ? rows[0].id : null;
        } catch (error) {
            console.error('Error getting role by name:', error);
            throw error;
        }
    },
    
    getTechnicianDetails: async (userId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT t.*, l.name as location_name FROM technicians t ' +
                'JOIN locations l ON t.location_id = l.id ' +
                'WHERE t.user_id = ?',
                [userId]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error getting technician details:', error);
            throw error;
        }
    }
};