import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/utils/validators.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/dialogs/confirm_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_dropdown.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AuthService _authService = AuthService();
  
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String? _selectedRole;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulo la carga de usuarios ya que no tenemos un servicio real
      // En un escenario real, usaríamos UserService.getAllUsers()
      await Future.delayed(const Duration(seconds: 1));
      
      // Datos de prueba
      final mockUsers = [
        User(
          id: 1,
          username: 'admin',
          email: 'admin@example.com',
          name: 'Administrador',
          role: 'admin',
          isActive: true,
        ),
        User(
          id: 2,
          username: 'secretaria',
          email: 'secretaria@example.com',
          name: 'María López',
          role: 'secretary',
          isActive: true,
        ),
        User(
          id: 3,
          username: 'tecnico1',
          email: 'tecnico1@example.com',
          name: 'Juan Pérez',
          role: 'technician',
          isActive: true,
        ),
        User(
          id: 4,
          username: 'tecnico2',
          email: 'tecnico2@example.com',
          name: 'Carlos Gómez',
          role: 'technician',
          isActive: false,
        ),
        User(
          id: 5,
          username: 'secretaria2',
          email: 'secretaria2@example.com',
          name: 'Ana Rodríguez',
          role: 'secretary',
          isActive: true,
        ),
      ];
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _users = mockUsers;
          _applyFilters();
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
          message: 'No se pudieron cargar los usuarios: $e',
        );
      }
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Filtro por rol
        if (_selectedRole != null && user.role != _selectedRole) {
          return false;
        }
        
        // Filtro por búsqueda
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return user.name.toLowerCase().contains(query) ||
                 user.username.toLowerCase().contains(query) ||
                 user.email.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
    });
  }
  
  void _showUserFormDialog({User? user}) {
    final bool isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    
    final usernameController = TextEditingController(text: user?.username);
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController();
    
    String? selectedRole = user?.role ?? 'technician';
    bool isActive = user?.isActive ?? true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Nombre de Usuario',
                  hint: 'Ingrese nombre de usuario',
                  controller: usernameController,
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nombre Completo',
                  hint: 'Ingrese nombre completo',
                  controller: nameController,
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Correo Electrónico',
                  hint: 'Ingrese correo electrónico',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final requiredError = Validators.validateRequired(value);
                    if (requiredError != null) return requiredError;
                    
                    return Validators.validateEmail(value);
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Contraseña',
                  hint: isEditing ? 'Dejar en blanco para mantener' : 'Ingrese contraseña',
                  controller: passwordController,
                  obscureText: true,
                  validator: isEditing ? null : Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return CustomDropdown<String>(
                      label: 'Rol',
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'secretary',
                          child: Text('Secretaria'),
                        ),
                        DropdownMenuItem(
                          value: 'technician',
                          child: Text('Técnico'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (isEditing)
                  StatefulBuilder(
                    builder: (context, setState) {
                      return SwitchListTile(
                        title: const Text('Usuario Activo'),
                        value: isActive,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final userData = {
                  'id': user?.id,
                  'username': usernameController.text,
                  'name': nameController.text,
                  'email': emailController.text,
                  'password': passwordController.text,
                  'role': selectedRole,
                  'isActive': isActive,
                };
                
                Navigator.pop(context, userData);
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    ).then((userData) async {
      if (userData != null) {
        if (isEditing) {
          _updateUser(userData);
        } else {
          _createUser(userData);
        }
      }
    });
  }
  
  Future<void> _createUser(Map<String, dynamic> userData) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulo la creación de usuario
      await Future.delayed(const Duration(seconds: 1));
      
      final newUser = User(
        id: _users.length + 1,
        username: userData['username'],
        email: userData['email'],
        name: userData['name'],
        role: userData['role'],
        isActive: userData['isActive'],
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _users.add(newUser);
          _applyFilters();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
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
          message: 'No se pudo crear el usuario: $e',
        );
      }
    }
  }
  
  Future<void> _updateUser(Map<String, dynamic> userData) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulo la actualización de usuario
      await Future.delayed(const Duration(seconds: 1));
      
      final int userId = userData['id'];
      final int index = _users.indexWhere((user) => user.id == userId);
      
      if (index != -1) {
        final updatedUser = User(
          id: userId,
          username: userData['username'],
          email: userData['email'],
          name: userData['name'],
          role: userData['role'],
          isActive: userData['isActive'],
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _users[index] = updatedUser;
            _applyFilters();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
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
          message: 'No se pudo actualizar el usuario: $e',
        );
      }
    }
  }
  
  Future<void> _deleteUser(User user) async {
    final bool? confirm = await showDeleteConfirmDialog(
      context: context,
      title: 'Eliminar Usuario',
      content: '¿Estás seguro de que deseas eliminar al usuario "${user.name}"?\n\n'
          'Esta acción no se puede deshacer.',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulo la eliminación de usuario
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _users.removeWhere((u) => u.id == user.id);
          _applyFilters();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
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
          message: 'No se pudo eliminar el usuario: $e',
        );
      }
    }
  }
  
  Future<void> _toggleUserStatus(User user) async {
    final bool newStatus = !user.isActive;
    final String action = newStatus ? 'activar' : 'desactivar';
    
    final bool? confirm = await showConfirmDialog(
      context: context,
      title: '${newStatus ? 'Activar' : 'Desactivar'} Usuario',
      content: '¿Estás seguro de que deseas $action al usuario "${user.name}"?',
      confirmText: 'Sí, $action',
      cancelText: 'Cancelar',
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulo cambio de estado
      await Future.delayed(const Duration(seconds: 1));
      
      final int index = _users.indexWhere((u) => u.id == user.id);
      
      if (index != -1) {
        final updatedUser = _users[index].copyWith(
          isActive: newStatus,
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _users[index] = updatedUser;
            _applyFilters();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario ${newStatus ? 'activado' : 'desactivado'} exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
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
          message: 'No se pudo cambiar el estado del usuario: $e',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestión de Usuarios',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserFormDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Cargando usuarios...')
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUsersList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, usuario o email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 12),
          // Filtro de roles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Filtrar por rol:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoleChip(null, 'Todos'),
                _buildRoleChip('admin', 'Administradores'),
                _buildRoleChip('secretary', 'Secretarias'),
                _buildRoleChip('technician', 'Técnicos'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoleChip(String? role, String label) {
    final bool isSelected = _selectedRole == role;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRole = selected ? role : null;
            _applyFilters();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
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
            'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedRole != null
                ? 'Prueba con otros filtros de búsqueda'
                : 'Crea un nuevo usuario con el botón +',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty || _selectedRole != null)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedRole = null;
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildUsersList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserListItem(user);
      },
    );
  }
  
  Widget _buildUserListItem(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(user.role),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildRoleBadge(user.role),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('@${user.username}'),
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showUserFormDialog(user: user);
                  break;
                case 'delete':
                  _deleteUser(user);
                  break;
                case 'toggle_status':
                  _toggleUserStatus(user);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      user.isActive ? Icons.block : Icons.check_circle,
                      size: 18,
                      color: user.isActive ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isActive ? 'Desactivar' : 'Activar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _showUserFormDialog(user: user),
        ),
      ),
    );
  }
  
  Widget _buildRoleBadge(String role) {
    String label;
    Color color;
    
    switch (role) {
      case 'admin':
        label = 'Administrador';
        color = Colors.purple;
        break;
      case 'secretary':
        label = 'Secretaria';
        color = Colors.blue;
        break;
      case 'technician':
        label = 'Técnico';
        color = Colors.green;
        break;
      default:
        label = 'Desconocido';
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'secretary':
        return Colors.blue;
      case 'technician':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}