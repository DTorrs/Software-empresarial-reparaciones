import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/service.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/services/service_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/widgets/cards/service_card.dart';
import 'package:repair_service_app/widgets/cards/technician_card.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/success_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class SecretaryAssignTechnicianScreen extends StatefulWidget {
  final int? serviceId; // Puede ser nulo si viene desde una lista

  const SecretaryAssignTechnicianScreen({
    Key? key,
    this.serviceId,
  }) : super(key: key);

  @override
  State<SecretaryAssignTechnicianScreen> createState() => _SecretaryAssignTechnicianScreenState();
}

class _SecretaryAssignTechnicianScreenState extends State<SecretaryAssignTechnicianScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final ServiceService _serviceService = ServiceService();
  
  bool _isLoading = true;
  bool _isAssigning = false;
  
  Service? _service;
  List<Technician> _technicians = [];
  List<Technician> _filteredTechnicians = [];
  
  int? _selectedLocationId;
  TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTechnicians);
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterTechnicians);
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterTechnicians() {
    if (_technicians.isEmpty) return;
    
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty && _selectedLocationId == null) {
        _filteredTechnicians = List.from(_technicians);
      } else {
        _filteredTechnicians = _technicians.where((technician) {
          bool matchesQuery = query.isEmpty || 
              technician.name.toLowerCase().contains(query);
          
          bool matchesLocation = _selectedLocationId == null || 
              technician.locationId == _selectedLocationId;
              
          return matchesQuery && matchesLocation;
        }).toList();
      }
    });
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar el servicio si se proporciona un ID
      if (widget.serviceId != null) {
        final serviceResponse = await _serviceService.getServiceById(widget.serviceId!);
        
        if (serviceResponse.success && serviceResponse.data != null) {
          _service = serviceResponse.data;
        } else {
          if (mounted) {
            showErrorDialog(
              context: context,
              title: 'Error',
              message: 'No se pudo cargar el servicio: ${serviceResponse.message}',
            );
          }
        }
      }
      
      // Cargar técnicos disponibles
      final techniciansResponse = await _technicianService.getAvailableTechnicians();
      
      if (techniciansResponse.success && techniciansResponse.data != null) {
        if (mounted) {
          setState(() {
            _technicians = techniciansResponse.data!;
            _filteredTechnicians = List.from(_technicians);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudieron cargar los técnicos: ${techniciansResponse.message}',
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
  
  Future<void> _assignTechnician(int technicianId) async {
    if (_service == null) {
      showErrorDialog(
        context: context,
        title: 'Error',
        message: 'No hay servicio seleccionado para asignar',
      );
      return;
    }
    
    final bool? confirmed = await showConfirmDialog(
      context: context,
      title: 'Asignar Técnico',
      content: '¿Estás seguro de que deseas asignar este técnico al servicio #${_service!.id}?',
      confirmText: 'Asignar',
      cancelText: 'Cancelar',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isAssigning = true;
    });
    
    try {
      final response = await _serviceService.assignTechnician(_service!.id, technicianId);
      
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
        
        if (response.success && response.data != null) {
          final assignedTechnician = _technicians.firstWhere(
            (tech) => tech.id == technicianId,
            orElse: () => Technician(
              id: technicianId,
              userId: 0,
              name: 'Técnico',
              locationId: 0,
              locationName: 'Desconocida',
              isAvailable: true,
              hasPendingWarranty: false,
              completionRate: 0,
              pendingServices: 0,
            ),
          );
          
          setState(() {
            _service = response.data;
          });
          
          await showAnimatedSuccessDialog(
            context: context,
            title: 'Técnico Asignado',
            message: 'El técnico ${assignedTechnician.name} ha sido asignado exitosamente al servicio #${_service!.id}.',
            buttonText: 'Aceptar',
            onButtonPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Volver a la pantalla anterior con resultado exitoso
            },
          );
        } else {
          showErrorDialog(
            context: context,
            title: 'Error',
            message: 'No se pudo asignar el técnico: ${response.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error al asignar el técnico: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _service != null 
            ? 'Asignar Técnico - Servicio #${_service!.id}'
            : 'Asignar Técnico',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Cargando técnicos disponibles...')
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_service != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ServiceCard(
                          service: _service!,
                          compact: true,
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    _buildFilters(),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildTechniciansList(),
                    ),
                  ],
                ),
                if (_isAssigning)
                  const FullscreenLoadingIndicator(
                    message: 'Asignando técnico...',
                  ),
              ],
            ),
    );
  }
  
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar Técnicos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Buscar',
                  hint: 'Nombre del técnico',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onChanged: (_) => _filterTechnicians(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLocationDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Técnicos Disponibles: ${_filteredTechnicians.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedLocationId = null;
                    _filteredTechnicians = List.from(_technicians);
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar Filtros'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationDropdown() {
    // Obtener ubicaciones únicas de los técnicos
    final locationsMap = <int, String>{};
    for (final technician in _technicians) {
      locationsMap[technician.locationId] = technician.locationName;
    }
    
    final locations = locationsMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              hint: const Text('Todas las ubicaciones'),
              value: _selectedLocationId,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas las ubicaciones'),
                ),
                ...locations.map((location) {
                  return DropdownMenuItem<int?>(
                    value: location.key,
                    child: Text(location.value),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                  _filterTechnicians();
                });
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTechniciansList() {
    if (_filteredTechnicians.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.engineering_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron técnicos disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTechnicians.length,
      itemBuilder: (context, index) {
        final technician = _filteredTechnicians[index];
        return TechnicianCard(
          technician: technician,
          showAssignButton: true,
          onTap: () {
            // Se podría mostrar más información del técnico
          },
          onAssign: () => _assignTechnician(technician.id),
        );
      },
    );
  }
}