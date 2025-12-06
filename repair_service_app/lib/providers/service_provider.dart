import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/services/api_service.dart';


class ServiceProvider with ChangeNotifier {
  final ServiceService _serviceService;
  final TechnicianService _technicianService;
  
  bool _isLoading = false;
  List<Service> _services = [];
  Service? _currentService;
  List<Technician> _availableTechnicians = [];
  String? _error;
  
  // Filtros y estados
  String? _statusFilter;
  int? _locationFilter;
  int? _technicianFilter;
  bool _onlyWarranties = false;
  String _searchQuery = '';
  
  // Constructor
  ServiceProvider({
    ServiceService? serviceService,
    TechnicianService? technicianService,
  })  : _serviceService = serviceService ?? ServiceService(),
        _technicianService = technicianService ?? TechnicianService();
  
  // Getters
  bool get isLoading => _isLoading;
  List<Service> get services => _getFilteredServices();
  Service? get currentService => _currentService;
  List<Technician> get availableTechnicians => _availableTechnicians;
  String? get error => _error;
  bool get hasServices => _services.isNotEmpty;
  bool get hasFilteredServices => _getFilteredServices().isNotEmpty;
  bool get hasError => _error != null;
  
  // Getters para filtros
  String? get statusFilter => _statusFilter;
  int? get locationFilter => _locationFilter;
  int? get technicianFilter => _technicianFilter;
  bool get onlyWarranties => _onlyWarranties;
  String get searchQuery => _searchQuery;
  
  // Método para filtrar servicios según criterios establecidos
  List<Service> _getFilteredServices() {
    return _services.where((service) {
      // Filtrar por estado
      if (_statusFilter != null && service.status != _statusFilter) {
        return false;
      }
      
      // Filtrar por técnico
      if (_technicianFilter != null && 
          (service.technicianId == null || service.technicianId != _technicianFilter)) {
        return false;
      }
      
      // Filtrar por ubicación de cliente
      if (_locationFilter != null && 
          (service.clientLocationName == null || 
           !service.clientLocationName!.toLowerCase().contains(_getLocationName(_locationFilter!).toLowerCase()))) {
        return false;
      }
      
      // Filtrar solo garantías
      if (_onlyWarranties && !service.isWarranty) {
        return false;
      }
      
      // Filtrar por texto de búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return service.deviceType.toLowerCase().contains(query) ||
               service.deviceBrand.toLowerCase().contains(query) ||
               service.issueDescription.toLowerCase().contains(query) ||
               service.clientName.toLowerCase().contains(query) ||
               service.id.toString().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  // Helper para obtener nombre de ubicación (implementación básica)
  String _getLocationName(int locationId) {
    // En un proyecto real, esto podría venir del LocationProvider
    switch (locationId) {
      case 1: return 'CDMX';
      case 2: return 'Estado de México';
      case 3: return 'Monterrey';
      case 4: return 'Guadalajara';
      case 5: return 'Querétaro';
      case 6: return 'Veracruz';
      case 7: return 'Puebla';
      case 8: return 'Cancún';
      case 9: return 'Baja California Sur';
      default: return 'Indefinido';
    }
  }
  
  // Métodos de filtrado
  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }
  
  void setLocationFilter(int? locationId) {
    _locationFilter = locationId;
    notifyListeners();
  }
  
  void setTechnicianFilter(int? technicianId) {
    _technicianFilter = technicianId;
    notifyListeners();
  }
  
  void setOnlyWarranties(bool value) {
    _onlyWarranties = value;
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void clearFilters() {
    _statusFilter = null;
    _locationFilter = null;
    _technicianFilter = null;
    _onlyWarranties = false;
    _searchQuery = '';
    notifyListeners();
  }
  
  // Cargar todos los servicios
  Future<void> loadServices() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.getAllServices();
      
      if (response.success && response.data != null) {
        _services = response.data!;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar servicios: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cargar servicios por estado
  Future<void> loadServicesByStatus(String status) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.getServicesByStatus(status);
      
      if (response.success && response.data != null) {
        _services = response.data!;
        _statusFilter = status;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar servicios por estado: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cargar servicios por técnico
  Future<void> loadServicesByTechnician(int technicianId, {String? status}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.getServicesByTechnician(technicianId, status: status);
      
      if (response.success && response.data != null) {
        _services = response.data!;
        _technicianFilter = technicianId;
        _statusFilter = status;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar servicios por técnico: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cargar servicios de garantía
  Future<void> loadWarrantyServices() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.getWarrantyServices();
      
      if (response.success && response.data != null) {
        _services = response.data!;
        _onlyWarranties = true;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar servicios de garantía: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Búsqueda de servicios
  Future<void> searchServices(String query) async {
    if (query.isEmpty) {
      // Si la búsqueda está vacía, simplemente aplicar el filtro local
      setSearchQuery('');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.searchServices(query);
      
      if (response.success && response.data != null) {
        _services = response.data!;
        _searchQuery = query;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al buscar servicios: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cargar un servicio específico
  Future<void> loadServiceById(int serviceId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.getServiceById(serviceId);
      
      if (response.success && response.data != null) {
        _currentService = response.data;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar servicio: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Crear un nuevo servicio
  Future<ApiResponse<Service>> createService(Map<String, dynamic> serviceData) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Este método devuelve la respuesta directamente para que la UI pueda manejarla
      final response = await _serviceService.createService(serviceData);
      
      if (response.success && response.data != null) {
        // Añadir el nuevo servicio a la lista si ya tenemos servicios cargados
        if (_services.isNotEmpty) {
          _services.insert(0, response.data!);
          notifyListeners();
        }
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al crear servicio: $e');
      return ApiResponse(success: false, message: 'Error al crear servicio: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar un servicio existente
  Future<ApiResponse<Service>> updateService(int serviceId, Map<String, dynamic> updatedData) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.updateService(serviceId, updatedData);
      
      if (response.success && response.data != null) {
        // Actualizar en la lista actual si existe
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index >= 0) {
          _services[index] = response.data!;
        }
        
        // Actualizar servicio actual si coincide
        if (_currentService != null && _currentService!.id == serviceId) {
          _currentService = response.data;
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al actualizar servicio: $e');
      return ApiResponse(success: false, message: 'Error al actualizar servicio: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar estado de un servicio
  Future<ApiResponse<Service>> updateServiceStatus(int serviceId, String status) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.updateServiceStatus(serviceId, status);
      
      if (response.success && response.data != null) {
        // Actualizar en la lista actual si existe
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index >= 0) {
          _services[index] = response.data!;
        }
        
        // Actualizar servicio actual si coincide
        if (_currentService != null && _currentService!.id == serviceId) {
          _currentService = response.data;
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al actualizar estado del servicio: $e');
      return ApiResponse(success: false, message: 'Error al actualizar estado: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Asignar técnico a un servicio
  Future<ApiResponse<Service>> assignTechnician(int serviceId, int technicianId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.assignTechnician(serviceId, technicianId);
      
      if (response.success && response.data != null) {
        // Actualizar en la lista actual si existe
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index >= 0) {
          _services[index] = response.data!;
        }
        
        // Actualizar servicio actual si coincide
        if (_currentService != null && _currentService!.id == serviceId) {
          _currentService = response.data;
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al asignar técnico: $e');
      return ApiResponse(success: false, message: 'Error al asignar técnico: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar precio estimado
  Future<ApiResponse<Service>> updateEstimatedPrice(int serviceId, double price) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.updateEstimatedPrice(serviceId, price);
      
      if (response.success && response.data != null) {
        // Actualizar en la lista actual si existe
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index >= 0) {
          _services[index] = response.data!;
        }
        
        // Actualizar servicio actual si coincide
        if (_currentService != null && _currentService!.id == serviceId) {
          _currentService = response.data;
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al actualizar precio estimado: $e');
      return ApiResponse(success: false, message: 'Error al actualizar precio estimado: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar precio final
  Future<ApiResponse<Service>> updateFinalPrice(int serviceId, double price) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.updateFinalPrice(serviceId, price);
      
      if (response.success && response.data != null) {
        // Actualizar en la lista actual si existe
        final index = _services.indexWhere((s) => s.id == serviceId);
        if (index >= 0) {
          _services[index] = response.data!;
        }
        
        // Actualizar servicio actual si coincide
        if (_currentService != null && _currentService!.id == serviceId) {
          _currentService = response.data;
        }
        
        notifyListeners();
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al actualizar precio final: $e');
      return ApiResponse(success: false, message: 'Error al actualizar precio final: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Subir foto de servicio
  Future<ApiResponse<ServicePhoto>> uploadServicePhoto(
    int serviceId,
    File photo,
    String photoType,
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.uploadServicePhoto(serviceId, photo, photoType);
      
      if (response.success && response.data != null) {
        // Recargar el servicio para obtener la foto actualizada
        await loadServiceById(serviceId);
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al subir foto: $e');
      return ApiResponse(success: false, message: 'Error al subir foto: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Eliminar foto de servicio
  Future<ApiResponse<void>> removeServicePhoto(int photoId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.removeServicePhoto(photoId);
      
      if (response.success && _currentService != null) {
        // Recargar el servicio actual para actualizar las fotos
        await loadServiceById(_currentService!.id);
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al eliminar foto: $e');
      return ApiResponse(success: false, message: 'Error al eliminar foto: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Crear servicio de garantía
  Future<ApiResponse<Service>> createWarrantyService(int originalServiceId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.createWarrantyService(originalServiceId);
      
      if (response.success && response.data != null) {
        // Añadir el nuevo servicio de garantía a la lista si ya tenemos servicios cargados
        if (_services.isNotEmpty) {
          _services.insert(0, response.data!);
          notifyListeners();
        }
      } else {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al crear garantía: $e');
      return ApiResponse(success: false, message: 'Error al crear garantía: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cargar técnicos disponibles
  Future<void> loadAvailableTechnicians({int? locationId}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.getAvailableTechnicians(locationId: locationId);
      
      if (response.success && response.data != null) {
        _availableTechnicians = response.data!;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error al cargar técnicos disponibles: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Calcular pago para un servicio
  Future<ApiResponse<Map<String, dynamic>>> calculateTechnicianPayment(int serviceId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _serviceService.calculateTechnicianPayment(serviceId);
      
      if (!response.success) {
        _setError(response.message);
      }
      
      return response;
    } catch (e) {
      _setError('Error al calcular pago: $e');
      return ApiResponse(success: false, message: 'Error al calcular pago: $e');
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
  
  // Método para obtener servicios con datos actuales o forzar recarga
  Future<List<Service>> getServices({bool forceRefresh = false}) async {
    if (_services.isEmpty || forceRefresh) {
      await loadServices();
    }
    return services;
  }
  
  // Estadísticas básicas
  int get totalServices => _services.length;
  
  int getServiceCountByStatus(String status) {
    return _services.where((service) => service.status == status).length;
  }
  
  int get warrantyServicesCount => 
      _services.where((service) => service.isWarranty).length;
  
  // Seleccionar y limpiar servicio actual
  void selectService(Service service) {
    _currentService = service;
    notifyListeners();
  }
  
  void clearCurrentService() {
    _currentService = null;
    notifyListeners();
  }
}