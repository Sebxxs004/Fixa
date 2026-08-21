import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;

  // Modifica esto según la URL de despliegue local o Cloud Run
  static const String _baseUrl = 'http://10.0.2.2:8080/api'; // 10.0.2.2 es localhost en el emulador de Android

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Registramos nuestro interceptor de autenticación
    dio.interceptors.add(AuthInterceptor());
    
    // Log interceptor opcional para depuración en desarrollo
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
}

// Instancia global pre-configurada del cliente HTTP
final apiClient = ApiClient().dio;
