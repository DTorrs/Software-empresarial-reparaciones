import 'package:repair_service_app/config/api_endpoints.dart';
import 'package:repair_service_app/models/payment.dart';
import 'package:repair_service_app/services/api_service.dart';

class PaymentService {
  final ApiService _apiService;
  
  PaymentService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Obtener todos los cálculos de pago
  Future<ApiResponse<List<Payment>>> getAllPaymentCalculations() async {
    final response = await _apiService.get<List<Payment>>(
      ApiEndpoints.payments,
      fromJson: (json) => (json as List)
          .map((item) => Payment.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener cálculo de pago por ID
  Future<ApiResponse<Payment>> getPaymentCalculationById(int paymentId) async {
    final response = await _apiService.get<Payment>(
      '${ApiEndpoints.paymentById}$paymentId',
      fromJson: (json) => Payment.fromJson(json),
    );
    return response;
  }
  
  // Obtener pagos por técnico
  Future<ApiResponse<List<Payment>>> getPaymentsByTechnician(int technicianId) async {
    final response = await _apiService.get<List<Payment>>(
      '${ApiEndpoints.paymentsByTechnician}$technicianId',
      fromJson: (json) => (json as List)
          .map((item) => Payment.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener pagos por rango de fechas
  Future<ApiResponse<List<Payment>>> getPaymentsByDateRange(String startDate, String endDate) async {
    final response = await _apiService.get<List<Payment>>(
      ApiEndpoints.paymentsByDateRange,
      queryParams: {
        'startDate': startDate,
        'endDate': endDate,
      },
      fromJson: (json) => (json as List)
          .map((item) => Payment.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Calcular pago para servicio
  Future<ApiResponse<Payment>> calculatePaymentForService(int serviceId) async {
    final response = await _apiService.post<Payment>(
      '${ApiEndpoints.servicePayment}',
      body: {
        'serviceId': serviceId,
      },
      fromJson: (json) => Payment.fromJson(json),
    );
    return response;
  }
  
  // Recalcular todos los pagos (solo admin)
  Future<ApiResponse<List<Payment>>> recalculateAllPayments() async {
    final response = await _apiService.post<List<Payment>>(
      ApiEndpoints.recalculateAllPayments,
      fromJson: (json) => (json as List)
          .map((item) => Payment.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener resumen de pagos del técnico
  Future<ApiResponse<PaymentSummary>> getTechnicianPaymentSummary(int technicianId) async {
    final response = await _apiService.get<PaymentSummary>(
      '${ApiEndpoints.technicianPaymentSummary}$technicianId/summary',
      fromJson: (json) => PaymentSummary.fromJson(json),
    );
    return response;
  }
  
  // Obtener estadísticas de pagos
  Future<ApiResponse<Map<String, dynamic>>> getPaymentStatistics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.paymentStatistics,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return response;
  }
  
  // Obtener mis pagos (para técnicos)
  Future<ApiResponse<List<Payment>>> getMyPayments() async {
    final response = await _apiService.get<List<Payment>>(
      ApiEndpoints.myPayments,
      fromJson: (json) => (json as List)
          .map((item) => Payment.fromJson(item))
          .toList(),
    );
    return response;
  }
  
  // Obtener mi resumen de pagos (para técnicos)
  Future<ApiResponse<PaymentSummary>> getMyPaymentSummary() async {
    final response = await _apiService.get<PaymentSummary>(
      ApiEndpoints.myPaymentSummary,
      fromJson: (json) => PaymentSummary.fromJson(json),
    );
    return response;
  }
}