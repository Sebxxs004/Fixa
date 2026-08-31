import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSubscriptionRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final User? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role; // "CLIENTE" | "TRABAJADOR"

  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role; // "CLIENTE" | "TRABAJADOR"
  final String? category;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.category,
  });

  @override
  List<Object?> get props => [name, email, password, role, category];
}

class AuthLogoutRequested extends AuthEvent {}
