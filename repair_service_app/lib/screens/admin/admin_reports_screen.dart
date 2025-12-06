import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/location.dart';
import 'package:repair_service_app/services/location_service.dart';
import 'package:repair_service_app/services/payment_service.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_dropdown.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final ServiceService _serviceService = ServiceService();
  final TechnicianService _technicianService = TechnicianService();
  final PaymentService _paymentService = PaymentService();
  
  late TabController _tabController;
  late DateTime _startDate;
  late DateTime _endDate;
  int? _selectedLocationId;
  
  bool _isLoading = true;
  Map<String, dynamic> _serviceStats = {};
  Map<String, dynamic> _technicianStats = {};
  Map<String, dynamic> _paymentStats = {};
  List<Location> _locations = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Por defecto, establecer fechas para el último mes
    _endDate = DateTime.now();
    _startDate = DateTime(_endDate.year, _endDate.month - 1, _endDate.day);
    
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar ubicaciones
      final locationsResponse = await _locationService.getAllLocations();
      
      if (locationsResponse.success && locationsResponse.data != null) {
  setState(() {
    _locations = locationsResponse.data ?? [];
  });
}
      
      // Cargar estadísticas iniciales
      await _loadReportData();
      
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar los datos iniciales: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar estadísticas de servicios
      await _loadServiceStatistics();
      
      // Cargar estadísticas de técnicos
      await _loadTechnicianStatistics();
      
      // Cargar estadísticas de pagos
      await _loadPaymentStatistics();
      
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar los datos del reporte: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadServiceStatistics() async {
    try {
      final response = await _serviceService.getServiceStatistics();
      
      if (response.success && response.data != null) {
  setState(() {
    _serviceStats = response.data ?? {};
  });
}
    } catch (e) {
      print('Error cargando estadísticas de servicios: $e');
      // No interrumpir la carga completa por un error en una sección
    }
  }
  
  Future<void> _loadTechnicianStatistics() async {
    try {
      // Aquí se cargarían estadísticas de técnicos
      // En un caso real, habría un endpoint específico para esto
      setState(() {
        _technicianStats = {
          'total_technicians': 12,
          'active_technicians': 10,
          'average_completion_rate': 85.5,
          'technicians_with_warranty': 3,
        };
      });
    } catch (e) {
      print('Error cargando estadísticas de técnicos: $e');
    }
  }
  
  Future<void> _loadPaymentStatistics() async {
    try {
      final response = await _paymentService.getPaymentStatistics();
      
      if (response.success && response.data != null) {
  setState(() {
    _paymentStats = response.data ?? {};
  });
}
    } catch (e) {
      print('Error cargando estadísticas de pagos: $e');
    }
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked.start != _startDate && picked.end != _endDate) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      
      // Recargar datos con el nuevo rango de fechas
      await _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reportes y Estadísticas',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Cargando datos de reportes...')
          : Column(
              children: [
                _buildFiltersBar(),
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: const [
                    Tab(text: 'Servicios'),
                    Tab(text: 'Técnicos'),
                    Tab(text: 'Finanzas'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildServicesReportTab(),
                      _buildTechniciansReportTab(),
                      _buildFinancialReportTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _selectedLocationId,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas las ubicaciones'),
                ),
                ..._locations.map((location) {
                  return DropdownMenuItem<int?>(
                    value: location.id,
                    child: Text(location.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
                _loadReportData();
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServicesReportTab() {
    if (_serviceStats.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles para servicios.'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Resumen de Servicios'),
          const SizedBox(height: 16),
          _buildServicesSummaryCards(),
          const SizedBox(height: 24),
          _buildSectionTitle('Distribución por Estado'),
          const SizedBox(height: 16),
          _buildServicesStatusChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Distribución por Tipo'),
          const SizedBox(height: 16),
          _buildServicesTypeChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Servicios por Mes'),
          const SizedBox(height: 16),
          _buildServicesTimeChart(),
        ],
      ),
    );
  }
  
  Widget _buildTechniciansReportTab() {
    if (_technicianStats.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles para técnicos.'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Resumen de Técnicos'),
          const SizedBox(height: 16),
          _buildTechniciansSummaryCards(),
          const SizedBox(height: 24),
          _buildSectionTitle('Desempeño de Técnicos'),
          const SizedBox(height: 16),
          _buildTechniciansPerformanceChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Técnicos con Mejor Desempeño'),
          const SizedBox(height: 16),
          _buildTopTechniciansTable(),
        ],
      ),
    );
  }
  
  Widget _buildFinancialReportTab() {
    if (_paymentStats.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles para finanzas.'),
      );
    }
    
    // Obtener datos de general si existen
    final generalStats = _paymentStats['general'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Resumen Financiero'),
          const SizedBox(height: 16),
          _buildFinancialSummaryCards(generalStats),
          const SizedBox(height: 24),
          _buildSectionTitle('Ingresos por Mes'),
          const SizedBox(height: 16),
          _buildFinancialTimeChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Pagos a Técnicos'),
          const SizedBox(height: 16),
          _buildTechnicianPaymentsTable(),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 4,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildServicesSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total de Servicios',
          _serviceStats['total_services']?.toString() ?? '0',
          Icons.home_repair_service,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Servicios Completados',
          _serviceStats['completed_services']?.toString() ?? '0',
          Icons.check_circle,
          AppTheme.completedServiceColor,
        ),
        _buildStatCard(
          'Servicios en Garantía',
          _serviceStats['warranty_services']?.toString() ?? '0',
          Icons.verified,
          AppTheme.warrantyServiceColor,
        ),
        _buildStatCard(
          'Precio Promedio',
          Formatters.formatCurrency(_serviceStats['average_price']?.toDouble() ?? 0.0),
          Icons.attach_money,
          Colors.green[700]!,
        ),
      ],
    );
  }
  
  Widget _buildServicesStatusChart() {
    // En un caso real, esto sería un gráfico circular
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gráfico de distribución por estado',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildChartLegendItem(
                  'Nuevos',
                  '${_serviceStats['new_services'] ?? 0}',
                  AppTheme.newServiceColor,
                ),
                _buildChartLegendItem(
                  'Asignados',
                  '${_serviceStats['assigned_services'] ?? 0}',
                  AppTheme.assignedServiceColor,
                ),
                _buildChartLegendItem(
                  'En Progreso',
                  '${_serviceStats['in_progress_services'] ?? 0}',
                  AppTheme.inProgressServiceColor,
                ),
                _buildChartLegendItem(
                  'Completados',
                  '${_serviceStats['completed_services'] ?? 0}',
                  AppTheme.completedServiceColor,
                ),
                _buildChartLegendItem(
                  'Cancelados',
                  '${_serviceStats['cancelled_services'] ?? 0}',
                  AppTheme.cancelledServiceColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServicesTypeChart() {
    // En un caso real, esto sería un gráfico de barras
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gráfico de distribución por tipo',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegendItem(
                  'Reparaciones',
                  '${_serviceStats['repair_services'] ?? 0}',
                  Colors.blue,
                ),
                const SizedBox(width: 32),
                _buildChartLegendItem(
                  'Mantenimientos',
                  '${_serviceStats['maintenance_services'] ?? 0}',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServicesTimeChart() {
    // En un caso real, esto sería un gráfico de líneas o barras por tiempo
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Gráfico de servicios por mes',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTechniciansSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total de Técnicos',
          _technicianStats['total_technicians']?.toString() ?? '0',
          Icons.engineering,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Técnicos Activos',
          _technicianStats['active_technicians']?.toString() ?? '0',
          Icons.check_circle,
          AppTheme.successColor,
        ),
        _buildStatCard(
          'Tasa de Finalización Promedio',
          '${_technicianStats['average_completion_rate']?.toString() ?? '0'}%',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildStatCard(
          'Con Garantías Pendientes',
          _technicianStats['technicians_with_warranty']?.toString() ?? '0',
          Icons.verified,
          AppTheme.warrantyServiceColor,
        ),
      ],
    );
  }
  
  Widget _buildTechniciansPerformanceChart() {
    // En un caso real, esto sería un gráfico de barras horizontales
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stacked_bar_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Gráfico de desempeño de técnicos',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopTechniciansTable() {
    // Aquí se mostraría una tabla de técnicos con mejor desempeño
    // En este caso usaremos datos de ejemplo
    final technicians = [
      {
        'name': 'Juan Pérez',
        'completion_rate': 95.2,
        'services_count': 48,
        'total_payment': 8450.0,
      },
      {
        'name': 'María López',
        'completion_rate': 93.8,
        'services_count': 42,
        'total_payment': 7680.0,
      },
      {
        'name': 'Carlos Gómez',
        'completion_rate': 90.5,
        'services_count': 38,
        'total_payment': 6950.0,
      },
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Técnico')),
            DataColumn(label: Text('Tasa Finalización')),
            DataColumn(label: Text('Servicios')),
            DataColumn(label: Text('Pagos Totales')),
          ],
          rows: technicians.map((technician) {
            return DataRow(
              cells: [
                DataCell(Text(technician['name'] as String)),
                DataCell(Text('${technician['completion_rate']}%')),
                DataCell(Text('${technician['services_count']}')),
                DataCell(Text(Formatters.formatCurrency(technician['total_payment'] as double))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildFinancialSummaryCards(Map<String, dynamic> generalStats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total de Ingresos',
          Formatters.formatCurrency(generalStats['total_service_value']?.toDouble() ?? 0.0),
          Icons.attach_money,
          Colors.green[700]!,
        ),
        _buildStatCard(
          'Total de Pagos a Técnicos',
          Formatters.formatCurrency(generalStats['total_payment_amount']?.toDouble() ?? 0.0),
          Icons.payments,
          Colors.orange[700]!,
        ),
        _buildStatCard(
          'Margen Promedio',
          '${(100 - (generalStats['average_percentage'] ?? 0)).toStringAsFixed(1)}%',
          Icons.trending_up,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Pagos Generados',
          generalStats['total_payments']?.toString() ?? '0',
          Icons.receipt_long,
          Colors.purple,
        ),
      ],
    );
  }
  
  Widget _buildFinancialTimeChart() {
    // En un caso real, esto sería un gráfico de líneas o barras por tiempo
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Gráfico de ingresos por mes',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTechnicianPaymentsTable() {
    // Utilizar datos de los técnicos con mejor desempeño de _paymentStats
    final topTechnicians = _paymentStats['topTechnicians'] ?? [];
    
    if (topTechnicians.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('No hay datos disponibles de pagos a técnicos.'),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Técnico')),
            DataColumn(label: Text('Servicios')),
            DataColumn(label: Text('Pagos Totales')),
            DataColumn(label: Text('% Promedio')),
          ],
          rows: topTechnicians.map<DataRow>((technician) {
            return DataRow(
              cells: [
                DataCell(Text(technician['technician_name'] ?? 'Desconocido')),
                DataCell(Text('${technician['service_count'] ?? 0}')),
                DataCell(Text(Formatters.formatCurrency(technician['total_payment']?.toDouble() ?? 0.0))),
                DataCell(Text('${technician['average_percentage']?.toStringAsFixed(1) ?? '0'}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}