import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_notifier.dart';
import 'providers/data_notifier.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'themes/theme_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hospital App',
            theme: HospitalTheme.lightTheme,
            home: authProvider.isAuthenticated
                ? const HomeScreen()
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
