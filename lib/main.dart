import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/services/app_provider.dart';
import 'features/activation/screens/activation_screen.dart';
import 'features/dashboard/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';
  await FirebaseService.initialize();
  runApp(const BukuCuanApp());
}

class BukuCuanApp extends StatelessWidget {
  const BukuCuanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: 'Buku Cuan',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat Buku Cuan...'),
                ],
              ),
            ),
          );
        }

        // Check expired BEFORE !isActivated so expired users see the expired screen
        if (provider.isExpired) {
          return const _ExpiredScreen();
        }

        if (!provider.isActivated) {
          return const ActivationScreen();
        }

        return const MainScreen();
      },
    );
  }
}

class _ExpiredScreen extends StatelessWidget {
  const _ExpiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.timer_pause,
                    size: 40,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Masa Aktif Berakhir',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Token Buku Cuan Anda sudah tidak aktif. Silakan hubungi administrator untuk memperpanjang masa penggunaan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppProvider>().logout();
                    },
                    child: const Text('Masukkan Token Baru'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
