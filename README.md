# Buku Cuan - Pencatatan Keuangan UMKM Sederhana

Aplikasi mobile Flutter untuk pencatatan keuangan UMKM sederhana.

## Instalasi

### Prasyarat
- Flutter SDK >= 3.8.0
- Dart SDK >= 3.8.0
- Android Studio / VS Code
- Firebase project

### Install Dependencies
```bash
cd "D:\Projek Flutter\buku_cuan_app"
flutter pub get
```

### Konfigurasi Firebase
1. Buka Firebase Console (https://console.firebase.google.com)
2. Pilih project `buku-cuan-69d6f`
3. Tambahkan aplikasi Android dengan package name `com.example.buku_cuan_app`
4. Download `google-services.json` dan taruh di `android/app/`
5. Pastikan `build.gradle` Android sudah benar

### Jalankan Aplikasi
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

### Build IPA (iOS)
```bash
flutter build ios --release
```

## Struktur Project

```
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── theme/app_theme.dart
│   ├── utils/formatters.dart
│   └── services/
│       ├── firebase_service.dart
│       └── app_provider.dart
├── features/
│   ├── activation/
│   ├── dashboard/
│   ├── transactions/
│   ├── categories/
│   ├── debts/
│   ├── receivables/
│   ├── capital/
│   ├── reports/
│   ├── reminders/
│   └── settings/
└── shared/widgets/
```

## Fitur

- Aktivasi dengan Token Key
- Dashboard keuangan
- Pencatatan pemasukan & pengeluaran
- Kategori transaksi
- Hutang & Piutang
- Modal usaha
- Laporan dengan grafik
- Export PDF & Excel
- Reminder pembayaran
- Pengaturan usaha
- Offline support
