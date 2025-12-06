import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/location.dart';
import 'package:repair_service_app/services/location_service.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  final LocationService _locationService = LocationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  
  List<Location> _locations = [];
  Map<int, Map<String, dynamic>> _locationStats = {};
  bool _isLoading = true;
  bool _isAdding = false;
  Location? _selectedLocation;
  bool _isEditing = false;
  bool _isDeleting = false;
  
  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadLocationStatistics();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _locationService.getAllLocations();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            // Fixed: Safely handle the nullable data and convert to non-nullable List<Location>
            _locations = response.data ?? [];
          } else {
            // If response is not successful or data is null, set to empty list
            _locations = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set to empty list if there's an error
          _locations = [];
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron cargar las ubicaciones: $e',
        );
      }
    }
  }
  
  Future<void> _loadLocationStatistics() async {
  try {
    final response = await _locationService.getLocationStatistics();
    
    if (mounted && response.success && response.data != null) {
      final Map<int, Map<String, dynamic>> stats = {};
      
      // Fixed: Safely handle the nullable response.data
      final locationData = response.data ?? [];
      
      for (final location in locationData) {
        stats[location.id] = {
          'technicians_count': location.techniciansCount ?? 0,
          'services_count': location.servicesCount ?? 0,
          'completed_services': location.completedServices ?? 0,
          'warranty_services': location.warrantyServices ?? 0,
        };
      }
      
      setState(() {
        _locationStats = stats;
      });
    }
  } catch (e) {
    // Manejar error de estadísticas silenciosamente
    print('Error al cargar estadísticas: $e');
  }
}
  
  Future<void> _addLocation() async {
    if (!_formKey.currentState!.validate()) return;
    
    final String name = _nameController.text.trim();
    
    setState(() {
      _isAdding = true;
    });
    
    try {
      final response = await _locationService.createLocation(name);
      
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
        
        if (response.success && response.data != null) {
          // Limpiar el formulario
          _nameController.clear();
          
          // Actualizar la lista
          await _loadLocations();
          await _loadLocationStatistics();
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación creada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Mostrar error
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
          _isAdding = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo crear la ubicación: $e',
        );
      }
    }
  }
  
  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) return;
    
    final String name = _nameController.text.trim();
    
    setState(() {
      _isEditing = true;
    });
    
    try {
      final response = await _locationService.updateLocation(_selectedLocation!.id, name);
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isAdding = false;
          _selectedLocation = null;
        });
        
        if (response.success && response.data != null) {
          // Limpiar el formulario
          _nameController.clear();
          
          // Actualizar la lista
          await _loadLocations();
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación actualizada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Mostrar error
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
          _isEditing = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo actualizar la ubicación: $e',
        );
      }
    }
  }
  
  Future<void> _deleteLocation(Location location) async {
    final bool? confirm = await showDeleteConfirmDialog(
      context: context,
      title: 'Eliminar Ubicación',
      content: '¿Estás seguro de que deseas eliminar la ubicación "${location.name}"?\n\n'
          'Esta acción no se puede deshacer, y fallará si hay técnicos o servicios asociados a esta ubicación.',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final response = await _locationService.deleteLocation(location.id);
      
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        
        if (response.success) {
          // Actualizar la lista
          await _loadLocations();
          await _loadLocationStatistics();
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación eliminada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Mostrar error
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
          _isDeleting = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo eliminar la ubicación: $e',
        );
      }
    }
  }
  
  void _editLocation(Location location) {
    setState(() {
      _selectedLocation = location;
      _nameController.text = location.name;
      _isAdding = true;
    });
  }
  
  void _cancelEdit() {
    setState(() {
      _selectedLocation = null;
      _nameController.clear();
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestión de Ubicaciones',
        actions: [
          IconButton(
            icon: Icon(_isAdding ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                if (_isAdding) {
                  _selectedLocation = null;
                  _nameController.clear();
                }
                _isAdding = !_isAdding;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Cargando ubicaciones...')
          : Stack(
              children: [
                _buildLocationsList(),
                if (_isAdding) _buildAddLocationForm(),
                if (_isDeleting)
                  const FullscreenLoadingIndicator(
                    message: 'Eliminando ubicación...',
                  ),
              ],
            ),
    );
  }
  
  Widget _buildLocationsList() {
    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay ubicaciones registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega una nueva ubicación para comenzar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAdding = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Ubicación'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadLocations();
        await _loadLocationStatistics();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          final stats = _locationStats[location.id] ?? {};
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  location.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                location.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'ID: ${location.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => _editLocation(location),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppTheme.errorColor,
                    ),
                    onPressed: () => _deleteLocation(location),
                  ),
                ],
              ),
              children: [
                _buildStatistics(stats),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatistics(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Técnicos',
                  '${stats['technicians_count'] ?? 0}',
                  Icons.engineering,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Servicios',
                  '${stats['services_count'] ?? 0}',
                  Icons.home_repair_service,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completados',
                  '${stats['completed_services'] ?? 0}',
                  Icons.check_circle,
                  AppTheme.completedServiceColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Garantías',
                  '${stats['warranty_services'] ?? 0}',
                  Icons.verified,
                  AppTheme.warrantyServiceColor,
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
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
        ],
      ),
    );
  }
  
  Widget _buildAddLocationForm() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedLocation == null ? 'Agregar Ubicación' : 'Editar Ubicación',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nombre de la Ubicación',
                  hint: 'Ej. Ciudad de México',
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAdding || _isEditing
                            ? null
                            : _selectedLocation == null
                                ? _addLocation
                                : _updateLocation,
                        child: Text(_selectedLocation == null ? 'Agregar' : 'Actualizar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}