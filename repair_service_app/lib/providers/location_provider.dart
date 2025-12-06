import 'package:flutter/foundation.dart';
import 'package:repair_service_app/models/location.dart';
import 'package:repair_service_app/services/location_service.dart';
import 'package:flutter/material.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService;
  
  bool _isLoading = false;
  List<Location> _locations = [];
  String? _error;
  
  // Constructor que acepta un servicio opcional para facilitar pruebas
  LocationProvider({LocationService? locationService})
      : _locationService = locationService ?? LocationService();
  
  // Getters
  bool get isLoading => _isLoading;
  List<Location> get locations => _locations;
  String? get error => _error;
  bool get hasLocations => _locations.isNotEmpty;
  bool get hasError => _error != null;
  
  // Método para cargar todas las ubicaciones
  Future<void> loadLocations() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _locationService.getAllLocations();
      
      if (response.success && response.data != null) {
        _locations = response.data!;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar ubicaciones: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Método para obtener una ubicación por ID
  Location? getLocationById(int locationId) {
    try {
      return _locations.firstWhere((location) => location.id == locationId);
    } catch (e) {
      return null;
    }
  }
  
  // Método para crear una nueva ubicación (solo admin)
  Future<bool> createLocation(String name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _locationService.createLocation(name);
      
      if (response.success && response.data != null) {
        _locations.add(response.data!);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error al crear ubicación: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Método para actualizar una ubicación (solo admin)
  Future<bool> updateLocation(int locationId, String name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _locationService.updateLocation(locationId, name);
      
      if (response.success && response.data != null) {
        final index = _locations.indexWhere((location) => location.id == locationId);
        if (index >= 0) {
          _locations[index] = response.data!;
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error al actualizar ubicación: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Método para eliminar una ubicación (solo admin)
  Future<bool> deleteLocation(int locationId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _locationService.deleteLocation(locationId);
      
      if (response.success) {
        _locations.removeWhere((location) => location.id == locationId);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error al eliminar ubicación: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtener estadísticas de ubicaciones
  Future<void> loadLocationStatistics() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _locationService.getLocationStatistics();
      
      if (response.success && response.data != null) {
        // Actualizar las ubicaciones con estadísticas
        final updatedLocations = response.data!;
        
        // Fusionar con las ubicaciones actuales o reemplazarlas
        if (_locations.isEmpty) {
          _locations = updatedLocations;
        } else {
          // Actualizar cada ubicación con sus estadísticas
          for (final updatedLocation in updatedLocations) {
            final index = _locations.indexWhere((l) => l.id == updatedLocation.id);
            if (index >= 0) {
              _locations[index] = updatedLocation;
            }
          }
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar estadísticas: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Helpers para gestionar estados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  // Método para obtener ubicaciones desde cache o carga completa
  Future<List<Location>> getLocations({bool forceRefresh = false}) async {
    if (_locations.isEmpty || forceRefresh) {
      await loadLocations();
    }
    return _locations;
  }
  
  // Obtener nombre de ubicación por ID (util para mostrar en UI)
  String getLocationNameById(int locationId) {
    final location = getLocationById(locationId);
    return location?.name ?? 'Ubicación Desconocida';
  }
  
  // Obtener lista de ubicaciones para usar en dropdowns
  List<DropdownMenuItem<int>> getLocationDropdownItems() {
    return _locations
        .map((location) => DropdownMenuItem<int>(
              value: location.id,
              child: Text(location.name),
            ))
        .toList();
  }
  
  // Obtener lista predefinida si aún no hay datos
  List<Location> getPredefinedLocations() {
    if (_locations.isEmpty) {
      return Location.getPredefinedLocations();
    }
    return _locations;
  }
}