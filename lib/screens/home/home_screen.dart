import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/estacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/estacion_service.dart';
import '../../screens/login/login_screen.dart';
import '../formulario/formulario_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<EstacionModel> _estaciones = [];
  List<EstacionModel> _estacionesFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  int _currentNavIndex = 0;
  bool _showAlert = true;

  late AnimationController _alertAnimController;

  // Colores personalizados
  static const Color _primaryBlue = Color(0xFF0066CC);
  static const Color _lightCyan = Color(0xFFE0F7FF);
  static const Color _darkBlue = Color(0xFF003D99);
  static const Color _accentCyan = Color(0xFF00B8E6);
  static const Color _bgGray = Color(0xFFF5F7FA);
  static const Color _successGreen = Color(0xFF27AE60);
  static const Color _warningOrange = Color(0xFFF39C12);
  static const Color _dangerRed = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _alertAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstaciones();
    });
  }

  @override
  void dispose() {
    _alertAnimController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstaciones() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        _logout();
        return;
      }

      final estaciones = await EstacionService.getEstaciones(token);

      if (mounted) {
        setState(() {
          _estaciones = estaciones;
          _estacionesFiltradas = estaciones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar estaciones: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: _dangerRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _filtrarEstaciones(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _estacionesFiltradas = _estaciones;
      } else {
        _estacionesFiltradas = _estaciones
            .where((estacion) =>
            estacion.nombre.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _formatearNumero(num numero) {
    final partes = numero.toString().split('.');
    String intParte = partes[0];
    final reversed = intParte.split('').reversed.toList();
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.sublist(i, (i + 3).clamp(0, reversed.length)).reversed.join());
    }

    return chunks.reversed.join(',') + (partes.length > 1 ? '.${partes[1]}' : '');
  }

  int _calcularDiasRestantes(DateTime fechaMantenimiento) {
    final ahora = DateTime.now();
    return fechaMantenimiento.difference(ahora).inDays;
  }

  Color _getAlertColor(int diasRestantes) {
    if (diasRestantes < 0) return _dangerRed;
    if (diasRestantes <= 7) return _warningOrange;
    return _successGreen;
  }

  String _getAlertMessage(int diasRestantes) {
    if (diasRestantes < 0) {
      return 'Mantenimiento vencido hace ${diasRestantes.abs()} días';
    }
    if (diasRestantes == 0) return 'Mantenimiento HOY';
    return 'Mantenimiento en $diasRestantes días';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return const LoginScreen();
        }

        return Scaffold(
          backgroundColor: _bgGray,
          body: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
            ),
          )
              : RefreshIndicator(
            onRefresh: _cargarEstaciones,
            color: _primaryBlue,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              slivers: [
                // AppBar personalizado
                SliverAppBar(
                  backgroundColor: _primaryBlue,
                  elevation: 2,
                  pinned: true,
                  expandedHeight: 0,
                  title: const Text(
                    'CAPTACIÓN DE AGUAS SUBTERRANEAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: Colors.white),
                      onPressed: _logout,
                      tooltip: 'Cerrar sesión',
                    ),
                  ],
                ),
                // Contenido
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Alerta dinámica
                        if (_showAlert) _buildAlertCard(),
                        const SizedBox(height: 16),
                        // Bienvenida compacta
                        _buildWelcomeCompact(user.nombreCompleto),
                        const SizedBox(height: 20),
                        // Búsqueda mejorada
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Lista de estaciones
                if (_estacionesFiltradas.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final estacion = _estacionesFiltradas[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _EstacionCard(
                              estacion: estacion,
                              formatearNumero: _formatearNumero,
                            ),
                          );
                        },
                        childCount: _estacionesFiltradas.length,
                      ),
                    ),
                  ),
                // Espacio al final
                SliverToBoxAdapter(
                  child: const SizedBox(height: 20),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: _currentNavIndex == 0
              ? FloatingActionButton(
            backgroundColor: _accentCyan,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Nueva estación en desarrollo')),
              );
            },
            tooltip: 'Agregar estación',
            child: const Icon(Icons.add, color: _primaryBlue),
          )
              : null,
        );
      },
    );
  }

  Widget _buildAlertCard() {
    final diasRestantes = _calcularDiasRestantes(
        DateTime.now().add(const Duration(days: 28)));
    final alertColor = _getAlertColor(diasRestantes);
    final alertMessage = _getAlertMessage(diasRestantes);

    return Dismissible(
      key: const Key('alert'),
      onDismissed: (_) {
        setState(() => _showAlert = false);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alertColor.withOpacity(0.1),
          border: Border.all(
            color: alertColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  diasRestantes < 0 ? Icons.error : Icons.warning_amber,
                  color: alertColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diasRestantes < 0
                            ? '⚠️ Mantenimiento Vencido'
                            : '📅 Próximo Mantenimiento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: alertColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alertMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: alertColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: alertColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Abriendo formulario de contacto...')),
                      );
                    },
                    child: const Text('Contactar Admin'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alertColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Abriendo detalles de mantenimiento...')),
                      );
                    },
                    child: const Text(
                      'Ver detalles',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCompact(String nombreCompleto) {
    final totalBombas =
    _estaciones.fold<int>(0, (sum, e) => sum + e.bombas.length);
    final totalActivos =
    _estaciones.fold<int>(0, (sum, e) => sum + e.activos.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hola, ${nombreCompleto.split(' ').first} 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
            const Spacer(),
            Text(
              '${_estacionesFiltradas.length} activas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCompact('Estaciones', _estaciones.length.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCompact('Bombas', totalBombas.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCompact('Activos', totalActivos.toString()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCompact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primaryBlue,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: _filtrarEstaciones,
        decoration: InputDecoration(
          hintText: 'Buscar estación, ID o zona...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close),
            color: Colors.grey[400],
            onPressed: () {
              _filtrarEstaciones('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No hay estaciones disponibles'
                  : 'No se encontraron estaciones',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Contacta al administrador'
                  : 'Intenta con otro término de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentNavIndex,
        selectedItemColor: _accentCyan,
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: _currentNavIndex == 0
                  ? BoxDecoration(
                color: _accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              )
                  : null,
              child: const Icon(Icons.home),
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: _currentNavIndex == 1
                  ? BoxDecoration(
                color: _accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              )
                  : null,
              child: const Icon(Icons.assignment),
            ),
            label: 'Registros',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: _currentNavIndex == 2
                  ? BoxDecoration(
                color: _accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              )
                  : null,
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: _currentNavIndex == 3
                  ? BoxDecoration(
                color: _accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              )
                  : null,
              child: const Icon(Icons.settings),
            ),
            label: 'Opciones',
          ),
        ],
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('📝 Registros en desarrollo')),
              );
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('🔔 Alertas en desarrollo')),
              );
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('⚙️ Opciones en desarrollo')),
              );
              break;
          }
        },
      ),
    );
  }
}

class _EstacionCard extends StatelessWidget {
  final EstacionModel estacion;
  final Function(num) formatearNumero;

  const _EstacionCard({
    required this.estacion,
    required this.formatearNumero,
  });

  static const Color _primaryBlue = Color(0xFF0066CC);
  static const Color _lightCyan = Color(0xFFE0F7FF);
  static const Color _accentCyan = Color(0xFF00B8E6);
  static const Color _successGreen = Color(0xFF27AE60);
  static const Color _warningOrange = Color(0xFFF39C12);
  static const Color _dangerRed = Color(0xFFE74C3C);

  Color _getEstadoColor() {
    if (estacion.bombas.isEmpty) return _dangerRed;
    if (estacion.activos.isEmpty) return _warningOrange;
    if (estacion.ultimoTotalizador == null) return _warningOrange;
    return _successGreen;
  }

  String _getEstadoText() {
    if (estacion.bombas.isEmpty) return '❌ Sin bombas';
    if (estacion.activos.isEmpty) return '⚠️ Sin activos';
    if (estacion.ultimoTotalizador == null) return '⚠️ Sin datos';
    return '✓ Activa';
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getEstadoColor();
    final totalizado = estacion.ultimoTotalizador ?? 0;
    final totalizadoFormato = formatearNumero(totalizado);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FormularioScreen(estacion: estacion),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightCyan,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estacion.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estación activa',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
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
                      color: estadoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getEstadoText(),
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💧 Totalizador',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalizadoFormato m³',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _accentCyan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCompact('Bombas', '${estacion.bombas.length}'),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildInfoCompact('Activos', '${estacion.activos.length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FormularioScreen(estacion: estacion),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        'Registrar lectura',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCompact(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}