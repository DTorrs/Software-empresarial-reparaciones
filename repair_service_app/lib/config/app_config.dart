class AppConfig {
  // API Base URL
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Para emulador Android
  // static const String apiBaseUrl = 'http://localhost:3000/api'; // Para iOS o pruebas locales

  // Configuración de Twilio - a modo de referencia, estos valores se manejan en el backend
  static const String twilioAccountSid = 'AC6ec30af83e524438624517dd361ed10a';
  static const String twilioAuthToken = '4e49118a6d093bb5ef78f560a1b30c38';
  static const String twilioWhatsAppNumber = '+14155238886';

  // Timeouts
  static const int connectionTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms

  // Cache
  static const int cacheMaxAge = 3600; // segundos (1 hora)
  
  // Datos de la empresa
  static const String appName = 'Gestión de Servicios';
  static const String companyName = 'Reparaciones Express';
  
  // Configuración de imágenes
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB en bytes
  static const double imageQuality = 85; // Calidad de compresión (0-100)
  static const int maxImageWidth = 1080; // Ancho máximo en píxeles
  static const int maxImageHeight = 1920; // Alto máximo en píxeles
}