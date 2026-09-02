import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    return 'http://10.0.2.2:8080'; // 10.0.2.2 es el loopback de localhost en el emulador de Android
  }

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Registramos nuestro interceptor de autenticación
    dio.interceptors.add(AuthInterceptor());

    // Log interceptor silencioso ante offline
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: false,
    ));
  }
}

// Instancia global pre-configurada del cliente HTTP
final apiClient = ApiClient().dio;
