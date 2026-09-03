class AppConstants {
  static const String appName = 'Buku Cuan';
  static const String appTagline = 'Pencatatan Keuangan UMKM Sederhana';
  static const String adminPin = '4444';

  static const String defaultCurrency = 'Rp';

  static const List<String> defaultIncomeCategories = [
    'Penjualan',
    'Jasa',
    'Pelunasan Piutang',
    'Modal',
    'Pendapatan Lainnya',
  ];

  static const List<String> defaultExpenseCategories = [
    'Bahan Baku',
    'Operasional',
    'Transportasi',
    'Listrik',
    'Internet',
    'Gaji',
    'Sewa',
    'Marketing',
    'Peralatan',
    'Pengeluaran Lainnya',
  ];

  static const List<String> paymentMethods = [
    'Tunai',
    'Transfer Bank',
    'E-Wallet',
    'QRIS',
    'Kartu Kredit',
    'Lainnya',
  ];

  static const List<String> debtStatuses = [
    'belum_lunas',
    'sebagian',
    'lunas',
  ];

  static const List<String> capitalTypes = [
    'initial',
    'additional',
    'withdrawal',
  ];

  static const Map<String, String> capitalTypeLabels = {
    'initial': 'Modal Awal',
    'additional': 'Tambahan Modal',
    'withdrawal': 'Penarikan Modal',
  };
}
