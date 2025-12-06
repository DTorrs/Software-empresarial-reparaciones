import 'package:flutter/foundation.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/utils/secure_storage.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final SecureStorage _secureStorage;
  
  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _error;
  bool _isLoading = false;
  
  AuthProvider({
    AuthService? authService,
    SecureStorage? secureStorage,
  }) : _authService = authService ?? AuthService(),
       _secureStorage = secureStorage ?? SecureStorage() {
    // Verificar autenticación al iniciar
    _checkAuthentication();
  }
  
  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSecretary => _currentUser?.isSecretary ?? false;
  bool get isTechnician => _currentUser?.isTechnician ?? false;
  
  // Iniciar sesión
  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    try {
      _setAuthenticating();
      
      final response = await _authService.login(username, password);
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _status = AuthStatus.authenticated;
        _error = null;
        
        // Guardar preferencia de recordar si está activada
        if (rememberMe) {
          await _secureStorage.saveRememberMe(true);
        }
        
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'Error al iniciar sesión: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }
  
  // Cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = 'Error al cerrar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Verificar autenticación actual
  Future<void> _checkAuthentication() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final hasToken = await _authService.isLoggedIn();
      
      if (hasToken) {
        final response = await _authService.verifyToken();
        
        if (response.success && response.data != null) {
          _currentUser = response.data;
          _status = AuthStatus.authenticated;
          _error = null;
        } else {
          _status = AuthStatus.unauthenticated;
          _error = 'Sesión expirada';
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'Error al verificar autenticación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refrescar información del usuario actual
  Future<void> refreshUserInfo() async {
    if (_status != AuthStatus.authenticated) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _authService.verifyToken();
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _status = AuthStatus.authenticated;
        _error = null;
      } else {
        // Token inválido, cerrar sesión
        await logout();
      }
    } catch (e) {
      _error = 'Error al actualizar información de usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Actualizar estado a autenticando
  void _setAuthenticating() {
    _status = AuthStatus.authenticating;
    _isLoading = true;
    notifyListeners();
  }
  
  // Verificar si hay un token válido y devolver el rol del usuario
  Future<String?> getUserRole() async {
    try {
      if (_currentUser != null) {
        return _currentUser!.role;
      }
      
      final hasToken = await _authService.isLoggedIn();
      if (hasToken) {
        final role = await _authService.getCurrentUserRole();
        return role;
      }
      
      return null;
    } catch (e) {
      _error = 'Error al obtener rol de usuario: $e';
      return null;
    }
  }
  
  // Actualizar usuario actual (después de un cambio de perfil)
  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}