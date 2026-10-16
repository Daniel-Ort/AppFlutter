import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'server/server_setup_helper.dart';
import 'logs/error_logger.dart';
import 'login/login_screen.dart'; // Módulo de login importado

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Usar AppData/Roaming para guardar la configuración de forma segura y persistente
  final Directory appDocDir = Directory(Platform.environment['APPDATA'] ?? Directory.current.path);
  final Directory configDir = Directory('${appDocDir.path}/POSPlugAndPlay');
  if (!await configDir.exists()) {
    await configDir.create(recursive: true);
  }
  final File file = File('${configDir.path}/config.json');

  // 2. Detectar si se pasó un rol por argumentos desde el instalador/acceso directo
  String? argRole;
  for (var arg in args) {
    if (arg.startsWith('--role=')) {
      argRole = arg.split('=')[1];
    }
  }

  String finalRole = 'terminal'; // Valor por defecto de seguridad

  // 3. Lógica de persistencia en AppData
  try {
    if (argRole != null) {
      finalRole = argRole;
      final configData = jsonEncode({'role': finalRole, 'is_configured': true});
      await file.writeAsString(configData);
    } else {
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        finalRole = data['role'] ?? 'terminal';
      } else {
        await file.writeAsString(jsonEncode({'role': 'terminal', 'is_configured': true}));
      }
    }
  } catch (e, stack) {
    print('[Config] Error al leer/escribir el archivo de configuración: $e');
    await ErrorLogger.logError('Lectura/Escritura de Configuración Main', e, stack);
  }

  // 4. Si arrancó como servidor, inicializar base de datos y API REST a través del Helper
  if (finalRole == 'server') {
    try {
      print('[App Main] Configurando motor de base de datos local y API REST...');
      
      await ServerSetupHelper.initializeServer(
        dbHost: 'localhost',
        dbPort: 5432,
        targetDbName: 'pos_db',
        dbUser: 'postgres',
        dbPassword: '',
        onStatusUpdate: (status) {
          print('[Server Setup] $status');
        },
      );

      print('[App Main] ¡Servidor y API REST iniciados con éxito!');
    } catch (e, stack) {
      print('[App Main] Error crítico al levantar el servidor: $e');
      await ErrorLogger.logError('Arranque Principal del Servidor (Main)', e, stack);
    }
  }

  runApp(PosApp(role: finalRole));
}

class PosApp extends StatelessWidget {
  final String role;

  const PosApp({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Plug & Play',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginScreen(role: role), // Inicia directamente con el Login modular
    );
  }
}