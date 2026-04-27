import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _primary = Color(0xFF0057B8);

  final List<Map<String, dynamic>> _estaciones = const [
    {
      'nombre': 'Estación 1',
      'descripcion': 'Descripción de la estación',
      'icono': Icons.water_outlined,
      'color': Color(0xFF0057B8),
      'ruta': '/formulario',
      'id': 1,
    },
    {
      'nombre': 'Estación 2',
      'descripcion': 'Descripción de la estación',
      'icono': Icons.speed_outlined,
      'color': Color(0xFF1D9E75),
      'ruta': '/formulario',
      'id': 2,
    },
    {
      'nombre': 'Estación 3',
      'descripcion': 'Descripción de la estación',
      'icono': Icons.compress_outlined,
      'color': Color(0xFF7F77DD),
      'ruta': '/formulario',
      'id': 3,
    },
    {
      'nombre': 'Estación 4',
      'descripcion': 'Descripción de la estación',
      'icono': Icons.science_outlined,
      'color': Color(0xFFBA7517),
      'ruta': '/formulario',
      'id': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Text(
          'SEDA Cusco',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Selecciona una estación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Elige la estación para registrar datos',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: _estaciones.length,
                itemBuilder: (context, index) {
                  final estacion = _estaciones[index];
                  return _EstacionCard(
                    nombre: estacion['nombre'],
                    descripcion: estacion['descripcion'],
                    icono: estacion['icono'],
                    color: estacion['color'],
                    onTap: () => Navigator.pushNamed(
                      context,
                      estacion['ruta'],
                      arguments: {
                        'estacionId': estacion['id'],
                        'estacionNombre': estacion['nombre'],
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Salir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _EstacionCard extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _EstacionCard({
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}