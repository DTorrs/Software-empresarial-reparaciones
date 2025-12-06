import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_dropdown.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

extension ServiceStatusExtension on String {
  String get formattedServiceStatus {
    switch (this) {
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
   Color get serviceStatusColor {
    switch (this) {
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
}

// Extensión para Service para agregar propiedades faltantes
extension ServiceExtension on Service {
  String? get technicianLocationName {
    // Implementación simplificada
    return 'No disponible';
  }

  String get clientLocationName {
    // Implementación simplificada
    return 'No disponible';
  }
}

class SecretaryServiceDetailsScreen extends StatefulWidget {
  final int serviceId;

  const SecretaryServiceDetailsScreen({
    Key? key,
    required this.serviceId,
  }) : super(key: key);

  @override
  State<SecretaryServiceDetailsScreen> createState() => _SecretaryServiceDetailsScreenState();
}

class _SecretaryServiceDetailsScreenState extends State<SecretaryServiceDetailsScreen> with SingleTickerProviderStateMixin {
  final ServiceService _serviceService = ServiceService();
  
  late TabController _tabController;
  Service? _service;
  bool _isLoading = true;
  bool _isUpdating = false;
  
  TextEditingController _estimatedPriceController = TextEditingController();
  TextEditingController _finalPriceController = TextEditingController();
  String? _selectedStatus;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadServiceDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _estimatedPriceController.dispose();
    _finalPriceController.dispose();
    super.dispose();
  }
  
  Future<void> _loadServiceDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _serviceService.getServiceById(widget.serviceId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          if (response.success && response.data != null) {
            _service = response.data;
            _selectedStatus = _service!.status;
            
            // Inicializar controladores
            _estimatedPriceController = TextEditingController(
              text: _service!.estimatedPrice?.toString() ?? '',
            );
            _finalPriceController = TextEditingController(
              text: _service!.finalPrice?.toString() ?? '',
            );
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
          message: 'No se pudo cargar los detalles del servicio. Por favor, inténtalo de nuevo.',
        );
      }
    }
  }
  
  Future<void> _updateServiceStatus(String newStatus) async {
    if (_service == null) return;
    
    // Confirmar cambio de estado
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: 'Cambiar Estado',
      content: '¿Estás seguro de cambiar el estado del servicio a ${newStatus.formattedServiceStatus}?',
      confirmText: 'Cambiar Estado',
      cancelText: 'Cancelar',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final response = await _serviceService.updateServiceStatus(
        _service!.id,
        newStatus,
      );
      
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        if (response.success && response.data != null) {
          // Actualizar servicio en estado local
          setState(() {
            _service = response.data;
            _selectedStatus = _service!.status;
          });
          
          showSuccessDialog(
            context: context,
            title: 'Estado Actualizado',
            message: 'El estado del servicio ha sido actualizado a ${newStatus.formattedServiceStatus}.',
            buttonText: 'Aceptar',
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al actualizar el estado del servicio.',
        );
      }
    }
  }
  
  Future<void> _updatePrice(bool isFinal) async {
    if (_service == null) return;
    
    final controller = isFinal ? _finalPriceController : _estimatedPriceController;
    final price = double.tryParse(controller.text);
    
    if (price == null || price <= 0) {
      showErrorDialog(
        context: context,
        title: 'Error',
        message: 'Por favor, ingresa un precio válido mayor a cero.',
      );
      return;
    }
    
    // Confirmar cambio de precio
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: isFinal ? 'Actualizar Precio Final' : 'Actualizar Presupuesto',
      content: '¿Estás seguro de establecer el ${isFinal ? 'precio final' : 'presupuesto'} en ${Formatters.formatCurrency(price)}?',
      confirmText: 'Actualizar',
      cancelText: 'Cancelar',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final response = isFinal
          ? await _serviceService.updateFinalPrice(_service!.id, price)
          : await _serviceService.updateEstimatedPrice(_service!.id, price);
      
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        if (response.success && response.data != null) {
          // Actualizar servicio en estado local
          setState(() {
            _service = response.data;
          });
          
          showSuccessDialog(
            context: context,
            title: isFinal ? 'Precio Final Actualizado' : 'Presupuesto Actualizado',
            message: 'El ${isFinal ? 'precio final' : 'presupuesto'} del servicio ha sido actualizado a ${Formatters.formatCurrency(price)}.',
            buttonText: 'Aceptar',
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al actualizar el ${isFinal ? 'precio final' : 'presupuesto'} del servicio.',
        );
      }
    }
  }
  
  Future<void> _createWarrantyService() async {
    if (_service == null) return;
    
    // Verificar que el servicio esté completado
    if (_service!.status != 'completed') {
      showErrorDialog(
        context: context,
        title: 'Error',
        message: 'Solo se pueden crear garantías para servicios completados.',
      );
      return;
    }
    
    // Confirmar creación de garantía
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: 'Crear Garantía',
      content: '¿Estás seguro de crear una garantía para este servicio?',
      confirmText: 'Crear Garantía',
      cancelText: 'Cancelar',
      icon: Icons.verified,
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final response = await _serviceService.createWarrantyService(_service!.id);
      
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        if (response.success && response.data != null) {
          // Mostrar diálogo de éxito
          final newService = response.data as Service;
          
          // ignore: use_build_context_synchronously
          showWarrantyCreatedDialog(
            context: context,
            warrantyServiceId: newService.id,
            originalServiceId: _service!.id,
            onButtonPressed: () {
              // Navegar a los detalles del nuevo servicio de garantía
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SecretaryServiceDetailsScreen(
                    serviceId: newService.id,
                  ),
                ),
              );
            },
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al crear la garantía.',
        );
      }
    }
  }
  
  Future<void> _assignTechnician() async {
    if (_service == null) return;
    
    // Navegar a la pantalla de asignación de técnico
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.secretaryAssignTechnician,
      arguments: _service!.id,
    );
    
    if (result == true) {
      _loadServiceDetails();
    }
  }
  
  Future<void> _sendClientMessage() async {
    if (_service == null) return;
    
    // Mostrar diálogo para seleccionar tipo de mensaje
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Mensaje al Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.waving_hand),
              title: const Text('Mensaje de Bienvenida'),
              onTap: () {
                Navigator.pop(context);
                _sendSpecificMessage('welcome');
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Enviar Presupuesto'),
              onTap: () {
                Navigator.pop(context);
                _sendSpecificMessage('quote');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Notificar Finalización'),
              onTap: () {
                Navigator.pop(context);
                _sendSpecificMessage('completion');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Recordatorio de Pago'),
              onTap: () {
                Navigator.pop(context);
                _sendSpecificMessage('payment-reminder');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendSpecificMessage(String messageType) async {
    if (_service == null) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Simulamos llamada a API, aquí deberías llamar al servicio real
      // Este es solo un placeholder, debes implementar un TwilioService real
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        showSuccessDialog(
          context: context,
          title: 'Mensaje Enviado',
          message: 'El mensaje ha sido enviado exitosamente al cliente.',
          buttonText: 'Aceptar',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al enviar el mensaje.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Cargando Servicio',
        ),
        body: const LoadingIndicator(message: 'Cargando detalles del servicio...'),
      );
    }
    
    if (_service == null) {
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
              const Text(
                'No se pudieron cargar los detalles del servicio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadServiceDetails,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Servicio #${_service!.id}',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isUpdating ? null : _loadServiceDetails,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildServiceHeader(),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: 'DETALLES'),
                  Tab(text: 'FOTOS'),
                  Tab(text: 'HISTORIAL'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildPhotosTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_isUpdating)
            const FullscreenLoadingIndicator(
              message: 'Actualizando servicio...',
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }
  
  Widget _buildServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _service!.status.serviceStatusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _service!.status.serviceStatusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_service!.deviceType} ${_service!.deviceBrand}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${_service!.clientName}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _service!.status.serviceStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _service!.status.serviceStatusColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(_service!.status),
                      color: _service!.status.serviceStatusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _service!.status.formattedServiceStatus,
                      style: TextStyle(
                        color: _service!.status.serviceStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_service!.isWarranty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warrantyServiceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warrantyServiceColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppTheme.warrantyServiceColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Servicio de garantía - Original #${_service!.originalServiceId}',
                    style: const TextStyle(
                      color: AppTheme.warrantyServiceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tipo: ${_service!.serviceType == 'repair' ? 'Reparación' : 'Mantenimiento'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              if (_service!.assignedDate != null)
                Text(
                  'Asignado: ${Formatters.formatShortDate(_service!.assignedDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Información del Dispositivo'),
          _buildInfoRow('Tipo de Dispositivo', _service!.deviceType),
          _buildInfoRow('Marca', _service!.deviceBrand),
          _buildInfoRow('Descripción del Problema', _service!.issueDescription),
          _buildInfoRow('Tipo de Servicio', _service!.serviceType == 'repair' ? 'Reparación' : 'Mantenimiento'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Información del Cliente'),
          _buildInfoRow('Nombre', _service!.clientName),
          
          // Esta información está encriptada en el backend y no debería mostrarse
          // directamente en la UI en un caso real. Aquí es un placeholder.
          _buildInfoRow('Ubicación', _service!.clientLocationName ?? 'No disponible'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Estado y Fechas'),
          _buildStatusDropdown(),
          if (_service!.assignedDate != null)
            _buildInfoRow('Fecha de Asignación', Formatters.formatDateTime(_service!.assignedDate!)),
          if (_service!.completedDate != null)
            _buildInfoRow('Fecha de Finalización', Formatters.formatDateTime(_service!.completedDate!)),
          _buildInfoRow('Fecha de Creación', Formatters.formatDateTime(_service!.createdAt!)),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Técnico Asignado'),
          _service!.technicianName != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Nombre', _service!.technicianName!),
                    _buildInfoRow('Ubicación', _service!.technicianLocationName ?? 'No disponible'),
                    TextButton.icon(
                      onPressed: _assignTechnician,
                      icon: const Icon(Icons.edit),
                      label: const Text('Cambiar Técnico'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No hay técnico asignado',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _assignTechnician,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Asignar Técnico'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Información de Precio'),
          _buildPriceField(false),
          _buildPriceField(true),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Estado:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _service!.status.serviceStatusColor,
                  ),
                ),
              ),
              items: _getAvailableStatuses().map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: status.serviceStatusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(status.formattedServiceStatus),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null && newValue != _service!.status) {
                  _updateServiceStatus(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceField(bool isFinal) {
    final controller = isFinal ? _finalPriceController : _estimatedPriceController;
    final currentValue = isFinal ? _service!.finalPrice : _service!.estimatedPrice;
    final label = isFinal ? 'Precio Final' : 'Presupuesto';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Ingrese $label',
                      prefixText: '\$ ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updatePrice(isFinal),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  child: Text('Actualizar $label'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotosTab() {
    final bool hasBeforePhotos = _service!.beforePhotos.isNotEmpty;
    final bool hasAfterPhotos = _service!.afterPhotos.isNotEmpty;
    
    if (!hasBeforePhotos && !hasAfterPhotos) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay fotos disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El técnico debe subir fotos del dispositivo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBeforePhotos) ...[
            _buildSectionHeader('Fotos Antes de la Reparación'),
            _buildPhotoGrid(_service!.beforePhotos),
            const SizedBox(height: 24),
          ],
          if (hasAfterPhotos) ...[
            _buildSectionHeader('Fotos Después de la Reparación'),
            _buildPhotoGrid(_service!.afterPhotos),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPhotoGrid(List<ServicePhoto> photos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return InkWell(
          onTap: () => _viewPhoto(photo),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.photoPath,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    color: Colors.black.withOpacity(0.6),
                    child: Text(
                      'Foto ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _viewPhoto(ServicePhoto photo) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  'Foto de ${photo.photoType == 'before' ? 'Antes' : 'Después'}',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    photo.photoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Subido el ${Formatters.formatDateTime(photo.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHistoryTab() {
    // Aquí simularemos un historial de eventos para el servicio
    // En una implementación real, estos datos vendrían de la API
    final events = [
      {
        'date': '10/05/2023 10:30',
        'event': 'Servicio creado',
        'user': 'María López',
        'icon': Icons.create,
        'color': Colors.blue,
      },
      {
        'date': '10/05/2023 11:15',
        'event': 'Técnico asignado: ${_service!.technicianName ?? 'No asignado'}',
        'user': 'María López',
        'icon': Icons.assignment_ind,
        'color': AppTheme.assignedServiceColor,
      },
      {
        'date': '10/05/2023 14:22',
        'event': 'Mensaje enviado al cliente: Bienvenida',
        'user': 'Sistema',
        'icon': Icons.message,
        'color': Colors.green,
      },
      {
        'date': '11/05/2023 09:45',
        'event': 'Presupuesto actualizado: \$${_service!.estimatedPrice ?? 0}',
        'user': _service!.technicianName ?? 'No asignado',
        'icon': Icons.monetization_on,
        'color': Colors.amber,
      },
      {
        'date': '11/05/2023 10:00',
        'event': 'Mensaje enviado al cliente: Presupuesto',
        'user': 'Sistema',
        'icon': Icons.message,
        'color': Colors.green,
      },
      if (_service!.status == 'completed')
        {
          'date': '12/05/2023 15:30',
          'event': 'Servicio completado',
          'user': _service!.technicianName ?? 'No asignado',
          'icon': Icons.check_circle,
          'color': AppTheme.completedServiceColor,
        },
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (event['color'] as Color).withOpacity(0.2),
              child: Icon(
                event['icon'] as IconData,
                color: event['color'] as Color,
                size: 20,
              ),
            ),
            title: Text(
              event['event'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'Por: ${event['user']}',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            trailing: Text(
              event['date'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            onPressed: _sendClientMessage,
            icon: const Icon(Icons.message),
            label: const Text('Enviar Mensaje'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _service!.status == 'completed' && !_service!.isWarranty
                ? _createWarrantyService
                : null,
            icon: const Icon(Icons.verified),
            label: const Text('Crear Garantía'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              backgroundColor: AppTheme.warrantyServiceColor,
              disabledBackgroundColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'assigned':
        return Icons.assignment_ind;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
  
  List<String> _getAvailableStatuses() {
    return ['new', 'assigned', 'in_progress', 'completed', 'cancelled'];
  }
}