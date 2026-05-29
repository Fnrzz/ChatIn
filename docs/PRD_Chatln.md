**Dokumen Kebutuhan Produk (PRD)**

**Nama Produk:** ChatIn **Platform:** Android & iOS (Mobile App) **Status:** Draf Revisi 1

**1\. Ringkasan Eksekutif**

ChatIn adalah aplikasi _mobile_ yang menyediakan layanan asisten AI interaktif. Aplikasi ini membedakan dirinya dengan menyediakan berbagai "Ruang Obrolan Spesialis" di mana agen AI telah dikonfigurasi dengan keahlian dan persona khusus, memungkinkan pengguna untuk berkonsultasi, belajar, atau sekadar bercerita dengan agen yang relevan dengan kebutuhan mereka. Ekosistem ini didukung oleh sebuah **Web Admin Dashboard (chatin-dashboard)** sebagai pusat kontrol untuk mengelola agen AI dan basis pengetahuan (_knowledge base_) spesifik menggunakan teknologi _Retrieval-Augmented Generation_ (RAG).

**2\. Tujuan Produk**

- Membangun aplikasi obrolan AI yang memiliki performa tinggi dan desain antarmuka yang seragam di perangkat Android maupun iOS.
- Menciptakan ekosistem berlangganan (SaaS) di mana pengguna mendapatkan nilai tambah dari kepakaran AI spesifik.
- Menyediakan sistem manajemen data yang aman dan terpusat untuk menjaga riwayat obrolan pengguna agar interaksi dengan AI terasa berkesinambungan.

**3\. Fitur Utama Produk**

**3.1. Autentikasi Pengguna (Login & Registrasi)**

- **Pendaftaran/Masuk Mulus:** Mendukung otentikasi melalui Email/Kata Sandi, Google Sign-In, dan Apple ID.
- **Manajemen Sesi:** Menjaga pengguna tetap masuk secara aman antar sesi menggunakan token otentikasi terenkripsi.
- **Keamanan Data:** Memastikan bahwa data setiap pengguna terisolasi dengan aman.

**3.2. Sistem Langganan (Subscription)**

- **Skema Freemium:** Pengguna baru mendapatkan akses terbatas (misalnya, 5 pesan per hari ke AI asisten umum).
- **Tier Premium:** Akses tanpa batas ke semua ruang obrolan spesialis, respons yang lebih cepat, dan batas konteks ingatan obrolan yang lebih panjang.
- **Integrasi Pembayaran:** Menggunakan _Google Play Billing_ untuk Android dan _Apple In-App Purchases_ untuk iOS agar transaksi berjalan sesuai kebijakan _store_.

**3.3. Manajemen Riwayat Obrolan (Save Chat History)**

- **Sinkronisasi Cloud Real-time:** Semua pesan dikirim dan ditarik secara _real-time_ ke _database cloud_, memastikan riwayat tetap sinkron meskipun pengguna berganti perangkat.
- **Sesi Berkelanjutan:** Setiap ruang obrolan menyimpan memori percakapan sebelumnya. AI dapat mengingat detail spesifik yang didiskusikan pada sesi sebelumnya.
- **Privasi dan Kontrol:** Terdapat fitur pencarian riwayat obrolan serta fungsi _Clear History_ bagi pengguna yang ingin mereset konteks ingatan AI di ruang tertentu.

**3.4. Ruang Obrolan Spesialis (Karakter & Agen AI)**

- **Katalog Persona (Prompt Engineering):** _Dashboard_ menampilkan pilihan agen dengan _system prompt_ khusus. Contoh:
  - **Psikolog/Konselor:** AI dengan instruksi untuk berempati, tidak menghakimi, mendengarkan secara aktif, dan memberikan teknik relaksasi dasar.
  - **Mentor UI/UX:** AI khusus untuk membantu _developer_ memahami prinsip desain, membedah studi kasus UI, atau membahas fase desain produk.
  - **Asisten Koding / Generalist:** AI untuk kebutuhan tanya jawab umum dan pemrograman.
- **Isolasi Konteks:** Setiap agen memiliki ruang obrolannya sendiri. Obrolan dengan AI Psikolog tidak akan pernah bocor atau tercampur dengan obrolan AI Mentor UI/UX.

**3.5. Web Admin Dashboard (chatin-dashboard)**

- **Control Center & Manajemen Agen:** Antarmuka web berbasis Next.js untuk menambah, mengedit, dan menghapus persona agen AI beserta instruksi (_system prompt_) mereka.
- **Manajemen Knowledge Base (RAG):** Fasilitas untuk mengunggah dan memproses dokumen sebagai basis pengetahuan spesifik untuk masing-masing agen menggunakan sistem _Retrieval-Augmented Generation_ (RAG).
- **Akses Eksklusif (Admin-Only):** _Dashboard_ ini tidak menggunakan sistem RBAC yang kompleks. Sebagai bentuk fokus pada MVP, sistem ini bersifat eksklusif bagi Admin untuk secara langsung mengelola seluruh aspek agen AI, mengubah _system prompt_, dan menjalankan proses _upload_ dokumen (RAG).

**4\. Spesifikasi Teknis & Arsitektur**

- **Mobile Framework: Flutter**
  - Menggunakan Flutter (berbasis bahasa Dart) untuk membangun antarmuka pengguna yang _native-like_ di Android dan iOS menggunakan satu basis kode (_single codebase_). Ini akan mempercepat siklus rilis dan memastikan konsistensi UI.
- **Web Admin Dashboard: Next.js**
  - Aplikasi web dibangun menggunakan framework Next.js. Dashboard ini akan terkoneksi ke instans Supabase yang sama dengan aplikasi mobile, berfungsi sebagai backend manajemen dan Control Center.
- **Backend & Database: Supabase**
  - **Database:** Menggunakan PostgreSQL bawaan Supabase untuk menyimpan skema data yang kuat (Tabel Pengguna, Tabel Ruang Obrolan, Tabel Pesan). Dilengkapi dengan ekstensi **pgvector** untuk menyimpan _embedding_ vektor dokumen (RAG).
  - **Autentikasi:** Menggunakan _Supabase Auth_ untuk mengelola pendaftaran, login _social_, dan keamanan sesi pengguna.
  - **Keamanan (Row Level Security - RLS):** Mengaktifkan kebijakan RLS agar pengguna hanya dapat membaca dan menulis riwayat obrolannya sendiri, memastikan privasi tingkat tinggi.
- **Penyedia Layanan AI (LLM): Sumopod**
  - **Integrasi API:** Aplikasi (atau _Edge Functions_ di Supabase) akan berkomunikasi langsung dengan API dari _provider_ Sumopod.
  - **Pengaturan Model:** API Sumopod akan dikonfigurasi untuk menerima _system prompt_ yang berbeda-beda tergantung pada "Ruang Chat" yang diakses oleh pengguna.
  - **Manajemen Konteks:** Aplikasi akan mengirimkan serangkaian riwayat pesan sebelumnya bersama pesan baru ke API Sumopod untuk menjaga kelangsungan percakapan.

**5\. Alur Pengguna (User Flow)**

- **Onboarding:** Pengguna mengunduh ChatIn, mendaftar akun menggunakan integrasi _Supabase Auth_, dan melihat layar perkenalan.
- **Eksplorasi:** Layar utama (_Home Screen_) yang dibangun dengan _widget_ Flutter menampilkan grid/daftar "Ruang Spesialis".
- **Konversi (Paywall):** Jika pengguna memilih agen spesialis berlabel Premium, muncul layar penawaran (_paywall_) yang terhubung dengan _in-app purchase_.
- **Berinteraksi:** Setelah masuk ke ruang chat, pengguna mengetik pesan. Pesan dikirim melalui API Sumopod, dan balasannya langsung di-render di UI obrolan.
- **Retensi & Sinkronisasi:** Pesan disimpan ke _database_ Supabase. Saat aplikasi ditutup dan dibuka lagi, Flutter me-_load_ kembali obrolan tersebut sehingga pengguna bisa langsung melanjutkan percakapan.

**6\. Kriteria Keberhasilan (Success Metrics)**

- **Kinerja Aplikasi:** Waktu muat awal aplikasi (_app load time_) dan kecepatan _render_ UI yang mulus (target 60fps dengan Flutter).
- **Latensi AI:** Waktu respons dari API Sumopod sejak pesan dikirim hingga balasan diterima pengguna (idealnya di bawah 2 detik).
- **User Acquisition & Conversion:** Rasio pengguna baru yang mendaftar dan persentase yang beralih ke paket langganan berbayar.
- **Retention Rate:** Persentase pengguna yang kembali membuka aplikasi dan melanjutkan percakapan di ruang spesialis pada hari ke-3 dan ke-7.
