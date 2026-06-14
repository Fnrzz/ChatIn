**Dokumen Kebutuhan Produk (PRD)**

**Nama Produk:** ChatIn **Platform:** Android & iOS (Mobile App) **Status:** Revisi 2 (Updated)

**1\. Ringkasan Eksekutif**

ChatIn adalah aplikasi _mobile_ yang menyediakan layanan asisten AI interaktif. Aplikasi ini membedakan dirinya dengan menyediakan berbagai "Ruang Obrolan Spesialis" di mana agen AI telah dikonfigurasi dengan keahlian dan persona khusus, memungkinkan pengguna untuk berkonsultasi, belajar, atau sekadar bercerita dengan agen yang relevan dengan kebutuhan mereka. Ekosistem ini didukung oleh sebuah **Web Admin Dashboard (chatin-dashboard)** sebagai pusat kontrol untuk mengelola agen AI dan basis pengetahuan (_knowledge base_) spesifik menggunakan teknologi _Retrieval-Augmented Generation_ (RAG). Selain itu, terdapat **Landing Page (chatin-landingpage)** sebagai halaman marketing publik.

**2\. Tujuan Produk**

- Membangun aplikasi obrolan AI yang memiliki performa tinggi dan desain antarmuka yang seragam di perangkat Android maupun iOS.
- Menciptakan ekosistem berlangganan (SaaS) di mana pengguna mendapatkan nilai tambah dari kepakaran AI spesifik.
- Menyediakan sistem manajemen data yang aman dan terpusat untuk menjaga riwayat obrolan pengguna agar interaksi dengan AI terasa berkesinambungan.
- Menghadirkan halaman landing publik untuk akuisisi pengguna baru dan distribusi unduhan aplikasi.

**3\. Fitur Utama Produk**

**3.1. Autentikasi Pengguna (Login & Registrasi)** ✅ Implemented

- **Pendaftaran/Masuk Mulus:** Mendukung otentikasi melalui Email/Kata Sandi dan Google Sign-In via Supabase Auth.
- **Verifikasi OTP:** Verifikasi email menggunakan kode OTP (otp_verification_screen).
- **Manajemen Sesi:** Menjaga pengguna tetap masuk secara aman antar sesi menggunakan token otentikasi terenkripsi.
- **Keamanan Data:** Memastikan bahwa data setiap pengguna terisolasi dengan aman melalui Row Level Security (RLS).

**3.2. Sistem Langganan (Subscription)** 🔜 Phase 2

- **Skema Freemium:** Pengguna baru mendapatkan akses terbatas (misalnya, 5 pesan per hari ke AI asisten umum).
- **Tier Premium:** Akses tanpa batas ke semua ruang obrolan spesialis, respons yang lebih cepat, dan batas konteks ingatan obrolan yang lebih panjang.
- **Integrasi Pembayaran:** Menggunakan _Google Play Billing_ untuk Android dan _Apple In-App Purchases_ untuk iOS agar transaksi berjalan sesuai kebijakan _store_.

**3.3. Manajemen Riwayat Obrolan (Save Chat History)** ✅ Implemented

- **Cloud Sync:** Pesan disimpan ke PostgreSQL via Supabase, memastikan riwayat tetap sinkron.
- **Sesi Berkelanjutan:** Setiap ruang obrolan menyimpan memori percakapan sebelumnya. AI dapat mengingat detail spesifik berkat sistem auto-summarize.
- **Auto Title Generation:** Judul sesi chat di-generate otomatis oleh AI.
- **Conversation Summarization:** Konteks percakapan di-summarize secara berkala untuk efisiensi context window.
- **Privasi dan Kontrol:** Terdapat fungsi hapus sesi chat dan riwayat.
- **Enkripsi Chat:** Konten chat dienkripsi dengan AES-256 sebelum disimpan.

**3.4. Ruang Obrolan Spesialis (Karakter & Agen AI)** ✅ Implemented

- **Katalog Persona (Prompt Engineering):** Dashboard menampilkan pilihan agen dengan _system prompt_ khusus. Contoh:
  - **Psikolog/Konselor:** AI dengan instruksi untuk berempati, tidak menghakimi, mendengarkan secara aktif, dan memberikan teknik relaksasi dasar.
  - **Mentor UI/UX:** AI khusus untuk membantu _developer_ memahami prinsip desain, membedah studi kasus UI, atau membahas fase desain produk.
  - **Asisten Koding / Generalist:** AI untuk kebutuhan tanya jawab umum dan pemrograman.
- **Isolasi Konteks:** Setiap agen memiliki ruang obrolannya sendiri. Obrolan dengan AI Psikolog tidak akan pernah bocor atau tercampur dengan obrolan AI Mentor UI/UX.
- **RAG Integration:** Jawaban agen diperkaya dengan konteks dari Knowledge Base menggunakan pencarian semantik via pgvector.
- **Streaming Response:** Respons AI di-stream secara real-time melalui ReadableStream.

**3.5. Web Admin Dashboard (chatin-dashboard)** ✅ Implemented

- **Control Center & Manajemen Agen:** Antarmuka web berbasis Next.js 16 untuk menambah, mengedit, dan menghapus persona agen AI beserta instruksi (_system prompt_) mereka.
- **Manajemen Avatar:** Pengelolaan avatar untuk setiap agen AI.
- **Manajemen Knowledge Base (RAG):** Fasilitas untuk mengunggah dan memproses dokumen (PDF/Teks) sebagai basis pengetahuan. Termasuk chunking otomatis dan vector embedding melalui Sumopod API.
- **Chat Playground:** Interface untuk menguji interaksi dengan agen secara langsung dari dashboard.
- **API Endpoints:**
  - `POST /api/chat` — Chat utama (streaming + RAG context)
  - `POST /api/chat/generate-title` — Auto-generate judul sesi
  - `POST /api/chat/summarize` — Summarisasi percakapan
- **Akses Eksklusif (Admin-Only):** Dashboard bersifat eksklusif bagi Admin tanpa sistem RBAC kompleks.

**3.6. Landing Page (chatin-landingpage)** ✅ Implemented

- **Hero Section:** Full-screen hero dengan background image, headline, subtitle, dan CTA buttons.
- **App Mockup:** Menampilkan screenshot aplikasi mobile.
- **Store Badges:** Badge App Store & Google Play dengan rating.
- **Glassmorphism UI:** Desain modern dengan efek backdrop-blur dan glass-style components.
- **Responsive Design:** Layout yang menyesuaikan desktop & mobile.
- **Sections Planned:** Features, Pricing, About, Footer (dalam pengembangan).

**3.7. Fitur Tambahan** ✅ Implemented

- **Dark/Light Mode:** Tema otomatis mengikuti sistem atau manual, dengan persistensi via SharedPreferences.
- **Multi-Language:** Mendukung Bahasa Inggris & Bahasa Indonesia via easy_localization.
- **User Profile:** Halaman profil pengguna dan pengaturan aplikasi.

**4\. Spesifikasi Teknis & Arsitektur**

- **Mobile Framework: Flutter**
  - Menggunakan Flutter (Dart ^3.12) untuk membangun antarmuka pengguna yang _native-like_ di Android dan iOS menggunakan satu basis kode. Material 3 dengan seed color `#FFD500`.
- **Web Admin Dashboard: Next.js**
  - Next.js 16 dengan App Router, Tailwind CSS 4, shadcn/ui + Radix UI.
- **Landing Page: Next.js**
  - Next.js 16 dengan Tailwind CSS 4, Geist fonts, glassmorphism design.
- **Backend & Database: Supabase**
  - **Database:** PostgreSQL + ekstensi **pgvector** untuk vector embeddings.
  - **Autentikasi:** Supabase Auth (Email/Password, Google Sign-In, OTP).
  - **Keamanan:** Row Level Security (RLS) + AES-256 chat encryption.
- **Penyedia Layanan AI (LLM): Sumopod**
  - **API Proxy:** Flutter → Next.js API → Sumopod (API key di server only).
  - **Streaming:** ReadableStream untuk real-time token rendering.
  - **RAG:** Embedding + cosine similarity via pgvector `match_documents` RPC.

**5\. Alur Pengguna (User Flow)**

- **Discovery:** Pengguna mengunjungi landing page, melihat informasi produk dan mockup.
- **Onboarding:** Mengunduh ChatIn, mendaftar akun via Email atau Google Sign-In.
- **Verifikasi:** Verifikasi email menggunakan kode OTP.
- **Eksplorasi:** Home screen dan dashboard menampilkan daftar agen AI spesialis.
- **Konversi (Paywall):** Jika pengguna memilih agen Premium, muncul layar penawaran (Phase 2).
- **Berinteraksi:** Pesan dikirim melalui Chat API → Sumopod (dengan RAG context), balasan di-stream real-time.
- **Retensi & Sinkronisasi:** Pesan disimpan (terenkripsi) ke Supabase. Saat app dibuka ulang, obrolan dilanjutkan.

**6\. Kriteria Keberhasilan (Success Metrics)**

- **Kinerja Aplikasi:** Waktu muat awal < 2 detik, UI render 60fps.
- **Latensi AI:** Respons dari API Sumopod < 2 detik (end-to-end).
- **User Acquisition & Conversion:** Rasio pendaftaran dan konversi ke premium > 5%.
- **Retention Rate:** Day-3 > 40%, Day-7 > 25%.

_ChatIn PRD · Revisi 2 · Updated berdasarkan implementasi aktual_
