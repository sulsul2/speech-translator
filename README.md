# Speech Translator

A new Flutter project.

## Getting Started

### Prerequisites
Sebelum menjalankan proyek ini, pastikan Anda sudah menginstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (sudah termasuk dalam Flutter SDK)
- [Android Studio](https://developer.android.com/studio) atau [Visual Studio Code](https://code.visualstudio.com/)
- Emulator Android/iOS atau perangkat fisik yang sudah dikonfigurasi
- Paket tambahan sesuai dengan kebutuhan proyek

### Setup Flutter
1. **Periksa Instalasi Flutter**
   ```sh
   flutter doctor
   ```
   Pastikan semua dependensi telah terinstal dengan benar.

2. **Clone Repository (Jika Perlu)**
   ```sh
   git clone https://github.com/sulsul2/speech_translator.git
   cd speech_translator
   ```

3. **Install Dependencies**
   ```sh
   flutter pub get
   ```

### Menjalankan Aplikasi

#### 1. Menjalankan di Emulator atau Perangkat Fisik
- **Pastikan emulator atau perangkat terhubung**
  ```sh
  flutter devices
  ```
- **Jalankan aplikasi**
  ```sh
  flutter run
  ```

#### 2. Menjalankan di Web
Untuk menjalankan aplikasi Flutter di browser:
```sh
flutter run -d chrome
```

### Build APK/IPA
- **Membuat APK** (untuk Android):
  ```sh
  flutter build apk
  ```
- **Membuat App Bundle** (untuk Play Store):
  ```sh
  flutter build appbundle
  ```
- **Membuat IPA** (untuk iOS, memerlukan Xcode):
  ```sh
  flutter build ios
  ```

### Troubleshooting
Jika terjadi error saat menjalankan aplikasi, coba:
- Periksa dependensi dengan `flutter pub get`
- Periksa masalah konfigurasi dengan `flutter doctor`
- Jalankan ulang emulator atau perangkat fisik
- Jika menggunakan Android, pastikan USB Debugging aktif

Untuk informasi lebih lanjut, kunjungi [Flutter Documentation](https://docs.flutter.dev/).
