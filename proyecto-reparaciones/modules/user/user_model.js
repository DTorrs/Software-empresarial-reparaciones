const pool = require('../../config/database');
const bcrypt = require('bcryptjs');

// Define the model as a named object
const userModel = {
    getAllUsers: async () => {
        try {
            const [rows] = await pool.execute(
                'SELECT u.id, u.username, u.email, u.name, r.name as role, u.is_active, u.created_at, u.updated_at ' +
                'FROM users u JOIN roles r ON u.role_id = r.id ORDER BY u.id'
            );
            return rows;
        } catch (error) {
            console.error('Error getting all users:', error);
            throw error;
        }
    },
    
    getUserById: async (userId) => {
        try {
            const [rows] = await pool.execute(
                'SELECT u.id, u.username, u.email, u.name, r.name as role, u.is_active, u.created_at, u.updated_at ' +
                'FROM users u JOIN roles r ON u.role_id = r.id WHERE u.id = ?',
                [userId]
            );
            return rows.length ? rows[0] : null;
        } catch (error) {
            console.error('Error getting user by ID:', error);
            throw error;
        }
    },
    
    createUser: async (userData) => {
        const { username, password, email, name, role_id } = userData;
        
        try {
            // Hash the password
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            
            const [result] = await pool.execute(
                'INSERT INTO users (username, password, email, name, role_id) VALUES (?, ?, ?, ?, ?)',
                [username, hashedPassword, email, name, role_id]
            );
            
            if (result.insertId) {
                // Use userModel instead of this
                return await userModel.getUserById(result.insertId);
            }
            
            return null;
        } catch (error) {
            console.error('Error creating user:', error);
            throw error;
        }
    },
    
    updateUser: async (userId, userData) => {
        try {
            const { username, email, name, role_id, is_active } = userData;
            
            let query = 'UPDATE users SET ';
            const params = [];
            
            if (username) {
                query += 'username = ?, ';
                params.push(username);
            }
            
            if (email) {
                query += 'email = ?, ';
                params.push(email);
            }
            
            if (name) {
                query += 'name = ?, ';
                params.push(name);
            }
            
            if (role_id) {
                query += 'role_id = ?, ';
                params.push(role_id);
            }
            
            if (is_active !== undefined) {
                query += 'is_active = ?, ';
                params.push(is_active);
            }
            
            // If there's a password, hash it and add to the update
            if (userData.password) {
                const salt = await bcrypt.genSalt(10);
                const hashedPassword = await bcrypt.hash(userData.password, salt);
                query += 'password = ?, ';
                params.push(hashedPassword);
            }
            
            // Remove the last comma and space
            query = query.slice(0, -2);
            
            // Add WHERE condition
            query += ' WHERE id = ?';
            params.push(userId);
            
            const [result] = await pool.execute(query, params);
            
            if (result.affectedRows > 0) {
                return await userModel.getUserById(userId); // Use userModel instead of this
            }
            
            return null;
        } catch (error) {
            console.error('Error updating user:', error);
            throw error;
        }
    },
    
    deleteUser: async (userId) => {
        try {
            const [result] = await pool.execute(
                'DELETE FROM users WHERE id = ?',
                [userId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error deleting user:', error);
            throw error;
        }
    },
    
    updatePassword: async (userId, newPassword) => {
        try {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(newPassword, salt);
            
            const [result] = await pool.execute(
                'UPDATE users SET password = ? WHERE id = ?',
                [hashedPassword, userId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error updating password:', error);
            throw error;
        }
    },
    
    changeUserStatus: async (userId, isActive) => {
        try {
            const [result] = await pool.execute(
                'UPDATE users SET is_active = ? WHERE id = ?',
                [isActive, userId]
            );
            
            return result.affectedRows > 0;
        } catch (error) {
            console.error('Error changing user status:', error);
            throw error;
        }
    },
    
    getUsersByRole: async (roleName) => {
        try {
            const [rows] = await pool.execute(
                'SELECT u.id, u.username, u.email, u.name, r.name as role, u.is_active, u.created_at, u.updated_at ' +
                'FROM users u JOIN roles r ON u.role_id = r.id WHERE r.name = ? ORDER BY u.name',
                [roleName]
            );
            return rows;
        } catch (error) {
            console.error('Error getting users by role:', error);
            throw error;
        }
    },
    
    getRoles: async () => {
        try {
            const [rows] = await pool.execute('SELECT * FROM roles');
            return rows;
        } catch (error) {
            console.error('Error getting roles:', error);
            throw error;
        }
    }
};

module.exports = userModel;