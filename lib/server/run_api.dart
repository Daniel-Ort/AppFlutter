import 'dart:async';
import 'pos_server.dart';

void main(List<String> args) async {
  print('[POS API Service] Iniciando servicio backend en segundo plano...');

  int baseApiPort = 8080;
  int portRange = 100;
  
  // Opcional: Sobrescribir el puerto base de la API por argumentos si se requiere
  for (var arg in args) {
    if (arg.startsWith('--port=')) {
      final parts = arg.split('=');
      if (parts.length > 1) {
        baseApiPort = int.tryParse(parts[1]) ?? 8080;
      }
    }
  }

  const String dbHost = 'localhost';
  const int dbPort = 5432; // Puerto estándar y fijo de PostgreSQL
  const String dbName = 'pos_db';
  const String dbUser = 'postgres';
  const String dbPassword = '';

  final posServer = PosServer();

  try {
    // Arrancar la API pasando el puerto fijo de la base de datos (5432).
    // PosServer buscará dinámicamente un puerto libre solo para la API y guardará ambos en el JSON.
    await posServer.start(
      dbHost: dbHost,
      dbPort: dbPort,
      dbName: dbName,
      dbUser: dbUser,
      dbPassword: dbPassword,
      basePreferredPort: baseApiPort,
      portRange: portRange,
    );

    print('[POS API Service] Backend operando correctamente y configuración guardada.');
  } catch (e) {
    print('[POS API Service] ERROR CRÍTICO: $e');
  }

  // Mantener el servicio ejecutándose en segundo plano
  await Completer<void>().future;
}