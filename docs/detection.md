Detection dilakukan menggunakan Wazuh dengan rule berbasis pattern matching pada log web.

Rule yang digunakan:

1. SQL Injection
Keyword:
- UNION
- SELECT

Tujuan:
Mendeteksi query mencurigakan yang mencoba mengambil data dari database.

2. Cross Site Scripting (XSS)
Keyword:
- <script>
- encoded script (%3Cscript%3E)

Tujuan:
Mendeteksi input berbahaya yang mencoba menjalankan script di browser.

3. Suspicious File Access / Upload
Keyword:
- .php

Tujuan:
Mendeteksi kemungkinan upload atau akses file berbahaya.