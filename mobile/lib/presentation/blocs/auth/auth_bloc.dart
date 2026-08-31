import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth? _injectedFirebaseAuth;
  StreamSubscription<User?>? _userSubscription;

  FirebaseAuth get _firebaseAuth =>
      _injectedFirebaseAuth ?? FirebaseAuth.instance;

  AuthBloc({FirebaseAuth? firebaseAuth})
      : _injectedFirebaseAuth = firebaseAuth,
        super(AuthInitial()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthLoading());
    _userSubscription?.cancel();
    try {
      _userSubscription = _firebaseAuth.authStateChanges().listen(
        (user) => add(AuthUserChanged(user)),
      );
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      if (credential.user != null) {
        emit(AuthAuthenticated(credential.user!));
      } else {
        emit(const AuthFailure('No fue posible autenticar al usuario'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseAuthError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(event.name.trim());
        emit(AuthAuthenticated(credential.user!));
      } else {
        emit(const AuthFailure('No fue posible crear la cuenta'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseAuthError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _firebaseAuth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ningún usuario registrado con este correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Contraseña o credenciales incorrectas.';
      case 'email-already-in-use':
        return 'El correo electrónico ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      default:
        return e.message ?? 'Ocurrió un error inesperado durante la autenticación.';
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
