import 'package:flutter/foundation.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/api_service.dart';
import 'package:repair_service_app/config/api_endpoints.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  
  // Constructor
  UserProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Getters
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasMore => _hasMore;
  
  // Obtener todos los usuarios
  Future<void> fetchUsers() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.get<List<User>>(
        ApiEndpoints.users,
        fromJson: (data) => (data as List)
            .map((item) => User.fromJson(item))
            .toList(),
      );
      
      if (response.success && response.data != null) {
        _users = response.data!;
        _hasMore = false; // Cargamos todos a la vez
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Error al cargar usuarios: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtener usuarios por rol
  Future<void> fetchUsersByRole(String role) async {
    if (_isLoading) return;
    
    _setLoading(true);
    _error = null;
    
    try {
      final response = await _apiService.get<List<User>>(
        '${ApiEndpoints.usersByRole}$role',
        fromJson: (data) => (data as List)
            .map((item) => User.fromJson(item))
            .toList(),
      );
      
      if (response.success && response.data != null) {
        _users = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Error al cargar usuarios por rol: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtener un usuario por ID
  Future<User?> getUserById(int userId) async {
    _error = null;
    
    try {
      // Buscar primero en la lista local
      final localUser = _users.firstWhere(
        (user) => user.id == userId,
        orElse: () => User(
          id: -1,
          username: '',
          email: '',
          name: '',
          role: '',
          isActive: false,
        ),
      );
      
      if (localUser.id != -1) {
        return localUser;
      }
      
      // Si no se encuentra localmente, cargar desde la API
      final response = await _apiService.get<User>(
        '${ApiEndpoints.userById}$userId',
        fromJson: (data) => User.fromJson(data),
      );
      
      if (response.success && response.data != null) {
        // Si el usuario no está en la lista, agregarlo
        final user = response.data!;
        final index = _users.indexWhere((u) => u.id == userId);
        if (index == -1) {
          _users.add(user);
          notifyListeners();
        }
        return user;
      } else {
        _error = response.message;
        return null;
      }
    } catch (e) {
      _error = 'Error al obtener usuario: $e';
      return null;
    }
  }
  
  // Crear un nuevo usuario
  Future<User?> createUser({
    required String username,
    required String password,
    required String email,
    required String name,
    required String role,
  }) async {
    _error = null;
    _setLoading(true);
    
    try {
      final response = await _apiService.post<User>(
        ApiEndpoints.users,
        body: {
          'username': username,
          'password': password,
          'email': email,
          'name': name,
          'role': role,
        },
        fromJson: (data) => User.fromJson(data),
      );
      
      if (response.success && response.data != null) {
        final newUser = response.data!;
        _users.add(newUser);
        notifyListeners();
        return newUser;
      } else {
        _error = response.message;
        return null;
      }
    } catch (e) {
      _error = 'Error al crear usuario: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar un usuario existente
  Future<User?> updateUser({
    required int userId,
    String? username,
    String? email,
    String? name,
    String? role,
    bool? isActive,
  }) async {
    _error = null;
    _setLoading(true);
    
    try {
      final Map<String, dynamic> data = {};
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;
      if (name != null) data['name'] = name;
      if (role != null) data['role'] = role;
      if (isActive != null) data['is_active'] = isActive;
      
      final response = await _apiService.put<User>(
        '${ApiEndpoints.userById}$userId',
        body: data,
        fromJson: (data) => User.fromJson(data),
      );
      
      if (response.success && response.data != null) {
        final updatedUser = response.data!;
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = updatedUser;
        } else {
          _users.add(updatedUser);
        }
        notifyListeners();
        return updatedUser;
      } else {
        _error = response.message;
        return null;
      }
    } catch (e) {
      _error = 'Error al actualizar usuario: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar contraseña de usuario
  Future<bool> updatePassword(int userId, String newPassword) async {
    _error = null;
    _setLoading(true);
    
    try {
      final response = await _apiService.patch(
        '${ApiEndpoints.userPassword}$userId',
        body: {
          'password': newPassword,
        },
      );
      
      if (response.success) {
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = 'Error al actualizar contraseña: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Cambiar estado de usuario (activar/desactivar)
  Future<bool> changeUserStatus(int userId, bool isActive) async {
    _error = null;
    _setLoading(true);
    
    try {
      final response = await _apiService.patch(
        '${ApiEndpoints.userStatus}$userId',
        body: {
          'is_active': isActive,
        },
      );
      
      if (response.success) {
        // Actualizar usuario en la lista
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isActive: isActive);
          notifyListeners();
        }
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = 'Error al cambiar estado de usuario: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Eliminar un usuario
  Future<bool> deleteUser(int userId) async {
    _error = null;
    _setLoading(true);
    
    try {
      final response = await _apiService.delete(
        '${ApiEndpoints.userById}$userId',
      );
      
      if (response.success) {
        _users.removeWhere((u) => u.id == userId);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = 'Error al eliminar usuario: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtener lista de roles disponibles
  Future<List<String>> fetchRoles() async {
    _error = null;
    
    try {
      final response = await _apiService.get<List<Map<String, dynamic>>>(
        ApiEndpoints.users,
        fromJson: (data) => (data as List)
            .map((item) => item as Map<String, dynamic>)
            .toList(),
      );
      
      if (response.success && response.data != null) {
        // Extraer roles únicos
        final roles = response.data!
            .map((item) => item['name'] as String)
            .toSet()
            .toList();
        return roles;
      } else {
        _error = response.message;
        return ['admin', 'secretary', 'technician']; // Valores por defecto
      }
    } catch (e) {
      _error = 'Error al obtener roles: $e';
      return ['admin', 'secretary', 'technician']; // Valores por defecto en caso de error
    }
  }
  
  // Limpiar datos
  void clearData() {
    _users = [];
    _error = null;
    _isLoading = false;
    _hasMore = true;
    notifyListeners();
  }
  
  // Método privado para actualizar estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Método para buscar un usuario en la lista
  User? findUserById(int userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }
}