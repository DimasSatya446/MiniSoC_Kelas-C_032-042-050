Alur demo Mini SOC:

1. Menjalankan DVWA melalui Docker
2. Mengakses DVWA melalui browser
3. Melakukan serangan (SQL Injection atau XSS)
4. Serangan tercatat dalam log web server
5. Log dikirim ke Wazuh
6. Wazuh mendeteksi serangan berdasarkan rule
7. Alert muncul di dashboard
8. Alert dianalisis
9. Dilakukan response terhadap insiden