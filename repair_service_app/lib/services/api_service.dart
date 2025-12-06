import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/utils/secure_storage.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;
  
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json, T? Function(dynamic)? fromJsonT) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      errors: json['errors'],
    );
  }
}

class ApiService {
  final http.Client _httpClient;
  final SecureStorage _secureStorage;
  
  ApiService({
    http.Client? httpClient,
    SecureStorage? secureStorage,
  }) : _httpClient = httpClient ?? http.Client(),
       _secureStorage = secureStorage ?? SecureStorage();
  
  // Obtener token de autenticación
  Future<String?> _getAuthToken() async {
    return await _secureStorage.getToken();
  }
  
  // Preparar headers con token de autenticación
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Manejo de errores HTTP
  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T? Function(dynamic)? fromJson,
  ) async {
    try {
      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.fromJson(responseData, fromJson);
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Error en la solicitud',
          errors: responseData['errors'],
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al procesar la respuesta: $e',
      );
    }
  }
  
  // GET request
  Future<ApiResponse<T>> get<T>(
  String url, {
  Map<String, String>? queryParams,
  bool requireAuth = true,
  T? Function(dynamic)? fromJson,
}) async {
  try {
    final headers = await _getHeaders(includeAuth: requireAuth);
    print('Headers enviados: $headers'); // Depura los headers

    Uri uri = Uri.parse(url);
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    print('URL solicitada: $uri'); // Depura la URL

    final response = await _httpClient.get(uri, headers: headers);
    print('Respuesta del servidor: ${response.statusCode} - ${response.body}'); // Depura la respuesta cruda

    return await _handleResponse<T>(response, fromJson);
  } catch (e) {
    return ApiResponse(
      success: false,
      message: 'Error de conexión: $e',
    );
  }
}
  
  // POST request
  Future<ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    T? Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requireAuth);
      
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return await _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
  
  // PUT request
  Future<ApiResponse<T>> put<T>(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    T? Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requireAuth);
      
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return await _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
  
  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String url, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    T? Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requireAuth);
      
      final response = await _httpClient.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return await _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
  
  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String url, {
    bool requireAuth = true,
    T? Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requireAuth);
      
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: headers,
      );
      
      return await _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
  
  // Subir archivo con datos adicionales
  Future<ApiResponse<T>> uploadFile<T>(
    String url,
    File file,
    String fileField, {
    Map<String, String>? fields,
    bool requireAuth = true,
    T? Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: requireAuth);
      // Eliminar Content-Type para que lo establezca http.MultipartRequest
      headers.remove('Content-Type');
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);
      
      // Agregar archivo
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        file.path,
      ));
      
      // Agregar campos adicionales
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return await _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error al subir archivo: $e',
      );
    }
  }
}