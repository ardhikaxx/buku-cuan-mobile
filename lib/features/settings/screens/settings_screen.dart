import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../activation/data/license_model.dart';
import '../../categories/screens/category_screen.dart';
import '../../reminders/screens/reminder_screen.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              const Text('Profil Usaha', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SettingsCard(
                children: [
                  SettingsTile(
                    icon: Iconsax.shop,
                    title: 'Nama Usaha',
                    subtitle: provider.userName ?? 'Belum diatur',
                    onTap: () => _editBusinessName(context, provider),
                  ),
                  const Divider(),
                  SettingsTile(
                    icon: Iconsax.location,
                    title: 'Alamat',
                    subtitle: 'Atur alamat usaha',
                    onTap: () {},
                  ),
                  const Divider(),
                  SettingsTile(
                    icon: Iconsax.call,
                    title: 'Nomor WhatsApp',
                    subtitle: 'Atur nomor WhatsApp',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // License Section
              const Text('Status Lisensi', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SettingsCard(
                children: [
                  _buildLicenseInfo(provider),
                ],
              ),
              const SizedBox(height: 16),

              // Other Settings
              const Text('Lainnya', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SettingsCard(
                children: [
                  SettingsTile(
                    icon: Iconsax.category,
                    title: 'Kategori Transaksi',
                    subtitle: 'Kelola kategori pemasukan & pengeluaran',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryScreen(),
                      ),
                    ),
                  ),
                  const Divider(),
                  SettingsTile(
                    icon: Iconsax.notification_bing,
                    title: 'Reminder',
                    subtitle: 'Kelola reminder pembayaran',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReminderScreen()),
                    ),
                  ),
                  const Divider(),
                  SettingsTile(
                    icon: Iconsax.info_circle,
                    title: 'Tentang Buku Cuan',
                    subtitle: 'Versi 1.0.0',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _logout(context, provider),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Keluar & Masukkan Token Baru'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLicenseInfo(AppProvider provider) {
    final license = provider.license;
    if (license == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Informasi lisensi tidak tersedia'),
      );
    }

    final statusText = license.isActive
        ? 'Aktif'
        : license.status == LicenseStatus.expired
            ? 'Expired'
            : 'Nonaktif';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InfoRow('Paket', license.packageType == PackageType.lifetime ? 'Lifetime' : '1 Bulan'),
          InfoRow('Status', statusText),
          InfoRow('Token', TokenUtils.maskToken(license.tokenKey)),
          InfoRow('Tanggal Aktif', DateFormatter.formatDate(license.createdAt)),
          if (license.expiredAt != null)
            InfoRow('Tanggal Berakhir', DateFormatter.formatDate(license.expiredAt!)),
          if (license.packageType == PackageType.lifetime)
            const InfoRow('Tanggal Berakhir', 'Selamanya'),
        ],
      ),
    );
  }

  void _editBusinessName(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(text: provider.userName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nama Usaha'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan nama usaha'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await StorageService.saveUserName(name);
                provider.setUserName(name);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Buku Cuan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buku Cuan v1.0.0'),
            SizedBox(height: 8),
            Text('Pencatatan Keuangan UMKM Sederhana'),
            SizedBox(height: 16),
            Text(
              'Buku Cuan membantu pemilik UMKM, usaha kecil, jasa, dan freelancer mencatat serta memantau keuangan usaha dengan sangat sederhana.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _logout(BuildContext context, AppProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar? Anda perlu memasukkan token lagi untuk menggunakan aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.logout();
    }
  }
}
