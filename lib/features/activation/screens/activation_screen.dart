import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isActivating = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isActivating = true);

    final token = _tokenController.text.trim().toUpperCase();
    final provider = context.read<AppProvider>();
    final success = await provider.activateWithToken(token);

    setState(() => _isActivating = false);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak valid atau sudah tidak aktif'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showNoTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Belum Memiliki Token?'),
        content: const Text(
          'Untuk menggunakan Buku Cuan, Anda perlu melakukan pembelian terlebih dahulu kepada administrator.\n\n'
          'Hubungi admin untuk mendapatkan Token Key Buku Cuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Iconsax.wallet_3,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aktifkan Buku Cuan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan Token Key yang Anda terima\nsetelah melakukan pembelian.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _tokenController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'BCN-XXXX-XXXX-XXXX',
                      hintStyle: TextStyle(
                        letterSpacing: 3,
                        color: AppColors.textHint,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Masukkan token key';
                      }
                      if (value.trim().length < 10) {
                        return 'Token key terlalu pendek';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isActivating ? null : _activate,
                      child: _isActivating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Aktifkan Buku Cuan'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showNoTokenDialog,
                    child: const Text(
                      'Belum memiliki token?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
