import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

class PosServer {
  HttpServer? _server;

  /// Busca un puerto disponible comenzando desde un puerto base dentro del rango de la capa
  Future<int> _getAvailablePort(int basePort, int maxRange) async {
    for (int i = 0; i < maxRange; i++) {
      int port = basePort + i;
      try {
        // Se añade shared: true para permitir la reutilización limpia del socket
        final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
        await serverSocket.close();
        return port;
      } catch (e) {
        // El puerto está ocupado, probamos con el siguiente
      }
    }
    throw Exception('No se encontraron puertos libres en el rango de $basePort a ${basePort + maxRange}');
  }

  /// Inicia el servidor HTTP de Shelf con puertos dinámicos y persistencia JSON limpia
  Future<int> start({
    required String dbHost,
    required int dbPort,
    required String dbName,
    required String dbUser,
    required String dbPassword,
    int basePreferredPort = 8080,
    int portRange = 100,
  }) async {
    // 1. Encontrar puerto libre de manera dinámica sin hardcodeos
    final int activePort = await _getAvailablePort(basePreferredPort, portRange);

    final router = Router();

    // Estado del servidor
    router.get('/api/status', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'online', 'message': 'Servidor POS activo y operando'}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Login
    router.post('/api/login', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);
        final connection = await _openConnection(dbHost, dbPort, dbName, dbUser, dbPassword);
        
        final result = await connection.execute(
          Sql.named('SELECT id, username, role FROM users WHERE username = @username AND password_hash = @password'),
          parameters: {'username': data['username'], 'password': data['password']},
        );
        await connection.close();

        if (result.isEmpty) {
          return Response.forbidden(jsonEncode({'error': 'Credenciales inválidas'}), headers: {'Content-Type': 'application/json'});
        }

        final user = result.first;
        return Response.ok(
          jsonEncode({'success': true, 'user': {'id': user[0], 'username': user[1], 'role': user[2]}}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'Content-Type': 'application/json'});
      }
    });

    // Productos
    router.get('/api/products', (Request request) async {
      try {
        final connection = await _openConnection(dbHost, dbPort, dbName, dbUser, dbPassword);
        final result = await connection.execute('SELECT id, name, price, stock FROM products');
        await connection.close();

        final products = result.map((row) => {'id': row[0], 'name': row[1], 'price': row[2], 'stock': row[3]}).toList();
        return Response.ok(jsonEncode(products), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
      }
    });

    final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    // 2. Levantar servidor HTTP incluyendo shared: true obligatoriamente para Windows
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, activePort, shared: true);
    
    // 3. Guardado estructurado y limpio en formato JSON para las terminales cliente
    final configDir = Directory('C:\\MiPos\\config');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    
    final configFile = File('${configDir.path}\\server_config.json');
    final configData = {
      'api_port': activePort,
      'db_port': dbPort,
      'host': dbHost,
      'updated_at': DateTime.now().toIso8601String(),
      'status': 'online'
    };

    const encoder = JsonEncoder.withIndent('  ');
    await configFile.writeAsString(encoder.convert(configData));

    print('API REST de Shelf corriendo con éxito en el puerto dinámico: $activePort');
    return activePort;
  }

  Future<Connection> _openConnection(String host, int port, String dbName, String user, String password) async {
    return await Connection.open(
      Endpoint(host: host, port: port, database: dbName, username: user, password: password),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}