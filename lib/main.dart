import 'package:flutter/material.dart';
import 'bottom_nav_bar/nav_bar.dart';
import 'core/data/local/auth_local_data_source.dart';
import 'core/data/local/local_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/view/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  runApp(const RebsHrmsApp());
}

class RebsHrmsApp extends StatelessWidget {
  const RebsHrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REBS HRMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Tapping anywhere outside a text field hides the keyboard, on every
      // route — wrapping the Navigator here covers pushed screens and dialogs.
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: child,
      ),
      home: AuthLocalDataSource().isLoggedIn
          ? const NavBar()
          : const LoginScreen(),
    );
  }
}
