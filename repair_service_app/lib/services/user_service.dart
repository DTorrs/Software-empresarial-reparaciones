import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/api_service.dart';

class UserService {
  final ApiService _apiService;
  
  UserService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Obtener todos los usuarios
  Future<ApiResponse<List<User>>> getAllUsers() async {
    final response = await _apiService.get<List<User>>(
      ApiEndpoints.users,
      fromJson: (json) => (json as List)
          .map((item) => User.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener usuario por ID
  Future<ApiResponse<User>> getUserById(int userId) async {
    final response = await _apiService.get<User>(
      '${ApiEndpoints.userById}$userId',
      fromJson: (json) => User.fromJson(json),
    );
    return response;
  }
  
  // Obtener usuarios por rol
  Future<ApiResponse<List<User>>> getUsersByRole(String role) async {
    final response = await _apiService.get<List<User>>(
      '${ApiEndpoints.usersByRole}$role',
      fromJson: (json) => (json as List)
          .map((item) => User.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Crear usuario
  Future<ApiResponse<User>> createUser({
    required String username,
    required String password,
    required String email,
    required String name,
    required String role,
  }) async {
    final response = await _apiService.post<User>(
      ApiEndpoints.users,
      body: {
        'username': username,
        'password': password,
        'email': email,
        'name': name,
        'role': role,
      },
      fromJson: (json) => User.fromJson(json),
    );
    return response;
  }
  
  // Actualizar usuario
  Future<ApiResponse<User>> updateUser(
    int userId, {
    String? username,
    String? email,
    String? name,
    String? role,
  }) async {
    final Map<String, dynamic> userData = {};
    if (username != null) userData['username'] = username;
    if (email != null) userData['email'] = email;
    if (name != null) userData['name'] = name;
    if (role != null) userData['role'] = role;
    
    final response = await _apiService.put<User>(
      '${ApiEndpoints.userById}$userId',
      body: userData,
      fromJson: (json) => User.fromJson(json),
    );
    return response;
  }
  
  // Eliminar usuario
  Future<ApiResponse<void>> deleteUser(int userId) async {
    final response = await _apiService.delete(
      '${ApiEndpoints.userById}$userId',
    );
    return response;
  }
  
  // Actualizar contraseña
  Future<ApiResponse<void>> updatePassword(int userId, String newPassword) async {
    final response = await _apiService.patch(
      '${ApiEndpoints.userPassword}$userId/password',
      body: {
        'password': newPassword,
      },
    );
    return response;
  }
  
  // Cambiar estado del usuario (activar/desactivar)
  Future<ApiResponse<void>> changeUserStatus(int userId, bool isActive) async {
    final response = await _apiService.patch(
      '${ApiEndpoints.userStatus}$userId/status',
      body: {
        'is_active': isActive,
      },
    );
    return response;
  }
  
  // Obtener roles disponibles
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoles() async {
    final response = await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.users + '/roles',
      fromJson: (json) => (json as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
    return response;
  }
}