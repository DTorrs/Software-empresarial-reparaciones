// client_service.dart
import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/client.dart';
import 'package:repair_service_app/services/api_service.dart';

class ClientService {
  final ApiService _apiService;
  
  ClientService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Obtener todos los clientes
  Future<ApiResponse<List<Client>>> getAllClients() async {
    try {
      print("Requesting all clients from: ${ApiEndpoints.clients}");
      
      // Use our regular API call with extra debug logging
      final response = await _apiService.get<List<Client>>(
        ApiEndpoints.clients,
        fromJson: (json) {
          print("Processing JSON response: $json");
          print("Response type: ${json.runtimeType}");
          
          try {
            if (json is! List) {
              print("WARNING: Expected List but got ${json.runtimeType}");
              // If we got a Map instead of a List, it might be an error response
              if (json is Map) {
                print("Map keys: ${json.keys.toList()}");
                // If this is the error response, throw to trigger the catch block
                throw FormatException("Received unexpected format: $json");
              }
            }
            
            return (json as List).map((item) => Client.fromJson(item)).toList();
          } catch (e) {
            print("Error parsing clients: $e");
            print("Error stack trace: ${StackTrace.current}");
            throw e;
          }
        },
      );
      
      print("API Response: $response");
      print("Response type: ${response.runtimeType}");
      
      return response;
    } catch (e) {
      print("Error in getAllClients: $e");
      return ApiResponse<List<Client>>(
        success: false,
        message: 'Error al obtener clientes: $e',
        data: [],
      );
    }
  }
  
  // Obtener cliente por ID
  Future<ApiResponse<Client>> getClientById(int clientId) async {
    try {
      final response = await _apiService.get<Client>(
        '${ApiEndpoints.clientById}$clientId',
        fromJson: (json) => Client.fromJson(json),
      );
      return response;
    } catch (e) {
      print("Error getting client by ID: $e");
      return ApiResponse<Client>(
        success: false,
        message: 'Error al obtener cliente: $e',
      );
    }
  }
  
  // Obtener clientes por ubicación
  Future<ApiResponse<List<Client>>> getClientsByLocation(int locationId) async {
    try {
      final response = await _apiService.get<List<Client>>(
        '${ApiEndpoints.clientsByLocation}$locationId',
        fromJson: (json) => (json as List)
            .map((item) => Client.fromJson(item))
            .toList(),
      );
      return response;
    } catch (e) {
      print("Error getting clients by location: $e");
      return ApiResponse<List<Client>>(
        success: false,
        message: 'Error al obtener clientes por ubicación: $e',
        data: [],
      );
    }
  }
  
  // Obtener historial de servicios del cliente
  Future<ApiResponse<List<dynamic>>> getClientServiceHistory(int clientId) async {
    final response = await _apiService.get<List<dynamic>>(
      '${ApiEndpoints.clientServiceHistory}$clientId',
      fromJson: (json) => json as List,
    );
    return response;
  }
  
  // Buscar clientes por término
  Future<ApiResponse<List<Client>>> searchClients(String term) async {
    final response = await _apiService.get<List<Client>>(
      ApiEndpoints.searchClients,
      queryParams: {
        'term': term,
      },
      fromJson: (json) => (json as List)
          .map((item) => Client.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Crear cliente
  Future<ApiResponse<Client>> createClient(Map<String, dynamic> clientData) async {
    final response = await _apiService.post<Client>(
      ApiEndpoints.clients,
      body: clientData,
      fromJson: (json) => Client.fromJson(json),
    );
    return response;
  }
  
  // Actualizar cliente
  Future<ApiResponse<Client>> updateClient(int clientId, Map<String, dynamic> clientData) async {
    final response = await _apiService.put<Client>(
      '${ApiEndpoints.clientById}$clientId',
      body: clientData,
      fromJson: (json) => Client.fromJson(json),
    );
    return response;
  }
  
  // Eliminar cliente
  Future<ApiResponse<void>> deleteClient(int clientId) async {
    final response = await _apiService.delete(
      '${ApiEndpoints.clientById}$clientId',
    );
    return response;
  }
}