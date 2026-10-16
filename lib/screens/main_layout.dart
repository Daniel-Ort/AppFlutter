import 'package:flutter/material.dart';
import '../login/login_screen.dart';

class MainLayout extends StatefulWidget {
  final String role;
  final Widget child; // Aquí se carga la pantalla/módulo activo (ej. Operaciones)
  final int selectedNavIndex;

  const MainLayout({
    super.key,
    required this.role,
    required this.child,
    this.selectedNavIndex = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  // Lista de secciones del menú superior
  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Operaciones', 'icon': Icons.handshake_outlined},
    {'title': 'Consultas', 'icon': Icons.inventory_2_outlined},
    {'title': 'Procesos', 'icon': Icons.settings_applications_outlined},
    {'title': 'Reportes', 'icon': Icons.assignment_outlined},
    {'title': 'Estadísticas', 'icon': Icons.pie_chart_outline},
    {'title': 'Configuración', 'icon': Icons.build_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedNavIndex;
  }

  @override
  Widget build(BuildContext context) {
    final bool isServer = widget.role == 'server';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          // ==========================================
          // BARRA DE NAVEGACIÓN SUPERIOR (ESTILO LOGIN)
          // ==========================================
          Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isServer
                    ? [const Color(0xFF134E5E), const Color(0xFF71B280)]
                    : [const Color(0xFF2B5876), const Color(0xFF4E4376)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Identificador de Rol / Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        isServer ? Icons.dns_outlined : Icons.point_of_sale,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isServer ? 'POS SERVER' : 'POS TERMINAL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(color: Colors.white24, indent: 15, endIndent: 15),

                // Pestañas Principales
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final bool isSelected = _currentIndex == index;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                            // Aquí puedes manejar la navegación de pestañas
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            decoration: BoxDecoration(
                              // Actualizado a .withValues(alpha:) para evitar advertencias de deprecación
                              color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.white70, width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item['icon'], color: Colors.white, size: 22),
                                const SizedBox(height: 2),
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Usuario y Salir
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'admin',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Cerrar Sesión',
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        onPressed: () {
                          // Regresar al Login pasando el rol actual de forma directa
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(role: widget.role),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // ÁREA DE CONTENIDO DINÁMICO
          // ==========================================
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}