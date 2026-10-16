import 'dart:io';
import 'package:flutter/foundation.dart';

class ErrorLogger {
  /// Registra un error global mapeado por el proceso, guardándolo en ProgramData.
  static Future<void> logError(String processName, dynamic error, [StackTrace? stackTrace]) async {
    try {
      // Usar la carpeta pública del sistema (C:\ProgramData) para evitar bloqueos de permisos en Archivos de Programa
      final String programData = Platform.environment['PROGRAMDATA'] ?? 'C:\\ProgramData';
      final Directory logsDir = Directory('$programData/MiPosCore/logs');
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final File logFile = File('${logsDir.path}/pos_error_log.txt');
      final timestamp = DateTime.now().toIso8601String();
      
      final String logEntry = '''
--------------------------------------------------
[FECHA/HORA]: $timestamp
[PROCESO]: $processName
[ERROR]: $error
[STACKTRACE]:
${stackTrace ?? 'No disponible'}
--------------------------------------------------
''';
      
      await logFile.writeAsString(logEntry, mode: FileMode.append);
      
      if (kDebugMode) {
        print('LOG REGISTRADO -> Proceso: $processName | Error: $error');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error crítico al intentar escribir en el sistema de logs: $e');
      }
    }
  }

  /// Método para leer los logs existentes
  static Future<String> readLogs() async {
    try {
      final String programData = Platform.environment['PROGRAMDATA'] ?? 'C:\\ProgramData';
      final File logFile = File('$programData/MiPosCore/logs/pos_error_log.txt');
      
      if (await logFile.exists()) {
        return await logFile.readAsString();
      }
      return 'No hay registros de errores guardados.';
    } catch (e) {
      return 'Error al leer el archivo de logs: $e';
    }
  }
}