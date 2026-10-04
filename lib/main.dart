import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_shell.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import 'package:data_konstruksi/services/mobile_navigation_provider.dart';
import 'package:data_konstruksi/services/auth_provider.dart';
import 'utils/responsive.dart';
import 'screens/mobile/mobile_main_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://sjkhwgmkkcnwoxbplbxz.supabase.co',
    anonKey: 'sb_publishable_4g_CZ-aNbtSvWcY-Qa2fBg_jzw-Gkji',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => MobileNavigationProvider()),
      ],
      child: const DataKonstruksiApp(),
    ),
  );
}

class DataKonstruksiApp extends StatelessWidget {
  const DataKonstruksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Konstruksi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          primary: const Color(0xFF007AFF),
          surface: const Color(0xFFF8F9FA),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }
          return const Responsive(
            mobile: MobileMainShell(),
            desktop: MainShell(),
          );
        },
      ),
    );
  }
}
