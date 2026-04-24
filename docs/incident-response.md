Incident response dilakukan setelah alert muncul dari Wazuh.

Langkah analisis:

1. Identifikasi jenis serangan dari alert
2. Cek alamat IP attacker
3. Cek endpoint yang diserang
4. Cek payload request
5. Cek waktu kejadian

Response yang dilakukan:

1. Dokumentasi insiden
2. Identifikasi sumber serangan
3. Jika diperlukan, lakukan blocking IP
4. Berikan rekomendasi perbaikan:
   - validasi input
   - sanitasi input
   - gunakan prepared statement