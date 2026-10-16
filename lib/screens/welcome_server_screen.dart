import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeServerScreen extends StatelessWidget {
  const WelcomeServerScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpia la configuración para pruebas
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/'); // O la ruta de tu pantalla de selección de rol
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Plug & Play - Servidor Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Reiniciar Configuración',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 96,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Bienvenido al Sistema, Administrador!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'El motor de base de datos PostgreSQL Portable y la API local están operando correctamente en este equipo.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: const [
                      ListTile(
                        leading: Icon(Icons.dns, color: Colors.blue),
                        title: Text('Estado del Servidor'),
                        subtitle: Text('Activo en localhost:5432'),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.security, color: Colors.orange),
                        title: Text('Rol de Equipo'),
                        subtitle: Text('Servidor Principal / Central'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Aquí puedes navegar a la pantalla de ventas (POS principal)
                  // Navigator.pushReplacementNamed(context, '/pos_home');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Entrando al módulo de ventas!')),
                  );
                },
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Iniciar Operaciones de Caja'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}