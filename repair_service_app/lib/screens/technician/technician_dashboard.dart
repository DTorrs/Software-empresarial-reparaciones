import 'package:flutter/material.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/widgets/common/app_drawer.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/utils/formatters.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({Key? key}) : super(key: key);

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final AuthService _authService = AuthService();
  final TechnicianService _technicianService = TechnicianService();
  
  User? _currentUser;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
    _hasError = false;
  });

  try {
    final userResponse = await _authService.verifyToken();
    
    if (!userResponse.success) {
      throw Exception(userResponse.message);
    }
    
    if (userResponse.data == null) {
      throw Exception('No se pudo obtener información del usuario');
    }
    
    _currentUser = userResponse.data;
    print('Usuario actual: ${_currentUser!.toJson()}'); // Esto asume que User tiene toJson()

    if (_currentUser!.role == 'technician') {
      final dashboardResponse = await _technicianService.getMyDashboard();
      
      // Cambia esta línea para imprimir propiedades específicas
      print('Respuesta del dashboard: success=${dashboardResponse.success}, message=${dashboardResponse.message}, data=${dashboardResponse.data}');
      
      if (!dashboardResponse.success) {
        throw Exception(dashboardResponse.message);
      }
      
      if (dashboardResponse.data == null) {
        throw Exception('No se pudieron cargar los datos del dashboard');
      }
      
      _dashboardData = dashboardResponse.data!;
    } else {
      throw Exception('El usuario no tiene rol de técnico');
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando dashboard...'),
      );
    }
    
    if (_hasError || _currentUser == null || _dashboardData == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Error',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _hasError ? _errorMessage : 'No se pudieron cargar los datos',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mi Dashboard',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: null,
          ),
        ],
      ),
      drawer: AppDrawer(
        user: _currentUser!,
        currentRoute: '/technician/dashboard',
         authService: _authService, 
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTechnicianInfoCard(),
              const SizedBox(height: 16),
              _buildPerformanceCard(),
              const SizedBox(height: 16),
              if (_hasPendingWarranty())
                _buildWarrantyAlertCard(),
              const SizedBox(height: 16),
              _buildSectionTitle('Mis Servicios Pendientes'),
              const SizedBox(height: 8),
              _buildPendingServicesList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Servicios Recientes'),
              const SizedBox(height: 8),
              _buildRecentCompletionsList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Resumen de Pagos'),
              const SizedBox(height: 8),
              _buildPaymentSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTechnicianInfoCard() {
    final DateTime now = DateTime.now();
    final String period = now.hour < 12 
        ? 'Buenos días'
        : now.hour < 18 
            ? 'Buenas tardes'
            : 'Buenas noches';
    
    final performance = _dashboardData!['performance'];
    final pendingServices = _getPendingServices();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 24,
                  child: Text(
                    _currentUser!.name.isNotEmpty 
                        ? _currentUser!.name[0].toUpperCase() 
                        : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$period, ${_currentUser!.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getTechnicianLocation(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBadge(
                    'Servicios Pendientes', 
                    '${pendingServices.length}', 
                    pendingServices.isEmpty ? AppTheme.successColor : AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoBadge(
                    'Tasa de Éxito', 
                    '${performance['general']['completed_services']}/${performance['general']['total_services']}', 
                    _getCompletionRateColor(performance['general']['completed_services'] / performance['general']['total_services'] * 100),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoBadge(
                    _hasPendingWarranty() ? 'Garantía Pendiente' : 'Garantías',
                    '${performance['general']['warranty_services']}',
                    _hasPendingWarranty() ? AppTheme.warrantyServiceColor : AppTheme.infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceCard() {
    final performance = _dashboardData!['performance'];
    final general = performance['general'];
    final financial = performance['financial'];
    
    // Calcular tasa de finalización
    final completionRate = general['total_services'] > 0
        ? (general['completed_services'] / general['total_services'] * 100)
        : 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mi Desempeño',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCompletionRateColor(completionRate),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${completionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getCompletionRateColor(completionRate)),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPerformanceMetric(
                  'Servicios Totales',
                  '${general['total_services']}',
                  Icons.home_repair_service,
                ),
                _buildPerformanceMetric(
                  'Completados',
                  '${general['completed_services']}',
                  Icons.check_circle,
                ),
                _buildPerformanceMetric(
                  'Tiempo Promedio',
                  _formatCompletionTime(general['avg_completion_time']),
                  Icons.timer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Resumen de Pagos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFinancialMetric(
                  'Valor Servicios',
                  Formatters.formatCurrency(financial['total_revenue'] ?? 0.0),
                  AppTheme.infoColor,
                ),
                _buildFinancialMetric(
                  'Pago Total',
                  Formatters.formatCurrency(financial['total_payment'] ?? 0.0),
                  AppTheme.primaryColor,
                ),
                _buildFinancialMetric(
                  'Porcentaje',
                  '${(financial['avg_payment_percentage'] ?? 0.0).toStringAsFixed(1)}%',
                  _getPaymentPercentageColor(financial['avg_payment_percentage'] ?? 0.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildFinancialMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWarrantyAlertCard() {
    final List<dynamic> pendingServices = _getPendingServices();
    final List<dynamic> warrantyServices = pendingServices
        .where((service) => service['is_warranty'] == true)
        .toList();
    
    if (warrantyServices.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final warrantyService = warrantyServices.first;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.warrantyServiceColor,
          width: 2,
        ),
      ),
      color: AppTheme.warrantyServiceColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warrantyServiceColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    color: AppTheme.warrantyServiceColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Garantía Pendiente - Alta Prioridad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warrantyServiceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tienes una solicitud de garantía que requiere atención prioritaria. No recibirás nuevos servicios hasta que completes esta garantía.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Garantía #${warrantyService['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Original #${warrantyService['original_service_id']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${warrantyService['client_name']} - ${warrantyService['device_type']} ${warrantyService['device_brand']}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warrantyService['issue_description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context, 
                    AppRoutes.technicianServiceDetails,
                    arguments: {
                      'serviceId': warrantyService['id'],
                    },
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warrantyServiceColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPendingServicesList() {
    final List<dynamic> pendingServices = _getPendingServices();
    
    if (pendingServices.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              Text(
                '¡No tienes servicios pendientes!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todos tus servicios asignados han sido completados.',
                style: TextStyle(
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${pendingServices.length} servicios pendientes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.technicianServiceDetails);
                  },
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('Ver Todos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingServices.length > 3 ? 3 : pendingServices.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final service = pendingServices[index];
              return ListTile(
                title: Row(
                  children: [
                    Text(
                      '#${service['id']} - ${service['device_type']} ${service['device_brand']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: service['is_warranty'] == true
                            ? AppTheme.warrantyServiceColor
                            : Colors.black87,
                      ),
                    ),
                    if (service['is_warranty'] == true) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.warrantyServiceColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      service['client_name'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      service['issue_description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(service['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(service['status']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(service['status']),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(service['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    AppRoutes.technicianServiceDetails,
                    arguments: {
                      'serviceId': service['id'],
                    },
                  );
                },
              );
            },
          ),
          if (pendingServices.length > 3) ...[
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.technicianServiceDetails);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Ver ${pendingServices.length - 3} servicios más...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRecentCompletionsList() {
    final List<dynamic> recentCompletions = _dashboardData!['recentCompletions'] ?? [];
    
    if (recentCompletions.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No hay servicios completados recientemente',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentCompletions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final service = recentCompletions[index];
          return ListTile(
            title: Text(
              '#${service['id']} - ${service['device_type']} ${service['device_brand']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  service['client_name'],
                  style: const TextStyle(fontSize: 12),
                ),
                if (service['completed_date'] != null)
                  Text(
                    'Completado: ${Formatters.formatShortDate(service['completed_date'])}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(service['final_price'] ?? 0.0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '${(service['payment_percentage'] ?? 0).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPaymentPercentageColor(service['payment_percentage'] ?? 0),
                  ),
                ),
              ],
            ),
            onTap: () {
              // Ver detalles del servicio completado
            },
          );
        },
      ),
    );
  }
  
  Widget _buildPaymentSummaryCard() {
    final performance = _dashboardData!['performance'];
    final financial = performance['financial'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumen de mis pagos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        performance['general']['completed_services'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentInfoCard(
                    'Valor Total',
                    Formatters.formatCurrency(financial['total_revenue'] ?? 0.0),
                    'Ingresos por servicios',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPaymentInfoCard(
                    'Mi Pago',
                    Formatters.formatCurrency(financial['total_payment'] ?? 0.0),
                    'Tus ingresos',
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Porcentaje de pago promedio',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Basado en tu tasa de finalización',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getPaymentPercentageColor(financial['avg_payment_percentage'] ?? 0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(financial['avg_payment_percentage'] ?? 0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getPaymentPercentageColor(financial['avg_payment_percentage'] ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.technicianPayments);
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver Detalles de Pagos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentInfoCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  
  String _getTechnicianLocation() {
    final pendingServices = _dashboardData!['pendingServices'] ?? [];
    if (pendingServices.isNotEmpty) {
      return pendingServices[0]['technician_location'] ?? 'Ubicación no disponible';
    }
    return 'Ubicación no disponible';
  }
  
  List<dynamic> _getPendingServices() {
    return _dashboardData!['pendingServices'] ?? [];
  }
  
  bool _hasPendingWarranty() {
    final pendingServices = _getPendingServices();
    return pendingServices.any((service) => service['is_warranty'] == true);
  }
  
  String _formatCompletionTime(dynamic hours) {
    if (hours == null) return 'N/A';
    
    try {
      final double hoursValue = hours.toDouble();
      if (hoursValue < 1) {
        return '${(hoursValue * 60).round()} min';
      } else if (hoursValue < 24) {
        return '${hoursValue.toStringAsFixed(1)} hrs';
      } else {
        return '${(hoursValue / 24).toStringAsFixed(1)} días';
      }
    } catch (e) {
      return 'N/A';
    }
  }
  
  Color _getCompletionRateColor(double rate) {
    if (rate >= 90) {
      return AppTheme.successColor;
    } else if (rate >= 80) {
      return Colors.blue;
    } else if (rate >= 70) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
  
  Color _getPaymentPercentageColor(double percentage) {
    if (percentage >= 80) {
      return AppTheme.successColor;
    } else if (percentage >= 70) {
      return AppTheme.primaryColor;
    } else {
      return AppTheme.warningColor;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return AppTheme.newServiceColor;
      case 'assigned':
        return AppTheme.assignedServiceColor;
      case 'in_progress':
        return AppTheme.inProgressServiceColor;
      case 'completed':
        return AppTheme.completedServiceColor;
      case 'cancelled':
        return AppTheme.cancelledServiceColor;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'Nuevo';
      case 'assigned':
        return 'Asignado';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }
}