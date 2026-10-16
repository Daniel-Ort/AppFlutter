import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import '../logs/error_logger.dart';
import 'pos_server.dart';

class ServerSetupHelper {
  
  /// Conecta con el motor PostgreSQL y levanta la API del POS de forma limpia usando puertos dinámicos.
  static Future<void> initializeServer({
    required String dbHost,
    required int dbPort,
    required String targetDbName,
    required String dbUser,
    required String dbPassword,
    int basePreferredPort = 8080,
    int portRange = 100,
    required void Function(String status) onStatusUpdate,
  }) async {
    try {
      onStatusUpdate('Verificando conexión con el servicio de base de datos...');
      await Future.delayed(const Duration(seconds: 2));

      // 1. Conectarse a la base de datos por defecto 'postgres' para crear la del POS
      onStatusUpdate('Configurando bases de datos y esquemas...');
      try {
        final adminConnection = await Connection.open(
          Endpoint(
            host: dbHost,
            port: dbPort,
            database: 'postgres',
            username: dbUser,
            password: '', 
          ),
          settings: const ConnectionSettings(sslMode: SslMode.disable),
        );

        final dbCheckResult = await adminConnection.execute(
          Sql.named('SELECT 1 FROM pg_database WHERE datname = @dbname'),
          parameters: {'dbname': targetDbName},
        );

        if (dbCheckResult.isEmpty) {
          await adminConnection.execute('CREATE DATABASE "$targetDbName";');
        }

        await adminConnection.close();
      } catch (e, stack) {
        await ErrorLogger.logError('Conexión Admin o Creación de Base de Datos', e, stack);
        rethrow;
      }

      // 2. Conectarse a la base de datos del POS y crear tablas de usuarios
      try {
        final posConnection = await Connection.open(
          Endpoint(
            host: dbHost,
            port: dbPort,
            database: targetDbName,
            username: dbUser,
            password: '',
          ),
          settings: const ConnectionSettings(sslMode: SslMode.disable),
        );

        await posConnection.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            role VARCHAR(20) NOT NULL DEFAULT 'admin',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        ''');

        await posConnection.execute(
          Sql.named('''
            INSERT INTO users (username, password_hash, role)
            VALUES (@username, @password, @role)
            ON CONFLICT (username) DO NOTHING;
          '''),
          parameters: {
            'username': 'admin',
            'password': 'admin123',
            'role': 'admin',
          },
        );

        await posConnection.close();
      } catch (e, stack) {
        await ErrorLogger.logError('Migración de Esquemas y Semilla de Usuarios', e, stack);
        rethrow;
      }

      // 3. Levantar la API de Shelf de forma centralizada y asíncrona pasando el rango dinámico
      onStatusUpdate('Iniciando API del Servidor POS...');
      final posServer = PosServer();
      
      Future.microtask(() async {
        try {
          await posServer.start(
            dbHost: dbHost,
            dbPort: dbPort,
            dbName: targetDbName,
            dbUser: dbUser,
            dbPassword: dbPassword,
            basePreferredPort: basePreferredPort,
            portRange: portRange,
          );
        } catch (e, stack) {
          await ErrorLogger.logError('Servicio de API REST (Shelf)', e, stack);
        }
      });

      onStatusUpdate('¡Servidor configurado y operando con éxito!');

    } catch (e, stack) {
      await ErrorLogger.logError('Flujo General de Inicialización del Servidor', e, stack);
      if (kDebugMode) {
        print('Error crítico capturado en servidor: $e');
      }
      rethrow;
    }
  }
}