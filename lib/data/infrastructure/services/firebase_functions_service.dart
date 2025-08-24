import 'package:cloud_functions/cloud_functions.dart';

class FirebaseFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Llamar a una función de Cloud Functions
  Future<dynamic> callFunction(String functionName, {Map<String, dynamic>? parameters}) async {
    try {
      final result = await _functions.httpsCallable(functionName).call(parameters);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      print('Error llamando a función $functionName: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Ejemplo: Función para procesar un nuevo relato
  Future<Map<String, dynamic>> processNewStory(Map<String, dynamic> storyData) async {
    try {
      final result = await callFunction(
        'processNewStory',
        parameters: storyData,
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error procesando nuevo relato: $e');
      rethrow;
    }
  }

  // Ejemplo: Función para moderar contenido
  Future<bool> moderateContent(String contentId, String contentType) async {
    try {
      final result = await callFunction(
        'moderateContent',
        parameters: {
          'contentId': contentId,
          'contentType': contentType,
        },
      );
      return result['isApproved'] ?? false;
    } catch (e) {
      print('Error moderando contenido: $e');
      rethrow;
    }
  }

  // Ejemplo: Función para generar resumen de actividad
  Future<Map<String, dynamic>> generateActivitySummary(String userId) async {
    try {
      final result = await callFunction(
        'generateActivitySummary',
        parameters: {'userId': userId},
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error generando resumen de actividad: $e');
      rethrow;
    }
  }

  // Ejemplo: Función para procesar notificaciones masivas
  Future<void> sendBulkNotifications(List<String> userIds, String message) async {
    try {
      await callFunction(
        'sendBulkNotifications',
        parameters: {
          'userIds': userIds,
          'message': message,
        },
      );
    } catch (e) {
      print('Error enviando notificaciones masivas: $e');
      rethrow;
    }
  }

  // Ejemplo: Función para actualizar estadísticas
  Future<Map<String, dynamic>> updateStatistics(String type) async {
    try {
      final result = await callFunction(
        'updateStatistics',
        parameters: {'type': type},
      );
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error actualizando estadísticas: $e');
      rethrow;
    }
  }
}
