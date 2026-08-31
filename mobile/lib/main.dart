import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FixaApp());
}

class FixaApp extends StatelessWidget {
  const FixaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(AuthSubscriptionRequested()),
      child: MaterialApp.router(
        title: 'Fixa',
        theme: AppTheme.lightTheme,
        routerConfig: goRouter,
      ),
    );
  }
}
