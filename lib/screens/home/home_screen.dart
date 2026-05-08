// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/estacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/login/login_screen.dart';
import '../../services/estacion_service.dart';

import '../../widgets/custom_buttom.dart';
import '../../widgets/custom_search.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/station_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EstacionModel> _estaciones = [];
  List<EstacionModel> _estacionesFiltradas = [];

  bool _isLoading = true;

  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstaciones();
  }

  // =====================================================
  // CARGAR ESTACIONES
  // =====================================================

  Future<void> _cargarEstaciones() async {
    try {
      final authProvider =
      context.read<AuthProvider>();

      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        _logout();
        return;
      }

      final estaciones =
      await EstacionService.getEstaciones(
        token,
      );

      if (!mounted) return;

      setState(() {
        _estaciones = estaciones;
        _estacionesFiltradas = estaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar estaciones: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  void _logout() {
    context.read<AuthProvider>().logout();

    Navigator.pushReplacementNamed(
      context,
      '/login',
    );
  }

  // =====================================================
  // BUSCAR
  // =====================================================

  void _filtrarEstaciones(
      String query,
      ) {
    setState(() {
      if (query.isEmpty) {
        _estacionesFiltradas =
            _estaciones;
      } else {
        _estacionesFiltradas =
            _estaciones.where((e) {
              return e.nombre
                  .toLowerCase()
                  .contains(
                query.toLowerCase(),
              );
            }).toList();
      }
    });
  }

  // =====================================================
  // FORMATEAR NÚMEROS
  // =====================================================

  String _formatearNumero(
      num numero,
      ) {
    final partes =
    numero.toString().split('.');

    String intParte = partes[0];

    final reversed =
    intParte.split('').reversed.toList();

    final chunks = <String>[];

    for (int i = 0;
    i < reversed.length;
    i += 3) {
      chunks.add(
        reversed
            .sublist(
          i,
          (i + 3).clamp(
            0,
            reversed.length,
          ),
        )
            .reversed
            .join(),
      );
    }

    return chunks.reversed.join(',') +
        (partes.length > 1
            ? '.${partes[1]}'
            : '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder:
          (context, authProvider, _) {
        final user =
            authProvider.user;

        if (user == null) {
          return const LoginScreen();
        }

        final totalBombas =
        _estaciones.fold<int>(
          0,
              (sum, e) =>
          sum + e.bombas.length,
        );

        final totalActivos =
        _estaciones.fold<int>(
          0,
              (sum, e) =>
          sum + e.activos.length,
        );

        return Scaffold(
          backgroundColor:
          AppTheme.background,

          // ===================================
          // BODY
          // ===================================

          body: _isLoading
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : RefreshIndicator(
            onRefresh:
            _cargarEstaciones,

            child:
            CustomScrollView(
              slivers: [
                // ==========================
                // APP BAR
                // ==========================

                SliverAppBar(
                  pinned: true,

                  expandedHeight: 90,

                  elevation: 0,

                  backgroundColor:
                  AppTheme
                      .primaryBlue,

                  flexibleSpace:
                  Container(
                    decoration:
                    const BoxDecoration(
                      gradient:
                      LinearGradient(
                        begin: Alignment
                            .topLeft,
                        end: Alignment
                            .bottomRight,
                        colors: [
                          AppTheme
                              .darkBlue,
                          AppTheme
                              .primaryBlue,
                        ],
                      ),
                    ),
                  ),

                  title:
                  const Text(
                    'CAPTACIÓN DE AGUAS SUBTERRÁNEAS',

                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                      fontSize: 18,
                      letterSpacing:
                      .3,
                    ),
                  ),

                  actions: [
                    IconButton(
                      onPressed:
                      _logout,

                      icon:
                      const Icon(
                        Icons
                            .logout_rounded,
                      ),
                    ),
                  ],
                ),

                // ==========================
                // CONTENIDO
                // ==========================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.all(
                      18,
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        // ===================
                        // HEADER
                        // ===================

                        Text(
                          'Hola, ${user.nombreCompleto.split(' ').first} 👋',

                          style:
                          const TextStyle(
                            fontSize:
                            30,
                            fontWeight:
                            FontWeight
                                .bold,
                            color: AppTheme
                                .textPrimary,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'Panel de monitoreo operativo',

                          style:
                          TextStyle(
                            fontSize:
                            14,
                            color: AppTheme
                                .textSecondary,
                          ),
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        // ===================
                        // KPI
                        // ===================

                        Row(
                          children: [
                            Expanded(
                              child:
                              KPICard(
                                title:
                                'Estaciones',
                                value:
                                '${_estaciones.length}',
                                icon:
                                Icons.water,
                              ),
                            ),

                            const SizedBox(
                              width:
                              14,
                            ),

                            Expanded(
                              child:
                              KPICard(
                                title:
                                'Bombas',
                                value:
                                '$totalBombas',
                                icon:
                                Icons.settings_input_component,
                              ),
                            ),

                            const SizedBox(
                              width:
                              14,
                            ),

                            Expanded(
                              child:
                              KPICard(
                                title:
                                'Activos',
                                value:
                                '$totalActivos',
                                icon:
                                Icons.bolt_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ===================
                        // SEARCH
                        // ===================

                        CustomSearchBar(
                          onChanged:
                          _filtrarEstaciones,
                        ),

                        const SizedBox(
                          height: 28,
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================
                // LISTA
                // ==========================

                SliverPadding(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal:
                    18,
                  ),

                  sliver:
                  SliverList(
                    delegate:
                    SliverChildBuilderDelegate(
                          (
                          context,
                          index,
                          ) {
                        final estacion =
                        _estacionesFiltradas[
                        index];

                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            bottom:
                            20,
                          ),

                          child:
                          StationCard(
                            estacion:
                            estacion,

                            formatearNumero:
                            _formatearNumero,
                          ),
                        );
                      },

                      childCount:
                      _estacionesFiltradas
                          .length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                  SizedBox(
                    height:
                    120,
                  ),
                ),
              ],
            ),
          ),

          // ===================================
          // FLOATING BUTTON
          // ===================================

          floatingActionButton:
          FloatingActionButton(
            onPressed: () {},

            backgroundColor:
            AppTheme.accentCyan,

            child: const Icon(
              Icons.add_rounded,
              size: 30,
            ),
          ),

          // ===================================
          // BOTTOM NAVIGATION
          // ===================================

          bottomNavigationBar:
          CustomBottomNav(
            currentIndex:
            _currentNavIndex,

            onTap: (index) {
              setState(() {
                _currentNavIndex =
                    index;
              });
            },
          ),
        );
      },
    );
  }
}