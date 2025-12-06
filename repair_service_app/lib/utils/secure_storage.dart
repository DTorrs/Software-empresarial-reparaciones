import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String technicianIdKey = 'technician_id';
  static const String rememberKey = 'remember_me';
  
  final FlutterSecureStorage _storage;
  
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  
  // Guardar token
  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }
  
  // Obtener token
  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }
  
  // Eliminar token
  Future<void> deleteToken() async {
    await _storage.delete(key: tokenKey);
  }
  
  // Guardar ID de usuario
  Future<void> saveUserId(int userId) async {
    await _storage.write(key: userIdKey, value: userId.toString());
  }
  
  // Obtener ID de usuario
  Future<int?> getUserId() async {
    final value = await _storage.read(key: userIdKey);
    return value != null ? int.parse(value) : null;
  }
  
  // Guardar rol de usuario
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: userRoleKey, value: role);
  }
  
  // Obtener rol de usuario
  Future<String?> getUserRole() async {
    return await _storage.read(key: userRoleKey);
  }
  
  // Guardar ID de técnico (solo para usuarios con rol de técnico)
  Future<void> saveTechnicianId(int technicianId) async {
    await _storage.write(key: technicianIdKey, value: technicianId.toString());
  }
  
  // Obtener ID de técnico
  Future<int?> getTechnicianId() async {
    final value = await _storage.read(key: technicianIdKey);
    return value != null ? int.parse(value) : null;
  }
  
  // Guardar datos de sesión completos
  Future<void> saveSessionData({
    required String token,
    required int userId,
    required String role,
    int? technicianId,
  }) async {
    await saveToken(token);
    await saveUserId(userId);
    await saveUserRole(role);
    if (technicianId != null) {
      await saveTechnicianId(technicianId);
    }
  }
  
  // Limpiar datos de sesión
  Future<void> clearSessionData() async {
    await _storage.deleteAll();
  }
  
  // Guardar preferencia de recordar usuario
  Future<void> saveRememberMe(bool remember) async {
    await _storage.write(key: rememberKey, value: remember.toString());
  }
  
  // Obtener preferencia de recordar usuario
  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: rememberKey);
    return value == 'true';
  }
}