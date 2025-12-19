Nama Aplikasi : ATELIER Tim : • Yunus Febrian -241712071 • Syaiful Anwar -241712072 • Daffa Indrasyah Dauly -241712077 • Alfi Syari Matondang -241712088 • Joseph Joel Sinaga -241712089

Deskripsi Aplikasi : Aplikasi yang kami buat adalah aplikasi pameran karya seni yang dapat mengungah gambar karya seni untuk dappat dipamerkan ke publik dan dapat di perjual belikan

Daftar Fitur pada aplikasi : -upload gambar -bid harga -ganti profil -saldo digital

Stack Technology yang digunakan : -Flutter version 3.38 -Android version 16 -Library / Framework yang digunakan PHP & Firebase -Public / Private API yang digunakan MYSQL & Firebase

Cara menjalankan aplikasi : Cara Menghubungkan Ponsel Anda (Langkah demi Langkah)

Aktifkan Mode Pengembang di Android Buka Pengaturan di ponsel Anda. Gulir ke bawah ke Tentang ponsel. Temukan Nomor build (mungkin di bawah "Informasi perangkat lunak"). Ketuk Nomor build 7 kali dengan cepat hingga Anda melihat "Anda sekarang adalah pengembang!".

Aktifkan Debugging USB Kembali ke Pengaturan utama. Buka Sistem > Opsi pengembang (atau cukup cari "Opsi pengembang" di pengaturan). Gulir ke bawah dan aktifkan debugging USB.

Hubungkan ke Komputer Hubungkan ponsel Anda ke komputer melalui kabel USB. Lihat layar ponsel Anda. Sebuah pop-up akan menanyakan "Izinkan debugging USB?". Centang "Selalu izinkan dari komputer ini" dan ketuk Izinkan.

Konfigurasi Jaringan (Selesai!) Saya telah secara otomatis mendeteksi alamat IP komputer Anda (192.168.100.7) dan memperbarui lib/config.dart untuk Anda.

Penting: Pastikan ponsel dan komputer Anda terhubung ke jaringan Wi-Fi yang sama.

Jalankan Aplikasi Di editor Anda (VS Code), buka Command Palette (Ctrl+Shift+P) dan ketik Flutter: Select Device.
Pilih ponsel Android Anda dari daftar. Tekan F5 (atau jalankan flutter run di terminal) untuk menginstal aplikasi di ponsel Anda. Pemecahan Masalah Aplikasi tidak dapat terhubung/login? Periksa apakah komputer Anda memiliki firewall. Anda mungkin perlu mengizinkan port 80 (atau port server web Anda) melalui firewall. Verifikasi IP Anda belum berubah. Jika berubah, jalankan ipconfig dan perbarui lib/config.dart . Ponsel tidak ditemukan? Coba kabel USB lain (beberapa hanya untuk pengisian daya). Verifikasi driver USB terinstal di Windows (sebagian besar otomatis, tetapi terkadang membutuhkan "Universal ADB Driver").
