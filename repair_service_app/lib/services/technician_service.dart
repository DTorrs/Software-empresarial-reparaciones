import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/services/api_service.dart';

class TechnicianService {
  final ApiService _apiService;
  
  TechnicianService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Obtener todos los técnicos
  Future<ApiResponse<List<Technician>>> getAllTechnicians() async {
    final response = await _apiService.get<List<Technician>>(
      ApiEndpoints.technicians,
      fromJson: (json) => (json as List)
          .map((item) => Technician.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener técnico por ID
  Future<ApiResponse<Technician>> getTechnicianById(int technicianId) async {
    final response = await _apiService.get<Technician>(
      '${ApiEndpoints.technicianById}$technicianId',
      fromJson: (json) => Technician.fromJson(json),
    );
    return response;
  }
  
  // Obtener técnicos por ubicación
  Future<ApiResponse<List<Technician>>> getTechniciansByLocation(int locationId) async {
    final response = await _apiService.get<List<Technician>>(
      '${ApiEndpoints.techniciansByLocation}$locationId',
      fromJson: (json) => (json as List)
          .map((item) => Technician.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener técnicos disponibles
// In your TechnicianService class
Future<ApiResponse<List<Technician>>> getAvailableTechnicians({int? locationId}) async {
  try {
    final Map<String, String> queryParams = {};
    if (locationId != null) {
      queryParams['location_id'] = locationId.toString(); // Changed to snake_case
    }
    
    print("Requesting available technicians with params: $queryParams");
    print("URL: ${ApiEndpoints.availableTechniciansByLocation}");
    
    final response = await _apiService.get<List<Technician>>(
      ApiEndpoints.availableTechniciansByLocation,
      queryParams: queryParams,
      fromJson: (json) {
        print("API response data: $json"); // Debug the raw response
        print("API response type: ${json.runtimeType}"); // Check the type
        
        try {
          final technicians = (json as List)
              .map((item) {
                print("Processing item: $item"); // Debug each item
                return Technician.fromJson(item);
              })
              .toList();
          return technicians;
        } catch (e) {
          print("Error parsing technicians: $e");
          throw e; // Re-throw to be caught by the outer try-catch
        }
      },
    );
    return response;
  } catch (e) {
    print("Error in getAvailableTechnicians: $e");
    return ApiResponse(
      success: false,
      message: 'Error al obtener técnicos: $e',
    );
  }
}
  // Crear técnico
// Añadir a la clase TechnicianService
// Crear técnico
Future<ApiResponse<Technician>> createTechnician({
  required int userId,
  required int locationId,
}) async {
  final response = await _apiService.post<Technician>(
    ApiEndpoints.technicians,
    body: {
      'user_id': userId,
      'location_id': locationId,
    },
    fromJson: (json) => Technician.fromJson(json),
  );
  return response;
}


// Eliminar técnico
Future<ApiResponse<void>> deleteTechnician(int technicianId) async {
  final response = await _apiService.delete(
    '${ApiEndpoints.technicianById}$technicianId',
  );
  return response;
}
  
  // Actualizar técnico
  Future<ApiResponse<Technician>> updateTechnician(
    int technicianId, {
    int? locationId,
    bool? isAvailable,
  }) async {
    final Map<String, dynamic> data = {};
    if (locationId != null) data['location_id'] = locationId;
    if (isAvailable != null) data['is_available'] = isAvailable;
    
    final response = await _apiService.put<Technician>(
      '${ApiEndpoints.technicianById}$technicianId',
      body: data,
      fromJson: (json) => Technician.fromJson(json),
    );
    return response;
  }
  
  // Obtener servicios del técnico
  Future<ApiResponse<List<Service>>> getTechnicianServices(int technicianId) async {
    final response = await _apiService.get<List<Service>>(
      '${ApiEndpoints.technicianServices}$technicianId',
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener servicios completados del técnico
  Future<ApiResponse<List<Service>>> getTechnicianCompletedServices(int technicianId) async {
    final response = await _apiService.get<List<Service>>(
      '${ApiEndpoints.technicianCompletedServices}$technicianId',
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener rendimiento del técnico
  Future<ApiResponse<Map<String, dynamic>>> getTechnicianPerformance(int technicianId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiEndpoints.technicianPerformance}$technicianId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response;
  }
  
  // Actualizar tasa de finalización del técnico
  Future<ApiResponse<Map<String, dynamic>>> updateTechnicianCompletionRate(int technicianId) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '${ApiEndpoints.technicianCompletionRate}$technicianId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response;
  }
  
  // Verificar estado de garantías pendientes
  Future<ApiResponse<Map<String, dynamic>>> checkWarrantyPendingStatus(int technicianId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiEndpoints.technicianWarrantyStatus}$technicianId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response;
  }
  
  // Obtener dashboard del técnico
  Future<ApiResponse<Map<String, dynamic>>> getTechnicianDashboard(int technicianId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiEndpoints.technicianDashboard}$technicianId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response;
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getMyDashboard() async {
  print('Llamando a: ${ApiEndpoints.technicianMyDashboard}');
  final response = await _apiService.get<Map<String, dynamic>>(
    ApiEndpoints.technicianMyDashboard,
    fromJson: (json) => json as Map<String, dynamic>,
  );
  print('Respuesta del backend: ${response.success}, ${response.message}, ${response.data}');
  return response;
}
}