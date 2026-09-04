import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../activation/data/license_model.dart';
import '../../categories/models/category_model.dart';
import '../../reminders/screens/reminder_screen.dart';

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
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Iconsax.shop,
                    title: 'Nama Usaha',
                    subtitle: provider.userName ?? 'Belum diatur',
                    onTap: () => _editBusinessName(context, provider),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Iconsax.location,
                    title: 'Alamat',
                    subtitle: 'Atur alamat usaha',
                    onTap: () {},
                  ),
                  const Divider(),
                  _SettingsTile(
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
              _SettingsCard(
                children: [
                  _buildLicenseInfo(provider),
                ],
              ),
              const SizedBox(height: 16),

              // Other Settings
              const Text('Lainnya', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Iconsax.category,
                    title: 'Kategori Transaksi',
                    subtitle: 'Kelola kategori pemasukan & pengeluaran',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _CategoryManagementScreen(),
                      ),
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
                    icon: Iconsax.notification_bing,
                    title: 'Reminder',
                    subtitle: 'Kelola reminder pembayaran',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReminderScreen()),
                    ),
                  ),
                  const Divider(),
                  _SettingsTile(
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
          _InfoRow('Paket', license.packageType == PackageType.lifetime ? 'Lifetime' : '1 Bulan'),
          _InfoRow('Status', statusText),
          _InfoRow('Token', TokenUtils.maskToken(license.tokenKey)),
          _InfoRow('Tanggal Aktif', DateFormatter.formatDate(license.createdAt)),
          if (license.expiredAt != null)
            _InfoRow('Tanggal Berakhir', DateFormatter.formatDate(license.expiredAt!)),
          if (license.packageType == PackageType.lifetime)
            const _InfoRow('Tanggal Berakhir', 'Selamanya'),
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CategoryManagementScreen extends StatelessWidget {
  const _CategoryManagementScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Transaksi')),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final List<CategoryModel> incomeCategories = provider.categories.where((CategoryModel c) => c.isIncome).toList();
          final List<CategoryModel> expenseCategories = provider.categories.where((CategoryModel c) => c.isExpense).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Kategori Pemasukan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...incomeCategories.map((cat) => ListTile(
                    title: Text(cat.name, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 16),
              const Text('Kategori Pengeluaran', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...expenseCategories.map((cat) => ListTile(
                    title: Text(cat.name, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          );
        },
      ),
    );
  }
}
