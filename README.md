wget -q https://raw.githubusercontent.com/Smarasanta/Mass-Network-Audit/refs/heads/main/Files/audit.sh && wget -q https://raw.githubusercontent.com/Smarasanta/Mass-Network-Audit/refs/heads/main/Files/host.txt && chmod +x audit.sh


# 🌐 Mass Network Audit Tool v8.0

Mass Network Audit Tool adalah script Bash ringan dan super cepat yang dirancang untuk melakukan *scanning* (audit) massal pada daftar host/domain. Script ini sangat berguna untuk memfilter *bug host* aktif yang merespons HTTP 200 OK atau berhasil melakukan koneksi TLS Handshake

Hasil audit akan ditampilkan secara rapi di layar terminal dan dikirimkan secara otomatis dalam bentuk file `.txt` ke bot Telegram Anda! 🚀

## ✨ Fitur Utama
* **Multi-Threading:** Pemindaian sangat cepat karena berjalan secara bersamaan (*concurrent*).
* **Deteksi ISP & IP:** Otomatis mendeteksi operator jaringan dan IP publik yang sedang Anda gunakan.
* **Filter Otomatis:** Memisahkan host yang merespons `HTTP 200 OK` dan `TLS_OK` (Sertifikat SSL aktif).
* **Anti-Duplikat:** Otomatis menyaring domain yang ditulis ganda di dalam file `host.txt`.
* **Telegram Backup:** Mengirimkan hasil lengkap ke Telegram dalam bentuk file dokumen (tidak akan terkena limit karakter teks Telegram).
* **Tampilan Interaktif:** Dilengkapi dengan animasi *loading spinner* yang bersih di terminal.

---

## 🛠️ Persyaratan (Prerequisites)
Pastikan Anda sudah menginstal paket-paket dasar berikut di terminal (Termux):
