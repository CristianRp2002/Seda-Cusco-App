import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/formulario/formulario_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEDA Cusco',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme, 
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/formulario': (context) => const FormularioScreen(),
      },
    );
  }
}