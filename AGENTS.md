# Aturan Tetap Pengembangan & Pembaruan Script VPS PremDigital

## 1. Prinsip Utama: Keamanan & Non-Destruktif (Zero Risk to Existing Services)
- **DILARANG MERUSAK ATAU MENGUBAH FILE LAIN**:
  - Dilarang menimpa atau merusak file database user atau konfigurasi akun yang sudah berjalan:
    - `/etc/xray/config.json`
    - `/etc/passwd`, `/etc/shadow`, `/etc/group` (akun SSH/WS)
    - `/etc/vps-domain.txt` (domain aktif pelanggan)
    - Sertifikat SSL `/etc/xray/xray.crt` & `/etc/xray/xray.key`
    - File konfigurasi token & service web connection.
- **SESI ROOT & PORT UTAMA**:
  - Akses SSH port 22/root tidak boleh disentuh, dibatasi, atau di-kill oleh script apa pun.

## 2. Pendekatan Modular & Penyesuaian Ringan (Surgical & In-Place)
- Saat menambah fitur baru (seperti Load Balancer, Limit IP, dsb.):
  - Buat file modul mandiri baru di `/vps-scripts/<nama-fitur>.sh` atau `/usr/local/bin/<nama-fitur>`.
  - Pada file menu utama (`/vps-scripts/menu.sh` atau `/usr/bin/menu`), lakukan penyesuaian (adjust) pada baris nomor opsi dan panggilan fungsi saja tanpa merombak struktur menu lainnya.
  - Jangan menghapus opsi atau sub-skrip yang sudah ada (`add-ssh.sh`, `add-vmess.sh`, `add-vless.sh`, `add-trojan.sh`, `list-account.sh`, dll).

## 3. Otomatisasi Backup Sebelum Modifikasi
- Setiap skrip yang melakukan perubahan pada konfigurasi sistem harus selalu menyertakan langkah cadangan (`cp file file.bak`) sebelum eksekusi.
