import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/category_tile.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Transaksi'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final incomeCategories =
              provider.categories.where((c) => c.isIncome).toList();
          final expenseCategories =
              provider.categories.where((c) => c.isExpense).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Row(
                children: [
                  Icon(Iconsax.money_recive, size: 18, color: AppColors.income),
                  SizedBox(width: 8),
                  Text(
                    'Kategori Pemasukan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...incomeCategories.map((cat) => CategoryTile(category: cat)),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Iconsax.money_send, size: 18, color: AppColors.expense),
                  SizedBox(width: 8),
                  Text(
                    'Kategori Pengeluaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...expenseCategories.map((cat) => CategoryTile(category: cat)),
            ],
          );
        },
      ),
    );
  }
}
