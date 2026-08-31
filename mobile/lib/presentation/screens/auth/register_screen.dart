import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/role_selector.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialRole;

  const RegisterScreen({
    super.key,
    this.initialRole,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _categoryController = TextEditingController();

  late UserRole _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == 'trabajador'
        ? UserRole.trabajador
        : UserRole.cliente;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final roleString =
          _selectedRole == UserRole.cliente ? 'CLIENTE' : 'TRABAJADOR';

      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              role: roleString,
              category: _selectedRole == UserRole.trabajador
                  ? _categoryController.text.trim()
                  : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                '¡Cuenta creada exitosamente! Bienvenido, ${state.user.displayName ?? state.user.email ?? ""}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
          context.go('/home');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Registro'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado
                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Únete a Fixa seleccionando el tipo de perfil',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Selector de Rol
                      RoleSelector(
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nombre Completo
                      CustomTextField(
                        controller: _nameController,
                        label: _selectedRole == UserRole.cliente
                            ? 'Nombre Completo'
                            : 'Nombre o Nombre Comercial',
                        hint: 'Juan Pérez',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Categoría/Especialidad (Sólo para trabajadores)
                      if (_selectedRole == UserRole.trabajador) ...[
                        CustomTextField(
                          controller: _categoryController,
                          label: 'Especialidad / Oficio',
                          hint: 'Ej. Plomería, Electricidad, Cerrajería',
                          prefixIcon: Icons.handyman_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor especifica tu especialidad';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Correo Electrónico
                      CustomTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        hint: 'ejemplo@correo.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: 'Mínimo 6 caracteres',
                        isPassword: _obscurePassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirmar Contraseña
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar Contraseña',
                        hint: 'Repite tu contraseña',
                        isPassword: _obscureConfirmPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Botón de Registro
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return ElevatedButton(
                            onPressed: isLoading ? null : _onRegisterPressed,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _selectedRole == UserRole.cliente
                                        ? 'Registrarme como Usuario'
                                        : 'Registrarme como Trabajador',
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Enlace a Login
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta?',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Inicia sesión'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
