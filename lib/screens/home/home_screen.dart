import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/estacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/estacion_service.dart';
import '../../screens/login/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EstacionModel> _estaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstaciones();
  }

  Future<void> _cargarEstaciones() async {
    final token = context.read<AuthProvider>().token!;
    final estaciones = await EstacionService.getEstaciones(token);
    setState(() {
      _estaciones = estaciones;
      _isLoading = false;
    });
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'SEDA Cusco',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${user.nombreCompleto}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona una estación',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Text(
                    'Elige la estación para registrar datos',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _estaciones.length,
                      itemBuilder: (context, index) {
                        final estacion = _estaciones[index];
                        return _EstacionCard(estacion: estacion);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EstacionCard extends StatelessWidget {
  final EstacionModel estacion;

  const _EstacionCard({required this.estacion});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navegación al formulario (siguiente paso)
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.water,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const Spacer(),
            Text(
              estacion.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${estacion.bombas.length} bombas · ${estacion.activos.length} activos',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (estacion.ultimoTotalizador != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tot: ${estacion.ultimoTotalizador} m³',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}