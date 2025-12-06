import 'package:repair_service_app/config/app_config.dart';

class ApiEndpoints {
  static final String baseUrl = AppConfig.apiBaseUrl;
  
  // Authentication endpoints
  static final String login = '$baseUrl/auth/login';
  static final String register = '$baseUrl/auth/register';
  static final String verifyToken = '$baseUrl/auth/verify';
  
  // User endpoints
  static final String users = '$baseUrl/users';
  static final String userById = '$baseUrl/users/'; // Append ID
  static final String usersByRole = '$baseUrl/users/role/'; // Append role
  static final String userPassword = '$baseUrl/users/'; // Append ID + '/password'
  static final String userStatus = '$baseUrl/users/'; // Append ID + '/status'
  
  // Location endpoints
  static final String locations = '$baseUrl/locations';
  static final String locationById = '$baseUrl/locations/'; // Append ID
  static final String locationStatistics = '$baseUrl/locations/statistics/all';
  static final String locationTechnicians = '$baseUrl/locations/statistics/technicians';
  static final String locationServices = '$baseUrl/locations/statistics/services';
  
  // Client endpoints
  static final String clients = '$baseUrl/clients';
  static final String clientById = '$baseUrl/clients/'; // Append ID
  static final String clientsByLocation = '$baseUrl/clients/location/'; // Append location ID
  static final String clientServiceHistory = '$baseUrl/clients/'; // Append ID + '/services'
  static final String searchClients = '$baseUrl/clients/search';
  
  // Service endpoints
  static final String services = '$baseUrl/services';
  static final String serviceById = '$baseUrl/services/'; // Append ID
  static final String servicesByStatus = '$baseUrl/services/status/'; // Append status
  static final String servicesByTechnician = '$baseUrl/services/technician/'; // Append technician ID
  static final String servicesByLocation = '$baseUrl/services/location/'; // Append location ID
  static final String warrantyServices = '$baseUrl/services/warranty/all';
  static final String createWarranty = '$baseUrl/services/warranty';
  static final String serviceStatus = '$baseUrl/services/'; // Append ID + '/status'
  static final String assignTechnician = '$baseUrl/services/'; // Append ID + '/assign'
  static final String estimatedPrice = '$baseUrl/services/'; // Append ID + '/estimated-price'
  static final String finalPrice = '$baseUrl/services/'; // Append ID + '/final-price'
  static final String availableTechnicians = '$baseUrl/services/technicians/available';
  static final String uploadPhoto = '$baseUrl/services/'; // Append ID + '/photos'
  static final String removePhoto = '$baseUrl/services/photos/'; // Append photo ID
  static final String servicePayment = '$baseUrl/services/'; // Append ID + '/payment'
  static const String serviceStatistics = '/services/statistics/all';

  
  // Technician endpoints
  static final String technicians = '$baseUrl/technicians';
  static final String technicianById = '$baseUrl/technicians/'; // Append ID
  static final String techniciansByLocation = '$baseUrl/technicians/location/'; // Append location ID
  static final String availableTechniciansByLocation = '$baseUrl/technicians/available';
  static final String technicianServices = '$baseUrl/technicians/'; // Append ID + '/services'
  static final String technicianCompletedServices = '$baseUrl/technicians/'; // Append ID + '/completed-services'
  static final String technicianPerformance = '$baseUrl/technicians/'; // Append ID + '/performance'
  static final String technicianCompletionRate = '$baseUrl/technicians/'; // Append ID + '/completion-rate'
  static final String technicianWarrantyStatus = '$baseUrl/technicians/'; // Append ID + '/warranty-status'
  static final String technicianDashboard = '$baseUrl/technicians/'; // Append ID + '/dashboard'
  static final String technicianMyDashboard = '$baseUrl/technicians/dashboard/my';
  
  // Payment endpoints
  static final String payments = '$baseUrl/payments';
  static final String paymentById = '$baseUrl/payments/'; // Append ID
  static final String paymentsByTechnician = '$baseUrl/payments/technician/'; // Append technician ID
  static final String paymentsByDateRange = '$baseUrl/payments/date-range';
  static final String paymentStatistics = '$baseUrl/payments/statistics';
  static final String technicianPaymentSummary = '$baseUrl/payments/technician/'; // Append technician ID + '/summary'
  static final String recalculateAllPayments = '$baseUrl/payments/recalculate-all';
  static final String myPayments = '$baseUrl/payments/my/payments';
  static final String myPaymentSummary = '$baseUrl/payments/my/summary';
  
  // Twilio endpoints
  static final String twilioMessages = '$baseUrl/twilio';
  static final String twilioMessageById = '$baseUrl/twilio/'; // Append ID
  static final String twilioMessagesByService = '$baseUrl/twilio/service/'; // Append service ID
  static final String twilioMessageStatus = '$baseUrl/twilio/'; // Append ID + '/status'
  static final String twilioSendWelcome = '$baseUrl/twilio/welcome';
  static final String twilioSendQuote = '$baseUrl/twilio/quote';
  static final String twilioSendCompletion = '$baseUrl/twilio/completion';
  static final String twilioSendPaymentReminder = '$baseUrl/twilio/payment-reminder';
  static final String twilioSendWarrantyNotification = '$baseUrl/twilio/warranty-notification';
  static final String twilioSendAnonymousMessage = '$baseUrl/twilio/anonymous-message';
}