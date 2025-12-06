import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/widgets/common/app_drawer.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _authService.verifyToken();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _currentUser = response.data;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando dashboard...'),
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
                onPressed: _loadUserData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard Administrador',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: null,
          ),
        ],
      ),
      drawer: AppDrawer(
        user: _currentUser!,
        currentRoute: '/admin/dashboard',
        authService: _authService, // Added required authService parameter
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildStatisticsGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Estado de Servicios'),
              const SizedBox(height: 8),
              _buildServiceStatusChart(),
              const SizedBox(height: 24),
              _buildSectionTitle('Actividad Reciente'),
              const SizedBox(height: 8),
              _buildRecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
    final DateTime now = DateTime.now();
    final String period = now.hour < 12 
        ? 'Buenos días'
        : now.hour < 18 
            ? 'Buenas tardes'
            : 'Buenas noches';
    
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
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 24,
                  child: Text(
                    _currentUser!.name.isNotEmpty 
                        ? _currentUser!.name[0].toUpperCase() 
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$period, ${_currentUser!.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rol: Administrador',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Resumen del sistema',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bienvenido al panel de administración. Aquí podrás gestionar usuarios, ver estadísticas y administrar los servicios de reparación.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatisticCard(
          title: 'Servicios Activos',
          value: '24',
          icon: Icons.home_repair_service,
          color: AppTheme.primaryColor,
        ),
        _buildStatisticCard(
          title: 'Técnicos Disponibles',
          value: '8',
          icon: Icons.engineering,
          color: AppTheme.successColor,
        ),
        _buildStatisticCard(
          title: 'Garantías Pendientes',
          value: '3',
          icon: Icons.verified,
          color: AppTheme.warrantyServiceColor,
        ),
        _buildStatisticCard(
          title: 'Clientes Registrados',
          value: '156',
          icon: Icons.people,
          color: AppTheme.secondaryColor,
        ),
      ],
    );
  }
  
  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const Spacer(),
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
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
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
  
  Widget _buildServiceStatusChart() {
    // Aquí se podría implementar un gráfico real con fl_chart o charts_flutter
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusLegendItem(
                  'Nuevos', 
                  AppTheme.newServiceColor, 
                  '5'
                ),
                _buildStatusLegendItem(
                  'Asignados', 
                  AppTheme.assignedServiceColor, 
                  '12'
                ),
                _buildStatusLegendItem(
                  'En Progreso', 
                  AppTheme.inProgressServiceColor, 
                  '7'
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusLegendItem(
                  'Completados', 
                  AppTheme.completedServiceColor, 
                  '18'
                ),
                _buildStatusLegendItem(
                  'Cancelados', 
                  AppTheme.cancelledServiceColor, 
                  '2'
                ),
                _buildStatusLegendItem(
                  'Garantías', 
                  AppTheme.warrantyServiceColor, 
                  '3'
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[100],
              child: const Center(
                child: Text(
                  'Aquí iría un gráfico de barras o un gráfico circular',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusLegendItem(String label, Color color, String value) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentActivityList() {
    // Lista de eventos recientes
    final List<Map<String, dynamic>> activities = [
      {
        'icon': Icons.assignment_turned_in,
        'color': AppTheme.completedServiceColor,
        'title': 'Servicio completado',
        'description': 'El técnico Juan Pérez completó el servicio #123',
        'time': '10:30 AM',
      },
      {
        'icon': Icons.verified,
        'color': AppTheme.warrantyServiceColor,
        'title': 'Nueva garantía',
        'description': 'Se ha creado garantía #45 para el servicio #89',
        'time': '09:15 AM',
      },
      {
        'icon': Icons.engineering,
        'color': AppTheme.assignedServiceColor,
        'title': 'Técnico asignado',
        'description': 'María López fue asignada al servicio #124',
        'time': 'Ayer',
      },
      {
        'icon': Icons.person_add,
        'color': AppTheme.primaryColor,
        'title': 'Nuevo usuario',
        'description': 'Se ha registrado un nuevo usuario: Carlos Gómez',
        'time': 'Ayer',
      },
      {
        'icon': Icons.home_repair_service,
        'color': AppTheme.newServiceColor,
        'title': 'Nuevo servicio',
        'description': 'Se ha registrado un nuevo servicio: #125',
        'time': '21/10/2023',
      },
    ];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: activity['color'].withOpacity(0.2),
              child: Icon(
                activity['icon'],
                color: activity['color'],
                size: 20,
              ),
            ),
            title: Text(
              activity['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              activity['description'],
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            trailing: Text(
              activity['time'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            onTap: () {
              // Navegar a la vista detallada de la actividad
            },
          );
        },
      ),
    );
  }
}