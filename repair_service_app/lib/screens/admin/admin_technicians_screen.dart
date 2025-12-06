import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/location.dart';
import 'package:repair_service_app/models/technician.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/location_service.dart';
import 'package:repair_service_app/services/technician_service.dart';
import 'package:repair_service_app/services/user_service.dart';
import 'package:repair_service_app/utils/formatters.dart';
import 'package:repair_service_app/widgets/cards/technician_card.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_dropdown.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class AdminTechniciansScreen extends StatefulWidget {
  const AdminTechniciansScreen({Key? key}) : super(key: key);

  @override
  State<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends State<AdminTechniciansScreen> {
  final TechnicianService _technicianService = TechnicianService();
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  
  List<Technician> _technicians = [];
  List<Location> _locations = [];
  List<User> _availableUsers = [];
  
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isEditing = false;
  
  int? _selectedLocationFilter;
  String _searchQuery = '';
  
  // Para el formulario de crear/editar técnico
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int? _selectedUserId;
  int? _selectedLocationId;
  bool _isAvailable = true;
  Technician? _technicianToEdit;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar ubicaciones
      final locationsResponse = await _locationService.getAllLocations();
      
      // Cargar técnicos
      final techniciansResponse = await _technicianService.getAllTechnicians();
      
      if (mounted) {
        setState(() {
          if (locationsResponse.success && locationsResponse.data != null) {
  _locations = locationsResponse.data ?? [];
}
          
          if (locationsResponse.success && locationsResponse.data != null) {
  _locations = locationsResponse.data ?? [];
}
          
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
  
  Future<void> _loadAvailableUsers() async {
    try {
      final response = await _userService.getUsersByRole('technician');
      
      if (mounted) {
        if (response.success && response.data != null) {
          // Filtrar usuarios que ya son técnicos
final existingTechnicianUserIds = _technicians.map((t) => t.userId).toSet();
final availableUsers = (response.data ?? []).where(
  (user) => !existingTechnicianUserIds.contains(user.id)
).toList();
          
          setState(() {
            _availableUsers = availableUsers;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar los usuarios disponibles: $e',
        );
      }
    }
  }
  
  List<Technician> get _filteredTechnicians {
    return _technicians.where((technician) {
      // Filtrar por ubicación si hay una seleccionada
      if (_selectedLocationFilter != null && 
          technician.locationId != _selectedLocationFilter) {
        return false;
      }
      
      // Filtrar por término de búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return technician.name.toLowerCase().contains(query) ||
               technician.email?.toLowerCase().contains(query) == true ||
               technician.locationName.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  void _showCreateTechnicianDialog() async {
    // Resetear valores del formulario
    setState(() {
      _selectedUserId = null;
      _selectedLocationId = null;
      _isAvailable = true;
      _technicianToEdit = null;
      _isCreating = true;
    });
    
    // Cargar usuarios disponibles
    await _loadAvailableUsers();
    
    if (!mounted) return;
    
    if (_availableUsers.isEmpty) {
      setState(() {
        _isCreating = false;
      });
      
      showWarningDialog(
        context: context,
        title: 'No hay usuarios disponibles',
        message: 'No hay usuarios con rol de técnico disponibles para asignar. Primero crea un usuario con rol de técnico.',
      );
      return;
    }
    
    _showTechnicianForm();
  }
  
  void _showEditTechnicianDialog(Technician technician) {
    setState(() {
      _technicianToEdit = technician;
      _selectedLocationId = technician.locationId;
      _isAvailable = technician.isAvailable;
      _isEditing = true;
    });
    
    _showTechnicianForm();
  }
  
  void _showTechnicianForm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _isCreating ? 'Crear Técnico' : 'Editar Técnico',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isCreating) ...[
                        _buildUserDropdown(setDialogState),
                        const SizedBox(height: 16),
                      ],
                      if (_isEditing) ...[
                        ReadOnlyTextField(
                          label: 'Nombre',
                          value: _technicianToEdit?.name ?? '',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        if (_technicianToEdit?.email != null)
                          ReadOnlyTextField(
                            label: 'Email',
                            value: _technicianToEdit!.email!,
                            icon: Icons.email,
                          ),
                        const SizedBox(height: 16),
                      ],
                      _buildLocationDropdown(setDialogState),
                      const SizedBox(height: 16),
                      _buildAvailabilitySwitch(setDialogState),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        _buildTechnicianStats(),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isCreating = false;
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _isCreating ? _createTechnician() : _updateTechnician(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(_isCreating ? 'Crear' : 'Guardar'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildUserDropdown(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Usuario',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedUserId,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
          ),
          hint: const Text('Seleccionar usuario'),
          items: _availableUsers.map((user) {
            return DropdownMenuItem<int>(
              value: user.id,
              child: Text('${user.name} (${user.username})'),
            );
          }).toList(),
          onChanged: (value) {
            setDialogState(() {
              _selectedUserId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona un usuario';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildLocationDropdown(StateSetter setDialogState) {
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
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedLocationId,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
          ),
          hint: const Text('Seleccionar ubicación'),
          items: _locations.map((location) {
            return DropdownMenuItem<int>(
              value: location.id,
              child: Text(location.name),
            );
          }).toList(),
          onChanged: (value) {
            setDialogState(() {
              _selectedLocationId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona una ubicación';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildAvailabilitySwitch(StateSetter setDialogState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Disponible',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: _isAvailable,
          onChanged: (value) {
            setDialogState(() {
              _isAvailable = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
  
  Widget _buildTechnicianStats() {
    if (_technicianToEdit == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Tasa de completitud',
          Formatters.formatPercentage(_technicianToEdit!.completionRate),
          Icons.star_rate,
          _getCompletionRateColor(_technicianToEdit!.completionRate),
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Servicios pendientes',
          _technicianToEdit!.pendingServices.toString(),
          Icons.pending_actions,
          Colors.grey[700]!,
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Garantías pendientes',
          _technicianToEdit!.hasPendingWarranty ? 'Sí' : 'No',
          Icons.verified,
          _technicianToEdit!.hasPendingWarranty ? AppTheme.warrantyServiceColor : Colors.grey,
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
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
  
  Future<void> _createTechnician() async {
    if (!_formKey.currentState!.validate()) return;
    
    Navigator.of(context).pop(); // Cerrar diálogo
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _technicianService.createTechnician(
        userId: _selectedUserId!,
        locationId: _selectedLocationId!,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCreating = false;
        });
        
        if (response.success && response.data != null) {
          // Actualizar lista de técnicos
          await _loadData();
          
          showSuccessDialog(
            context: context,
            title: 'Técnico creado',
            message: 'El técnico se ha creado exitosamente.',
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
          _isLoading = false;
          _isCreating = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al crear el técnico: $e',
        );
      }
    }
  }
  
  Future<void> _updateTechnician() async {
    if (!_formKey.currentState!.validate() || _technicianToEdit == null) return;
    
    Navigator.of(context).pop(); // Cerrar diálogo
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _technicianService.updateTechnician(
        _technicianToEdit!.id,
        locationId: _selectedLocationId,
        isAvailable: _isAvailable,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        
        if (response.success && response.data != null) {
          // Actualizar lista de técnicos
          await _loadData();
          
          showSuccessDialog(
            context: context,
            title: 'Técnico actualizado',
            message: 'El técnico se ha actualizado exitosamente.',
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
          _isLoading = false;
          _isEditing = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al actualizar el técnico: $e',
        );
      }
    }
  }
  
  Future<void> _showDeleteTechnicianConfirmation(Technician technician) async {
    final bool? confirm = await showDeleteConfirmDialog(
      context: context,
      title: 'Eliminar Técnico',
      content: '¿Estás seguro de que deseas eliminar al técnico ${technician.name}?\n\n'
          'Esta acción no se puede deshacer.',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _technicianService.deleteTechnician(technician.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (response.success) {
          // Actualizar lista de técnicos
          await _loadData();
          
          showSuccessDialog(
            context: context,
            title: 'Técnico eliminado',
            message: 'El técnico se ha eliminado exitosamente.',
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
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al eliminar el técnico: $e',
        );
      }
    }
  }
  
  Future<void> _updateTechnicianCompletionRate(Technician technician) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _technicianService.updateTechnicianCompletionRate(technician.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (response.success && response.data != null) {
          // Actualizar lista de técnicos
          await _loadData();
          
          showSuccessDialog(
            context: context,
            title: 'Tasa actualizada',
            message: 'La tasa de completitud del técnico se ha actualizado exitosamente.',
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
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error al actualizar la tasa de completitud: $e',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestión de Técnicos',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTechnicianDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Cargando técnicos...')
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(),
        Expanded(
          child: _filteredTechnicians.isEmpty
              ? _buildEmptyState()
              : _buildTechniciansList(),
        ),
      ],
    );
  }
  
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Buscar técnicos',
                  hint: 'Nombre, email o ubicación',
                  suffixIcon: Icons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LocationDropdown(
                  label: 'Filtrar por ubicación',
                  value: _selectedLocationFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedLocationFilter = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total de técnicos: ${_filteredTechnicians.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (_selectedLocationFilter != null || _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedLocationFilter = null;
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar filtros'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
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
          Text(
            _searchQuery.isEmpty && _selectedLocationFilter == null
                ? 'No hay técnicos disponibles'
                : 'No se encontraron técnicos con los filtros actuales',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedLocationFilter == null
                ? 'Crea tu primer técnico haciendo clic en el botón "+"'
                : 'Intenta modificar los filtros de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isNotEmpty || _selectedLocationFilter != null)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedLocationFilter = null;
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTechniciansList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _filteredTechnicians.length,
        itemBuilder: (context, index) {
          final technician = _filteredTechnicians[index];
          return TechnicianCard(
            technician: technician,
            onTap: () => _showEditTechnicianDialog(technician),
            showAssignButton: false,
            showRestrictionBadges: true,
            showProgressBar: true,
          );
        },
      ),
    );
  }
  
  void _showTechnicianOptionsMenu(BuildContext context, Technician technician) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Editar técnico'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditTechnicianDialog(technician);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Actualizar tasa de completitud'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTechnicianCompletionRate(technician);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.toggle_on,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    technician.isAvailable ? 'Marcar como no disponible' : 'Marcar como disponible',
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      final response = await _technicianService.updateTechnician(
                        technician.id,
                        isAvailable: !technician.isAvailable,
                      );
                      
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        if (response.success) {
                          await _loadData();
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
                          _isLoading = false;
                        });
                        
                        showErrorDialog(
                          context: context,
                          title: 'Error',
                          message: 'Error al actualizar el estado del técnico: $e',
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Eliminar técnico',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteTechnicianConfirmation(technician);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
