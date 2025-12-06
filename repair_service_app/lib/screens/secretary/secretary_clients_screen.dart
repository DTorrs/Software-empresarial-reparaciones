import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/location.dart';
import 'package:repair_service_app/services/client_service.dart';
import 'package:repair_service_app/services/location_service.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_dropdown.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class SecretaryClientsScreen extends StatefulWidget {
  const SecretaryClientsScreen({Key? key}) : super(key: key);

  @override
  State<SecretaryClientsScreen> createState() => _SecretaryClientsScreenState();
}

class _SecretaryClientsScreenState extends State<SecretaryClientsScreen> {
  final ClientService _clientService = ClientService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSearching = false;
  
  List<dynamic> _clients = [];
  List<Location> _locations = [];
  int? _selectedLocationId;
  
  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadLocations();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadLocations() async {
    try {
      final response = await _locationService.getAllLocations();
      
      if (mounted) {
  setState(() {
    if (response.success && response.data != null) {
      _locations = response.data ?? [];
    }
  });

      }
    } catch (e) {
      // Manejo de error silencioso para las ubicaciones
      print('Error loading locations: $e');
    }
  }
  
  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = _selectedLocationId != null
          ? await _clientService.getClientsByLocation(_selectedLocationId!)
          : await _clientService.getAllClients();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _clients = response.data;
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
          message: 'No se pudo cargar la lista de clientes: $e',
        );
      }
    }
  }
  
  Future<void> _searchClients(String term) async {
    if (term.isEmpty) {
      _loadClients();
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final response = await _clientService.searchClients(term);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
          if (response.success && response.data != null) {
            _clients = response.data;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Error en la búsqueda: $e',
        );
      }
    }
  }
  
  void _filterByLocation(int? locationId) {
    setState(() {
      _selectedLocationId = locationId;
    });
    
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Clientes',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Cargando clientes...')
                : _buildClientsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar clientes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadClients();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            _loadClients();
          } else if (value.length >= 3) {
            // Buscar solo si hay al menos 3 caracteres
            _searchClients(value);
          }
        },
        onSubmitted: _searchClients,
      ),
    );
  }
  
  Widget _buildClientsList() {
    if (_clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching
                  ? 'No se encontraron clientes con esa búsqueda'
                  : 'No hay clientes registrados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _loadClients();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Ver todos los clientes'),
              ),
            ],
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.builder(
        itemCount: _clients.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final client = _clients[index];
          return _buildClientCard(client);
        },
      ),
    );
  }
  
  Widget _buildClientCard(dynamic client) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToClientDetails(client['id']),
        borderRadius: BorderRadius.circular(12),
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
                      client['name'].isNotEmpty
                          ? client['name'][0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              client['location_name'] ?? 'Sin ubicación',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showClientOptionsDialog(client),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.home_repair_service,
                    label: 'Servicios',
                    onTap: () => _navigateToClientServices(client['id']),
                  ),
                  _buildActionButton(
                    icon: Icons.add_circle,
                    label: 'Nuevo Servicio',
                    onTap: () => _navigateToNewService(client['id']),
                  ),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Editar',
                    onTap: () => _showEditClientDialog(client),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Clientes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocationDropdown(
              label: 'Ubicación',
              value: _selectedLocationId,
              onChanged: (value) {
                Navigator.pop(context);
                _filterByLocation(value);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedLocationId = null;
                });
                _loadClients();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
              ),
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
  
  void _showClientOptionsDialog(dynamic client) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  client['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                client['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                client['location_name'] ?? 'Sin ubicación',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _navigateToClientDetails(client['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_repair_service),
              title: const Text('Ver servicios'),
              onTap: () {
                Navigator.pop(context);
                _navigateToClientServices(client['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Nuevo servicio'),
              onTap: () {
                Navigator.pop(context);
                _navigateToNewService(client['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar cliente'),
              onTap: () {
                Navigator.pop(context);
                _showEditClientDialog(client);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text(
                'Eliminar cliente',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteClient(client['id'], client['name']);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToClientDetails(int clientId) {
    // Navegación a los detalles del cliente
    // Navigator.pushNamed(context, '/secretary/clients/$clientId');
    // Como placeholder, solo mostraremos un diálogo por ahora
    showInfoDialog(
      context: context,
      title: 'Detalles del Cliente',
      message: 'Aquí se mostrarían los detalles del cliente con ID $clientId',
    );
  }
  
  void _navigateToClientServices(int clientId) {
    // Navegación al historial de servicios del cliente
    // Navigator.pushNamed(context, '/secretary/clients/$clientId/services');
    // Como placeholder, solo mostraremos un diálogo por ahora
    showInfoDialog(
      context: context,
      title: 'Servicios del Cliente',
      message: 'Aquí se mostraría el historial de servicios del cliente con ID $clientId',
    );
  }
  
  void _navigateToNewService(int clientId) {
    // Navegación a la pantalla de nuevo servicio con el cliente preseleccionado
    // Navigator.pushNamed(
    //   context,
    //   '/secretary/services/new',
    //   arguments: {'clientId': clientId},
    // );
    // Como placeholder, solo mostraremos un diálogo por ahora
    showInfoDialog(
      context: context,
      title: 'Nuevo Servicio',
      message: 'Aquí se crearía un nuevo servicio para el cliente con ID $clientId',
    );
  }
  
  void _showAddClientDialog() {
    // Aquí se mostraría un formulario para agregar un nuevo cliente
    // Como placeholder, solo mostraremos un diálogo informativo
    showInfoDialog(
      context: context,
      title: 'Nuevo Cliente',
      message: 'Aquí se mostraría un formulario para agregar un nuevo cliente',
    );
  }
  
  void _showEditClientDialog(dynamic client) {
    // Aquí se mostraría un formulario para editar el cliente
    // Como placeholder, solo mostraremos un diálogo informativo
    showInfoDialog(
      context: context,
      title: 'Editar Cliente',
      message: 'Aquí se mostraría un formulario para editar el cliente ${client['name']}',
    );
  }
  
  void _confirmDeleteClient(int clientId, String clientName) {
    showDeleteConfirmDialog(
      context: context,
      title: 'Eliminar Cliente',
      content: '¿Estás seguro de que deseas eliminar al cliente "$clientName"?\n\n'
          'Esta acción no se puede deshacer.',
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteClient(clientId);
      }
    });
  }
  
  Future<void> _deleteClient(int clientId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Aquí se haría la llamada para eliminar el cliente
      // final response = await _clientService.deleteClient(clientId);
      
      // Como placeholder, asumimos que la eliminación fue exitosa
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Eliminar el cliente de la lista local
          _clients.removeWhere((client) => client['id'] == clientId);
        });
        
        showSuccessDialog(
          context: context,
          title: 'Cliente Eliminado',
          message: 'El cliente ha sido eliminado exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo eliminar el cliente: $e',
        );
      }
    }
  }
}

// Para simular el servicio de clientes mientras se implementa el real
class ClientService {
  Future<dynamic> getAllClients() async {
    // Simulación de respuesta exitosa
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'success': true,
      'data': [
        {
          'id': 1,
          'name': 'Juan Pérez',
          'email': 'juan@example.com',
          'location_name': 'CDMX',
          'created_at': '2023-01-15T10:30:00Z',
        },
        {
          'id': 2,
          'name': 'María López',
          'email': 'maria@example.com',
          'location_name': 'Monterrey',
          'created_at': '2023-02-20T14:15:00Z',
        },
        {
          'id': 3,
          'name': 'Carlos Gómez',
          'email': 'carlos@example.com',
          'location_name': 'Guadalajara',
          'created_at': '2023-03-10T09:45:00Z',
        },
        {
          'id': 4,
          'name': 'Ana Rodríguez',
          'email': 'ana@example.com',
          'location_name': 'CDMX',
          'created_at': '2023-04-05T16:20:00Z',
        },
        {
          'id': 5,
          'name': 'Roberto Díaz',
          'email': 'roberto@example.com',
          'location_name': 'Querétaro',
          'created_at': '2023-05-12T11:10:00Z',
        },
      ]
    };
  }
  
  Future<dynamic> getClientsByLocation(int locationId) async {
    // Simulación de respuesta exitosa
    await Future.delayed(const Duration(seconds: 1));
    
    final allClients = await getAllClients();
    final filtered = (allClients['data'] as List).where((client) {
      final Map<String, String> locationMap = {
        'CDMX': '1',
        'Estado de México': '2',
        'Monterrey': '3',
        'Guadalajara': '4',
        'Querétaro': '5',
      };
      
      return locationMap[client['location_name']] == locationId.toString();
    }).toList();
    
    return {
      'success': true,
      'data': filtered,
    };
  }
  
  Future<dynamic> searchClients(String term) async {
    // Simulación de respuesta exitosa
    await Future.delayed(const Duration(seconds: 1));
    
    final allClients = await getAllClients();
    final filtered = (allClients['data'] as List).where((client) {
      return client['name'].toLowerCase().contains(term.toLowerCase()) ||
          (client['email'] ?? '').toLowerCase().contains(term.toLowerCase());
    }).toList();
    
    return {
      'success': true,
      'data': filtered,
    };
  }
}