import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/location.dart';
import 'package:repair_service_app/services/api_service.dart';

class LocationService {
  final ApiService _apiService;
  
  LocationService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Obtener todas las ubicaciones
  Future<ApiResponse<List<Location>>> getAllLocations() async {
    final response = await _apiService.get<List<Location>>(
      ApiEndpoints.locations,
      fromJson: (json) => (json as List)
          .map((item) => Location.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener ubicación por ID
  Future<ApiResponse<Location>> getLocationById(int locationId) async {
    final response = await _apiService.get<Location>(
      '${ApiEndpoints.locationById}$locationId',
      fromJson: (json) => Location.fromJson(json),
    );
    return response;
  }
  
  // Crear nueva ubicación (solo admin)
  Future<ApiResponse<Location>> createLocation(String name) async {
    final response = await _apiService.post<Location>(
      ApiEndpoints.locations,
      body: {
        'name': name,
      },
      fromJson: (json) => Location.fromJson(json),
    );
    return response;
  }
  
  // Actualizar ubicación (solo admin)
  Future<ApiResponse<Location>> updateLocation(int locationId, String name) async {
    final response = await _apiService.put<Location>(
      '${ApiEndpoints.locationById}$locationId',
      body: {
        'name': name,
      },
      fromJson: (json) => Location.fromJson(json),
    );
    return response;
  }
  
  // Eliminar ubicación (solo admin)
  Future<ApiResponse<void>> deleteLocation(int locationId) async {
    final response = await _apiService.delete(
      '${ApiEndpoints.locationById}$locationId',
    );
    return response;
  }
  
  // Obtener estadísticas de ubicaciones
  Future<ApiResponse<List<Location>>> getLocationStatistics() async {
    final response = await _apiService.get<List<Location>>(
      ApiEndpoints.locationStatistics,
      fromJson: (json) => (json as List)
          .map((item) => Location.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener conteo de técnicos por ubicación
  Future<ApiResponse<List<Map<String, dynamic>>>> getTechniciansCountByLocation() async {
    final response = await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.locationTechnicians,
      fromJson: (json) => (json as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
    return response;
  }
  
  // Obtener conteo de servicios por ubicación
  Future<ApiResponse<List<Map<String, dynamic>>>> getServicesCountByLocation() async {
    final response = await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.locationServices,
      fromJson: (json) => (json as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
    return response;
  }
}