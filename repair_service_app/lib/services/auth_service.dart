import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/api_service.dart';
import 'package:repair_service_app/utils/secure_storage.dart';

class AuthService {
  final ApiService _apiService;
  final SecureStorage _secureStorage;
  
  AuthService({
    ApiService? apiService,
    SecureStorage? secureStorage,
  }) : _apiService = apiService ?? ApiService(),
       _secureStorage = secureStorage ?? SecureStorage();
  
 Future<ApiResponse<User>> login(String username, String password) async {
  try {
    print('Intentando login con: $username');
    
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      body: {
        'username': username,
        'password': password,
      },
      requireAuth: false,
      fromJson: (json) => json,
    );
    
    print('Respuesta del servidor: ${response.success}, mensaje: ${response.message}');
    
    if (response.success && response.data != null) {
      try {
        print('Datos de respuesta: ${response.data}');
        
        final token = response.data!['token'] as String;
        final userData = response.data!['user'] as Map<String, dynamic>;
        
        print('Token obtenido. Datos de usuario: $userData');
        
        // Guardar token
        await _secureStorage.saveToken(token);
        
        // Crear usuario
        final user = User.fromJson(userData);
        
        return ApiResponse(
          success: true,
          message: response.message,
          data: user,
        );
      } catch (e, stackTrace) {
        print('Error procesando datos de login: $e');
        print('Stack trace: $stackTrace');
        return ApiResponse(
          success: false,
          message: 'Error al procesar datos de usuario: $e',
        );
      }
    }
    
    return ApiResponse(
      success: false,
      message: response.message,
      errors: response.errors,
    );
  } catch (e) {
    print('Error general en login: $e');
    return ApiResponse(
      success: false,
      message: 'Error inesperado: $e',
    );
  }
}
  
  // Verificar token
  Future<ApiResponse<User>> verifyToken() async {
    final token = await _secureStorage.getToken();
    
    if (token == null) {
      return ApiResponse(
        success: false,
        message: 'No hay token almacenado',
      );
    }
    
    final response = await _apiService.get<User>(
      ApiEndpoints.verifyToken,
      requireAuth: true,
      fromJson: (json) => User.fromJson(json),
    );
    
    return response;
  }
  
  // Cerrar sesión
  Future<void> logout() async {
    await _secureStorage.deleteToken();
  }
  
  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getToken();
    return token != null;
  }
  
  // Obtener el rol del usuario actual
  Future<String?> getCurrentUserRole() async {
    final tokenResponse = await verifyToken();
    if (tokenResponse.success && tokenResponse.data != null) {
      return tokenResponse.data!.role;
    }
    return null;
  }
}