import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  final FirebaseAuth? _firebaseAuth;

  AuthInterceptor({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final auth = _firebaseAuth ?? FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user != null) {
        // Solicitamos de forma asíncrona el Token JWT actual a Firebase
        final token = await user.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      // En caso de error, el interceptor continúa para no bloquear la petición
      // Se utiliza developer.log para evitar advertencias de print en producción
      // import 'dart:developer' as developer;
    }

    // Inyectamos cabecera de idempotencia por defecto para las mutaciones (POST, PUT, DELETE)
    if (options.method != 'GET') {
      options.headers['X-Idempotency-Key'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    handler.next(options);
  }
}
