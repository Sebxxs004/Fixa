import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inyectamos una cabecera de autorización Bearer ficticia para las pruebas iniciales.
    // En producción se consumirá el token real del usuario provisto por Firebase Auth.
    options.headers['Authorization'] = 'Bearer TOKEN_FICTICIO_DE_PRUEBA_JWT';
    
    // También inyectamos una cabecera de idempotencia por defecto para las mutaciones (POST, PUT, DELETE)
    if (options.method != 'GET') {
      options.headers['X-Idempotency-Key'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    super.onRequest(options, handler);
  }
}
