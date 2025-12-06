import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/utils/validators.dart';
import 'package:repair_service_app/widgets/cards/service_card.dart';
import 'package:repair_service_app/widgets/common/app_drawer.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class SecretaryWarrantyScreen extends StatefulWidget {
  final int? serviceId; // ID de servicio para pre-seleccionar (opcional)
  
  const SecretaryWarrantyScreen({
    Key? key,
    this.serviceId,
  }) : super(key: key);

  @override
  State<SecretaryWarrantyScreen> createState() => _SecretaryWarrantyScreenState();
}

class _SecretaryWarrantyScreenState extends State<SecretaryWarrantyScreen> with SingleTickerProviderStateMixin {
  final _serviceIdController = TextEditingController();
  final _searchController = TextEditingController();
  final _issueController = TextEditingController();
  
  final ServiceService _serviceService = ServiceService();
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = true;
  bool _isCreatingWarranty = false;
  
  Service? _selectedService;
  Service? _originalService;
  
  List<Service> _completedServices = [];
  List<Service> _warrantyServices = [];
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Preseleccionar servicio si viene con ID
    if (widget.serviceId != null) {
      _serviceIdController.text = widget.serviceId.toString();
    }
    
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _serviceIdController.dispose();
    _searchController.dispose();
    _issueController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar usuario actual
      final userResponse = await _authService.verifyToken();
      
      if (userResponse.success && userResponse.data != null) {
        _currentUser = userResponse.data;
      }
      
      // Cargar servicios completados
      final completedResponse = await _serviceService.getServicesByStatus('completed');
      
     if (completedResponse.success && completedResponse.data != null) {
  _completedServices = completedResponse.data ?? [];
}
      
      // Cargar garantías existentes
      final warrantyResponse = await _serviceService.getWarrantyServices();
      
     if (warrantyResponse.success && warrantyResponse.data != null) {
  _warrantyServices = warrantyResponse.data ?? [];
}
      
      // Si hay un servicio preseleccionado, cargarlo
      if (widget.serviceId != null) {
        await _findOriginalService();
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
        });
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar los datos: $e',
        );
      }
    }
  }
  
  // Buscar servicio original por ID
  Future<void> _findOriginalService() async {
    if (_serviceIdController.text.isEmpty) {
      setState(() {
        _originalService = null;
      });
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final serviceId = int.tryParse(_serviceIdController.text);
      
      if (serviceId == null) {
        if (mounted) {
          showErrorDialog(
            context: context,
            title: 'ID Inválido',
            message: 'Por favor ingresa un número de servicio válido.',
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      final response = await _serviceService.getServiceById(serviceId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (response.success && response.data != null) {
          // Verificar si el servicio está completado
         if (response.data?.status.toLowerCase() != 'completed') {
            showWarningDialog(
              context: context,
              title: 'Servicio No Completado',
              message: 'Solo se pueden crear garantías para servicios completados.',
            );
            setState(() {
              _originalService = null;
            });
            return;
          }
          
          // Verificar si ya es una garantía
          if (response.data?.isWarranty == true) {
            showWarningDialog(
              context: context,
              title: 'Servicio Ya Es Garantía',
              message: 'No se puede crear una garantía a partir de otra garantía.',
            );
            setState(() {
              _originalService = null;
            });
            return;
          }
          
          setState(() {
            _originalService = response.data;
          });
        } else {
          showErrorDialog(
            context: context,
            title: 'Servicio No Encontrado',
            message: 'No se encontró ningún servicio con el ID ${_serviceIdController.text}',
          );
          setState(() {
            _originalService = null;
          });
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
          message: 'Error al buscar servicio: $e',
        );
      }
    }
  }
  
  // Crear garantía
  Future<void> _createWarranty() async {
    if (_originalService == null) {
      showErrorDialog(
        context: context,
        title: 'Servicio Requerido',
        message: 'Por favor, selecciona un servicio original antes de crear una garantía.',
      );
      return;
    }
    
    if (_issueController.text.isEmpty) {
      showErrorDialog(
        context: context,
        title: 'Descripción Requerida',
        message: 'Por favor, describe el problema que presenta el equipo.',
      );
      return;
    }
    
    setState(() {
      _isCreatingWarranty = true;
    });
    
    try {
      final response = await _serviceService.createWarrantyService(
        _originalService!.id,
      );
      
      if (mounted) {
        setState(() {
          _isCreatingWarranty = false;
        });
        
        if (response.success && response.data != null) {
          final newWarranty = response.data;
          
          // Limpiar el formulario
          _serviceIdController.clear();
          _issueController.clear();
          setState(() {
            _originalService = null;
          });
          
          // Recargar garantías
          _loadInitialData();
          
          // Mostrar diálogo de éxito
          showWarrantyCreatedDialog(
            context: context,
warrantyServiceId: newWarranty!.id,            originalServiceId: _originalService!.id,
            onButtonPressed: () {
              Navigator.pop(context);
              // Opcional: navegar a los detalles de la garantía
            },
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error al Crear Garantía',
            message: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingWarranty = false;
        });
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al crear garantía: $e',
        );
      }
    }
  }
  
  // Filtrar servicios completados por término de búsqueda
  List<Service> _getFilteredCompletedServices() {
    if (_searchController.text.isEmpty) {
      return _completedServices;
    }
    
    final searchTerm = _searchController.text.toLowerCase();
    
    return _completedServices.where((service) {
      return service.id.toString().contains(searchTerm) ||
             service.clientName.toLowerCase().contains(searchTerm) ||
             service.deviceType.toLowerCase().contains(searchTerm) ||
             service.deviceBrand.toLowerCase().contains(searchTerm) ||
             service.issueDescription.toLowerCase().contains(searchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando servicios...'),
      );
    }
    
    if (_currentUser == null) {
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
                'No se pudo cargar la información del usuario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestión de Garantías',
      ),
      drawer: AppDrawer(
        user: _currentUser!,
        currentRoute: '/secretary/warranty',
          authService: _authService,  // Añadir esta línea

      ),
      body: Column(
        children: [
          _buildCreateWarrantySection(),
          const Divider(height: 1),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWarrantiesListTab(),
                _buildCompletedServicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.verified),
            text: 'Garantías',
          ),
          Tab(
            icon: Icon(Icons.check_circle),
            text: 'Servicios Completados',
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreateWarrantySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warrantyServiceColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: AppTheme.warrantyServiceColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear Nueva Garantía',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete el formulario para crear una garantía',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
                flex: 2,
                child: CustomTextField(
                  label: 'Número de Servicio Original',
                  hint: 'Ej. 123',
                  controller: _serviceIdController,
                  keyboardType: TextInputType.number,
                  suffixIcon: Icons.search,
                  onSuffixIconPressed: _findOriginalService,
                  validator: Validators.validateRequired,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _findOriginalService,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_originalService != null) ...[
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: AppTheme.warrantyServiceColor,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.completedServiceColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Servicio Original #${_originalService!.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Cliente', 
                      _originalService!.clientName,
                      Icons.person,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoItem(
                      'Dispositivo', 
                      '${_originalService!.deviceType} ${_originalService!.deviceBrand}',
                      Icons.devices,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoItem(
                      'Problema Original', 
                      _originalService!.issueDescription,
                      Icons.error_outline,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoItem(
                      'Técnico', 
                      _originalService!.technicianName ?? 'No asignado',
                      Icons.engineering,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Descripción del Problema Actual',
                      hint: 'Describa el problema que presenta el equipo',
                      controller: _issueController,
                      minLines: 2,
                      maxLines: 4,
                      validator: Validators.validateRequired,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingWarranty ? null : _createWarranty,
                        icon: const Icon(Icons.add_circle),
                        label: _isCreatingWarranty
                            ? const Text('Creando Garantía...')
                            : const Text('Crear Garantía'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warrantyServiceColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Ingrese el número de servicio original para crear una garantía. Solo puede crear garantías para servicios completados.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWarrantiesListTab() {
    if (_warrantyServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay garantías registradas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las garantías aparecerán aquí una vez creadas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _warrantyServices.length,
        itemBuilder: (context, index) {
          final service = _warrantyServices[index];
          
          return ServiceCard(
            service: service,
            showWarrantyBadge: true,
            onTap: () {
              // Navegar a detalles del servicio
            },
          );
        },
      ),
    );
  }
  
  Widget _buildCompletedServicesTab() {
    final filteredServices = _getFilteredCompletedServices();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomTextField(
            label: 'Buscar Servicios Completados',
            hint: 'Buscar por ID, cliente, dispositivo...',
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: filteredServices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No hay servicios completados'
                            : 'No se encontraron resultados',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      
                      return ServiceCard(
                        service: service,
                        showWarrantyBadge: false,
                        onTap: () {
                          // Seleccionar este servicio para crear garantía
                          _serviceIdController.text = service.id.toString();
                          _findOriginalService();
                          
                          // Cambiar a la primera pestaña
                          _tabController.animateTo(0);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}