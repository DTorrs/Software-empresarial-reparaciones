import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/payment.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/services/payment_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/widgets/cards/payment_card.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';

class TechnicianPaymentsScreen extends StatefulWidget {
  const TechnicianPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianPaymentsScreen> createState() => _TechnicianPaymentsScreenState();
}

class _TechnicianPaymentsScreenState extends State<TechnicianPaymentsScreen> with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final TechnicianService _technicianService = TechnicianService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  User? _currentUser;
  bool _isLoading = true;
  
  // Datos del técnico
  Map<String, dynamic>? _performanceData;
  PaymentSummary? _paymentSummary;
  List<Payment> _payments = [];
  List<Service> _completedServices = [];
  
  // Filtros
  String _timeFilter = 'all'; // 'all', 'month', 'week'
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _authService.verifyToken();
      
      if (mounted) {
        if (response.success && response.data != null) {
          _currentUser = response.data;
          
          // Cargar datos de pagos
          await _loadTechnicianData();
        } else {
          setState(() {
            _isLoading = false;
          });
          
          showErrorDialog(
            context: context,
            title: 'Error de autenticación',
            message: 'No se pudo verificar tu sesión. Por favor, inicia sesión nuevamente.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al cargar los datos: $e',
        );
      }
    }
  }
  
  Future<void> _loadTechnicianData() async {
    if (_currentUser == null || !_currentUser!.isTechnician) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      // Cargar varios datos en paralelo
      final futures = await Future.wait([
        _paymentService.getMyPaymentSummary(),
        _paymentService.getMyPayments(),
        _technicianService.getMyDashboard(),
        _technicianService.getTechnicianCompletedServices(_currentUser!.id),
      ]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          // Procesar resultados en el orden de las solicitudes
          if (futures[0].success && futures[0].data != null) {
            _paymentSummary = futures[0].data as PaymentSummary;
          }
          
          if (futures[1].success && futures[1].data != null) {
  _payments = futures[1].data as List<Payment>;
  _filterPayments();
}

if (futures[2].success && futures[2].data != null) {
  _performanceData = futures[2].data as Map<String, dynamic>;
}

if (futures[3].success && futures[3].data != null) {
  _completedServices = futures[3].data as List<Service>;
}
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al cargar los datos: $e',
        );
      }
    }
  }
  
  void _filterPayments() {
    if (_payments.isEmpty) return;
    
    // Ordenar por fecha más reciente primero
    _payments.sort((a, b) => 
      DateTime.parse(b.calculationDate).compareTo(DateTime.parse(a.calculationDate))
    );
    
    if (_timeFilter == 'all') {
      // No filtrar, mostrar todos
      return;
    }
    
    final DateTime now = DateTime.now();
    DateTime cutoffDate;
    
    if (_timeFilter == 'month') {
      cutoffDate = DateTime(now.year, now.month - 1, now.day);
    } else if (_timeFilter == 'week') {
      cutoffDate = now.subtract(const Duration(days: 7));
    } else {
      return; // No debería llegar aquí
    }
    
    setState(() {
      _payments = _payments.where((payment) {
        final paymentDate = DateTime.parse(payment.calculationDate);
        return paymentDate.isAfter(cutoffDate);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando datos de pagos...'),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mis Pagos',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTechnicianData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.primaryColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(
            text: 'Resumen',
            icon: Icon(Icons.assessment),
          ),
          Tab(
            text: 'Historial',
            icon: Icon(Icons.history),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    if (_paymentSummary == null) {
      return const Center(
        child: Text('No hay datos de resumen disponibles'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadTechnicianData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentSummaryCard(
              summary: _paymentSummary!,
              title: 'Mi Resumen de Pagos',
              color: AppTheme.primaryColor,
              onTap: () {
                // Podría abrir una vista detallada
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Rendimiento y Pagos'),
            const SizedBox(height: 16),
            _buildPerformanceInfoCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Pagos Recientes'),
            const SizedBox(height: 8),
            _buildRecentPaymentsList(),
            const SizedBox(height: 24),
            _buildSectionTitle('Política de Pagos'),
            const SizedBox(height: 8),
            _buildPaymentPolicyCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: _payments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTechnicianData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      return PaymentCard(
                        payment: _payments[index],
                        showTechnician: false,
                        onTap: () {
                          // Podría abrir detalles del pago
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar pagos:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip('Todos', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Último mes', 'month'),
              const SizedBox(width: 8),
              _buildFilterChip('Última semana', 'week'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _timeFilter == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _timeFilter = value;
          });
          _loadTechnicianData(); // Recargar con el nuevo filtro
        }
      },
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay pagos disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los pagos aparecerán aquí una vez que completés servicios',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
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
  
  Widget _buildPerformanceInfoCard() {
    final performance = _performanceData != null && _performanceData!['performance'] != null
        ? _performanceData!['performance']
        : null;
    
    if (performance == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos de rendimiento disponibles'),
        ),
      );
    }
    
    final general = performance['general'];
    
    final double completionRate = general['completed_services'] > 0 && general['total_services'] > 0
        ? (general['completed_services'] / general['total_services']) * 100
        : 0.0;
    
    final String paymentPercentage = _getPaymentPercentageText(completionRate);
    
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
                const Icon(
                  Icons.star_rate,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tu Rendimiento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Servicios Totales',
                  '${general['total_services'] ?? 0}',
                ),
                _buildStatColumn(
                  'Completados',
                  '${general['completed_services'] ?? 0}',
                ),
                _buildStatColumn(
                  'Garantías',
                  '${general['warranty_services'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tu porcentaje de pago actual:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    paymentPercentage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getCompletionRateColor(completionRate)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              _getCompletionRateDescription(completionRate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildRecentPaymentsList() {
    if (_payments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay pagos recientes'),
          ),
        ),
      );
    }
    
    // Mostrar solo los 5 más recientes
    final recentPayments = _payments.take(5).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentPayments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = recentPayments[index];
              return ListTile(
                title: Text(
                  'Servicio #${payment.serviceId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${payment.deviceType ?? 'Dispositivo'} - ${payment.clientName ?? 'Cliente'}',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(payment.paymentAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '${payment.appliedPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Podría mostrar detalles del pago
                },
              );
            },
          ),
          InkWell(
            onTap: () {
              _tabController.animateTo(1); // Cambiar a la pestaña de historial
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver todos los pagos',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentPolicyCard() {
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
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cómo se calculan tus pagos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'El porcentaje de pago se calcula según tu tasa de finalización de servicios:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildPolicyItem(
              '80% del valor del servicio',
              'Para una tasa de finalización ≥ 80%',
              AppTheme.successColor,
            ),
            const SizedBox(height: 4),
            _buildPolicyItem(
              '70% del valor del servicio',
              'Para una tasa de finalización entre 70% y 79%',
              AppTheme.warningColor,
            ),
            const SizedBox(height: 4),
            _buildPolicyItem(
              '60% del valor del servicio',
              'Para una tasa de finalización < 70%',
              AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.infoColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: AppTheme.infoColor,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Consejos para maximizar tus ganancias:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem('Completa todos los servicios asignados a tiempo'),
                  _buildTipItem('Atiende las garantías pendientes lo antes posible'),
                  _buildTipItem('Mantén actualizado el estado de los servicios'),
                  _buildTipItem('Sube fotos claras del antes y después de cada reparación'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPolicyItem(String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods para determinar colores y textos
  
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
  
  String _getPaymentPercentageText(double completionRate) {
    if (completionRate >= 80) {
      return '80%';
    } else if (completionRate >= 70) {
      return '70%';
    } else {
      return '60%';
    }
  }
  
  String _getCompletionRateDescription(double completionRate) {
    if (completionRate >= 90) {
      return '¡Excelente rendimiento! Estás completando la mayoría de tus servicios asignados.';
    } else if (completionRate >= 80) {
      return 'Buen rendimiento. Mantienes un alto porcentaje de servicios completados.';
    } else if (completionRate >= 70) {
      return 'Rendimiento aceptable. Intenta completar más servicios para aumentar tu porcentaje de pago.';
    } else {
      return 'Rendimiento por mejorar. Completa más servicios asignados para incrementar tu porcentaje de pago.';
    }
  }
}