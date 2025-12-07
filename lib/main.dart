import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/upload_page.dart';

void main() {
  runApp(const AtelierApp());
}

class AtelierApp extends StatelessWidget {
  const AtelierApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF7C3AED); // ungu utama
    const bg = Color(0xFFF7F5F1); // ivory
    const fg = Color(0xFF0F0F0F); // charcoal

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Galeri Seni',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          secondary: const Color(0xFF9333EA),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: fg,
          elevation: 0.5,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            color: fg,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w600,
            color: fg,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            color: fg,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryPurple, width: 1.5),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/upload': (context) => const UploadPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class AtelierScaffold extends StatelessWidget {
  final Widget body;
  final String currentRoute;

  const AtelierScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = currentRoute == '/';
    final isUpload = currentRoute == '/upload';
    final isLogin = currentRoute == '/login';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black87, width: 1.5),
                ),
                child: const Text(
                  'Atelier',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavTextButton(
                    label: 'Galeri',
                    isActive: isHome,
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NavTextButton(
                    label: 'Upload',
                    isActive: isUpload,
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/upload',
                      (route) => false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Center(
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTextButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isActive ? colorScheme.primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}
