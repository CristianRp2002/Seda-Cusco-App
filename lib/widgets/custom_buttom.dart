import 'package:flutter/material.dart';
import '../core/theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),

      child: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: onTap,

        backgroundColor: Colors.white,

        selectedItemColor: AppTheme.accentCyan,

        unselectedItemColor: Colors.grey,

        elevation: 0,

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Registros',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Alertas',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Opciones',
          ),
        ],
      ),
    );
  }
}