import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/payment.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/services/payment_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/widgets/cards/payment_card.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final TechnicianService _technicianService = TechnicianService();
  
  bool _isLoading = true;
  bool _isRecalculating = false;
  
  List<Payment> _payments = [];
  List<Technician> _technicians = [];
  Map<String, dynamic>? _paymentStatistics;
  
  // Filtros
  int? _selectedTechnicianId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    // Cargar datos en paralelo
    final responses = await Future.wait([
      _paymentService.getAllPaymentCalculations(),
      _paymentService.getPaymentStatistics(),
      _technicianService.getAllTechnicians(),
    ]);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        
        // Procesar resultados si fueron exitosos
        final paymentsResponse = responses[0];
        if (paymentsResponse.success && paymentsResponse.data != null) {
          // Aquí se necesita un cast para resolver el problema
          _payments = paymentsResponse.data as List<Payment>;
        }
        
        final statsResponse = responses[1];
if (statsResponse.success && statsResponse.data != null) {
  _paymentStatistics = statsResponse.data as Map<String, dynamic>;
}
        
        final techniciansResponse = responses[2];
        if (techniciansResponse.success && techniciansResponse.data != null) {
          _technicians = techniciansResponse.data as List<Technician>;
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
  
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Si hay filtros aplicados, aplicarlos
      final response = await _fetchFilteredPayments();
      
      // Actualizar estadísticas
      final statsResponse = await _paymentService.getPaymentStatistics();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          if (response.success && response.data != null) {
            _payments = response.data!;
          }
          
          if (statsResponse.success && statsResponse.data != null) {
            _paymentStatistics = statsResponse.data!;
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
          message: 'Ocurrió un error al actualizar los datos: $e',
        );
      }
    }
  }
  
  Future<void> _recalculateAllPayments() async {
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: 'Recalcular Pagos',
      content: 'Esta acción recalculará todos los pagos para servicios completados. '
          'Esto puede tomar un tiempo y modificará los valores calculados previamente. '
          '¿Deseas continuar?',
      confirmText: 'Recalcular',
      cancelText: 'Cancelar',
      icon: Icons.refresh,
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isRecalculating = true;
    });
    
    try {
      final response = await _paymentService.recalculateAllPayments();
      
      if (mounted) {
        setState(() {
          _isRecalculating = false;
        });
        
        if (response.success) {
          showSuccessDialog(
            context: context,
            title: 'Recálculo Completado',
            message: 'Se han recalculado todos los pagos exitosamente. '
                'Se procesaron ${response.data?.length ?? 0} pagos.',
            onButtonPressed: () {
              Navigator.pop(context);
              _refreshData();
            },
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudieron recalcular los pagos: ${response.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecalculating = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al recalcular los pagos: $e',
        );
      }
    }
  }
  
  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _fetchFilteredPayments();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          if (response.success && response.data != null) {
            _payments = response.data!;
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
          message: 'Ocurrió un error al aplicar los filtros: $e',
        );
      }
    }
  }
  
  Future<void> _clearFilters() async {
    setState(() {
      _selectedTechnicianId = null;
      _startDate = null;
      _endDate = null;
    });
    
    await _refreshData();
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
      
      await _applyFilters();
    }
  }
  
  Future<dynamic> _fetchFilteredPayments() async {
    if (_selectedTechnicianId != null) {
      return _paymentService.getPaymentsByTechnician(_selectedTechnicianId!);
    } else if (_startDate != null && _endDate != null) {
      return _paymentService.getPaymentsByDateRange(
        DateFormat('yyyy-MM-dd').format(_startDate!),
        DateFormat('yyyy-MM-dd').format(_endDate!),
      );
    } else {
      return _paymentService.getAllPaymentCalculations();
    }
  }
  
  Future<void> _viewPaymentDetails(Payment payment) async {
    // Mostrar detalles de pago
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.drag_handle, color: Colors.grey),
                      Text(
                        'Detalles de Pago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PaymentCard(
                  payment: payment,
                  showTechnician: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Cerrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestión de Pagos',
      ),
      body: _isLoading 
          ? const LoadingIndicator(message: 'Cargando datos de pagos...')
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsCards(),
                    const SizedBox(height: 16),
                    _buildFiltersSection(),
                    const SizedBox(height: 16),
                    _buildPaymentsList(),
                    const SizedBox(height: 16),
                    _buildRecalculateButton(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh),
        tooltip: 'Actualizar',
      ),
    );
  }
  
  Widget _buildStatisticsCards() {
    if (_paymentStatistics == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No hay estadísticas disponibles',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }
    
    final generalStats = _paymentStatistics!['general'];
    final topTechnicians = _paymentStatistics!['topTechnicians'] as List? ?? [];
    final monthly = _paymentStatistics!['monthly'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen General',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      'Total Pagos',
                      Formatters.formatCurrency(generalStats['total_payment_amount'] ?? 0.0),
                      Icons.payments,
                      AppTheme.primaryColor,
                    ),
                    _buildStatCard(
                      'Valor Servicios',
                      Formatters.formatCurrency(generalStats['total_service_value'] ?? 0.0),
                      Icons.home_repair_service,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      '% Promedio',
                      '${(generalStats['average_percentage'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Mejores técnicos
        if (topTechnicians.isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mejores Técnicos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topTechnicians.length,
                      itemBuilder: (context, index) {
                        final technician = topTechnicians[index];
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                technician['technician_name'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pagos: ${Formatters.formatCurrency(technician['total_payment'] ?? 0.0)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Servicios: ${technician['service_count'] ?? 0}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '% Prom: ${(technician['average_percentage'] ?? 0.0).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFiltersSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTechnicianDropdown(),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range),
                  label: const Text('Fechas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mostrar filtros activos
            if (_selectedTechnicianId != null || _startDate != null || _endDate != null)
              Wrap(
                spacing: 8,
                children: [
                  if (_selectedTechnicianId != null)
                    _buildFilterChip(
                      'Técnico: ${_technicians.firstWhere((t) => t.id == _selectedTechnicianId).name}',
                      () {
                        setState(() {
                          _selectedTechnicianId = null;
                        });
                        _applyFilters();
                      },
                    ),
                  if (_startDate != null && _endDate != null)
                    _buildFilterChip(
                      'Fechas: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                      () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            if (_selectedTechnicianId != null || _startDate != null || _endDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar Filtros'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTechnicianDropdown() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Filtrar por Técnico',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      value: _selectedTechnicianId,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Todos los Técnicos'),
        ),
        ..._technicians.map((technician) {
          return DropdownMenuItem<int>(
            value: technician.id,
            child: Text(technician.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTechnicianId = value;
        });
        _applyFilters();
      },
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: Colors.grey[200],
    );
  }
  
  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay pagos disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (_selectedTechnicianId != null || _startDate != null || _endDate != null)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar Filtros'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pagos (${_payments.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: ${Formatters.formatCurrency(_payments.fold(0.0, (sum, payment) => sum + payment.paymentAmount))}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _payments.length,
          itemBuilder: (context, index) {
            final payment = _payments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _viewPaymentDetails(payment),
                borderRadius: BorderRadius.circular(12),
                child: PaymentCard(
                  payment: payment,
                  compact: true,
                  showTechnician: true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildRecalculateButton() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recalcular Pagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción recalculará todos los pagos para los servicios completados según la tasa de finalización actual de cada técnico.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRecalculating ? null : _recalculateAllPayments,
                icon: _isRecalculating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRecalculating ? 'Recalculando...' : 'Recalcular Todos los Pagos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}