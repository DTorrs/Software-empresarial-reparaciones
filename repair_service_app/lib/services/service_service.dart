import 'dart:io';
import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/services/api_service.dart';

class ServiceService {
  final ApiService _apiService;
  
  ServiceService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  Future<ApiResponse<Service>> createService(Map<String, dynamic> serviceData) async {
  final response = await _apiService.post<Service>(
    ApiEndpoints.services, // Endpoint para crear servicios
    body: serviceData,
    fromJson: (json) => Service.fromJson(json),
  );
  return response;
}
 Future<ApiResponse<Service>> updateService(int serviceId, Map<String, dynamic> updatedData) async {
    final response = await _apiService.put<Service>(
      '${ApiEndpoints.serviceById}$serviceId',
      body: updatedData,
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  // Obtener estadísticas de servicios
Future<ApiResponse<Map<String, dynamic>>> getServiceStatistics() async {
  final response = await _apiService.get<Map<String, dynamic>>(
    ApiEndpoints.serviceStatistics,
    fromJson: (json) => json as Map<String, dynamic>,
  );
  return response;
}



  // Obtener todos los servicios
  Future<ApiResponse<List<Service>>> getAllServices() async {
    final response = await _apiService.get<List<Service>>(
      ApiEndpoints.services,
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener servicio por ID
  Future<ApiResponse<Service>> getServiceById(int serviceId) async {
    final response = await _apiService.get<Service>(
      '${ApiEndpoints.serviceById}$serviceId',
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  
  // Obtener servicios por estado
  Future<ApiResponse<List<Service>>> getServicesByStatus(String status) async {
    final response = await _apiService.get<List<Service>>(
      '${ApiEndpoints.servicesByStatus}$status',
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener servicios por técnico
  Future<ApiResponse<List<Service>>> getServicesByTechnician(int technicianId, {String? status}) async {
    final Map<String, String> queryParams = {};
    if (status != null) {
      queryParams['status'] = status;
    }
    
    final response = await _apiService.get<List<Service>>(
      '${ApiEndpoints.servicesByTechnician}$technicianId',
      queryParams: queryParams,
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener servicios de garantía
  Future<ApiResponse<List<Service>>> getWarrantyServices() async {
    final response = await _apiService.get<List<Service>>(
      ApiEndpoints.warrantyServices,
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Cambiar estado de servicio
  Future<ApiResponse<Service>> updateServiceStatus(int serviceId, String status) async {
    final response = await _apiService.patch<Service>(
      '${ApiEndpoints.serviceStatus}$serviceId',
      body: {
        'status': status,
      },
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  
  // Asignar técnico a servicio
  Future<ApiResponse<Service>> assignTechnician(int serviceId, int technicianId) async {
    final response = await _apiService.patch<Service>(
      '${ApiEndpoints.assignTechnician}$serviceId',
      body: {
        'technician_id': technicianId,
      },
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  
  // Actualizar precio estimado
  Future<ApiResponse<Service>> updateEstimatedPrice(int serviceId, double price) async {
    final response = await _apiService.patch<Service>(
      '${ApiEndpoints.estimatedPrice}$serviceId',
      body: {
        'price': price,
      },
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  
  // Actualizar precio final
  Future<ApiResponse<Service>> updateFinalPrice(int serviceId, double price) async {
    final response = await _apiService.patch<Service>(
      '${ApiEndpoints.finalPrice}$serviceId',
      body: {
        'price': price,
      },
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  
  // Subir foto de servicio
  Future<ApiResponse<ServicePhoto>> uploadServicePhoto(
    int serviceId,
    File photo,
    String photoType,
  ) async {
    final response = await _apiService.uploadFile<ServicePhoto>(
      '${ApiEndpoints.uploadPhoto}$serviceId/photos',
      photo,
      'photo',
      fields: {
        'photo_type': photoType,
      },
      fromJson: (json) => ServicePhoto.fromJson(json),
    );
    return response;
  }
  
  // Eliminar foto de servicio
  Future<ApiResponse<void>> removeServicePhoto(int photoId) async {
    final response = await _apiService.delete(
      '${ApiEndpoints.removePhoto}$photoId',
    );
    return response;
  }
  
  // Crear servicio de garantía
  Future<ApiResponse<Service>> createWarrantyService(int originalServiceId) async {
    final response = await _apiService.post<Service>(
      ApiEndpoints.createWarranty,
      body: {
        'original_service_id': originalServiceId,
      },
      fromJson: (json) => Service.fromJson(json),
    );
    return response;
  }
  
  // Obtener técnicos disponibles
  Future<ApiResponse<List<Technician>>> getAvailableTechnicians({int? locationId}) async {
    final Map<String, String> queryParams = {};
    if (locationId != null) {
      queryParams['location_id'] = locationId.toString();
    }
    
    final response = await _apiService.get<List<Technician>>(
      ApiEndpoints.availableTechnicians,
      queryParams: queryParams,
      fromJson: (json) => (json as List)
          .map((item) => Technician.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Calcular pago para técnico por servicio
  Future<ApiResponse<Map<String, dynamic>>> calculateTechnicianPayment(int serviceId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiEndpoints.servicePayment}$serviceId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response;
  }
  
  // Buscar servicios
  Future<ApiResponse<List<Service>>> searchServices(String term) async {
    final response = await _apiService.get<List<Service>>(
      ApiEndpoints.services,
      queryParams: {
        'term': term,
      },
      fromJson: (json) => (json as List)
          .map((item) => Service.fromJson(item))
          .toList(),
    );
    return response;
  }
  
}