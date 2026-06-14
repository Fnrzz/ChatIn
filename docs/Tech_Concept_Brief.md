**ChatIn**

Tech Concept Brief

_Platform Mobile AI - Android & iOS_

Versi Dokumen: 1.1 · Status: Updated

Berdasarkan PRD Revisi 1 + Implementasi Aktual

# **1\. Gambaran Produk**

ChatIn adalah aplikasi mobile berbasis AI yang menyediakan ekosistem "Ruang Obrolan Spesialis" - di mana setiap ruang dihuni oleh agen AI dengan persona, keahlian, dan instruksi (system prompt) yang berbeda-beda. Pengguna dapat berinteraksi dengan AI layaknya berkonsultasi dengan seorang spesialis: psikolog, mentor desain, atau asisten koding. 

Sebagai pendukung di balik layar, terdapat **Web Admin Dashboard** (chatin-dashboard) yang bertindak sebagai Control Center. Melalui dashboard ini, admin dan tim pengelola dapat mengatur agen AI serta memperkaya pengetahuan agen tersebut dengan menyuntikkan dokumen _knowledge base_ spesifik melalui sistem _Retrieval-Augmented Generation_ (RAG).

Selain itu, terdapat **Landing Page** (chatin-landingpage) sebagai halaman marketing publik yang menampilkan informasi produk, mockup aplikasi, dan tombol download untuk App Store & Google Play.

Produk ini dibangun di atas model bisnis freemium berbasis langganan (SaaS), dengan akses tak terbatas ke semua agen spesialis sebagai nilai utama paket premium.

## **Proposisi Nilai Utama**

- Konteks terisolasi per-agen: obrolan dengan Psikolog AI tidak pernah tercampur dengan sesi Mentor UI/UX.
- Memori percakapan lintas sesi: AI mengingat detail diskusi sebelumnya berkat sinkronisasi cloud realtime.
- UI native-like di Android & iOS dari satu codebase Flutter.
- Proses onboarding dan pembayaran in-app yang mulus sesuai kebijakan masing-masing store.
- Enkripsi AES-256 untuk keamanan konten chat.
- Dukungan multi-bahasa (Bahasa Inggris & Bahasa Indonesia).

# **2\. Arsitektur Teknis**

Sistem ChatIn dibangun dengan pendekatan three-tier: mobile client (Flutter), backend-as-a-service (Supabase), dan integrasi LLM (Sumopod). Setiap lapisan memiliki tanggung jawab yang terdefinisi jelas untuk memaksimalkan keamanan, skalabilitas, dan kecepatan pengembangan.

## **2.1 Diagram Arsitektur (Konseptual)**

```text
┌──────────────────────┐     ┌──────────────────────────────────────────┐
│                      │     │           Supabase (BaaS)                │
│   Flutter App        │◄───►│  ┌──────────┐ ┌────────┐ ┌───────────┐  │
│   (Android & iOS)    │     │  │  Auth     │ │Postgres│ │ pgvector  │  │
│                      │     │  │(Google,   │ │   DB   │ │ (RAG)     │  │
└───────┬──────────────┘     │  │ Email)    │ └────────┘ └───────────┘  │
        │                    └──────────┬───────────────────────────────┘
        │ (Chat API)                    │
        ▼                               │
┌──────────────────────┐                │
│   Next.js Dashboard  │◄───────────────┘
│   (Admin Panel)      │◄──────────────────► Sumopod API (LLM & Embedding)
│   • Agent Management │
│   • Knowledge Base   │
│   • RAG Pipeline     │
│   • Chat Playground  │
│   • Auto Summarize   │
└──────────────────────┘

┌──────────────────────┐
│   Next.js Landing    │  ← Public-facing marketing site
│   Page               │
│   • Hero & CTA       │
│   • App Download     │
└──────────────────────┘
```

## **2.2 Stack Teknologi**

| **Layer**         | **Teknologi**                    | **Justifikasi**                                                   |
| ----------------- | -------------------------------- | ----------------------------------------------------------------- |
| Mobile Framework  | Flutter (Dart ^3.12)             | Single codebase untuk Android & iOS, native-like UI, 60fps        |
| Web Dashboard     | Next.js 16 + Tailwind CSS 4     | Framework React modern, App Router, server components             |
| Landing Page      | Next.js 16 + Tailwind CSS 4     | Halaman marketing publik, SSR untuk SEO                           |
| Backend & Auth    | Supabase                        | PostgreSQL + Auth + RLS bawaan, mudah di-scale, realtime support  |
| Database & Vector | PostgreSQL + pgvector (Supabase) | Relasional terstruktur dan pencarian semantik (RAG) untuk AI      |
| AI / LLM Provider | Sumopod API                     | Dikonfigurasi per-ruang obrolan (LLM) dan menghasilkan embeddings |
| UI Components     | shadcn/ui + Radix UI            | Component library untuk Dashboard                                 |
| Encryption        | encrypt (AES-256)               | Enkripsi konten chat di sisi client                               |
| Localization      | easy_localization               | Dukungan multi-bahasa (EN, ID)                                    |
| In-App Purchase   | Google Play Billing + Apple IAP  | Wajib untuk distribusi di Play Store dan App Store                |
| Cloud Sync        | Supabase Realtime               | WebSocket-based, sinkronisasi histori obrolan lintas perangkat    |

## **2.3 Keamanan Data**

Keamanan data menjadi prioritas utama, terutama mengingat sensitivitas konten obrolan pengguna (termasuk konsultasi psikologis).

- **RLS Supabase:** Row Level Security (RLS) di PostgreSQL memastikan setiap query secara otomatis terfilter berdasarkan user_id yang terautentikasi.
- **Manajemen Sesi:** Token sesi dienkripsi dan dikelola sepenuhnya oleh Supabase Auth, mendukung social login (Google, Apple).
- **Isolasi Konteks:** Setiap Ruang Obrolan memiliki konteks terisolasi di level database, bukan hanya di level UI.
- **Enkripsi Chat:** Konten chat dienkripsi menggunakan AES-256 di sisi client sebelum dikirim dan disimpan. Key enkripsi dikelola melalui environment variables.
- **API Proxy:** Seluruh panggilan ke LLM dirutekan melalui Next.js API sebagai proxy aman. API key Sumopod hanya ada di server environment.
- **Dual Authentication:** API endpoint mendukung dua metode autentikasi — API Key (untuk Flutter) dan Session Auth (untuk Dashboard).
- **Enkripsi Transit:** Seluruh komunikasi menggunakan HTTPS/TLS.

# **3\. Breakdown Fitur**

## **3.1 Autentikasi Pengguna**

- **Metode Login:** Email & Password, Google Sign-In — semuanya melalui Supabase Auth.
- **Verifikasi OTP:** Email verification menggunakan kode OTP.
- **Manajemen Sesi:** Token sesi terenkripsi yang persisten antar session (tidak perlu login ulang).
- **Onboarding:** Pengguna baru mendapatkan welcome screen (home_screen).

## **3.2 Sistem Langganan (Freemium)**

- **Tier Gratis:** Akses terbatas: 5 pesan per hari ke agen umum. Cukup untuk memvalidasi produk sebelum konversi.
- **Tier Premium:** Akses tak terbatas ke semua Ruang Spesialis, prioritas respons, konteks ingatan lebih panjang.
- **Mekanisme Pembayaran:** Google Play Billing (Android) dan Apple In-App Purchases (iOS) — sesuai kebijakan distribusi resmi.
- **Paywall Trigger:** Paywall ditampilkan saat pengguna mencoba mengakses agen berlabel Premium.
- **Status:** 🔜 Belum diimplementasikan (roadmap Phase 2).

## **3.3 Manajemen Riwayat Obrolan**

- **Cloud Sync:** Pesan disimpan ke PostgreSQL via Supabase.
- **Sesi Berkelanjutan:** Saat aplikasi dibuka kembali, Flutter me-load riwayat dari DB sehingga percakapan langsung dapat dilanjutkan.
- **Auto Title Generation:** Judul sesi chat di-generate otomatis oleh AI berdasarkan konteks percakapan.
- **Conversation Summarization:** Konteks percakapan di-summarize untuk menjaga efisiensi context window.
- **Privasi & Kontrol:** Pengguna dapat menghapus sesi chat dan mereset konteks AI.

## **3.4 Ruang Obrolan Spesialis**

- **Konfigurasi Persona:** Setiap agen dikonfigurasi dengan system prompt unik yang dikirim bersama setiap request ke Sumopod API.
  - Psikolog/Konselor AI (empati, tidak menghakimi, teknik relaksasi dasar).
  - Mentor UI/UX (prinsip desain, studi kasus, fase product design).
  - Asisten Koding & Generalist (debugging, tanya jawab umum, pemrograman).
- **RAG Integration:** Jawaban agen diperkaya dengan konteks dari Knowledge Base menggunakan pencarian semantik (cosine similarity via pgvector).
- **Manajemen Konteks:** Konteks percakapan sebelumnya + summary dikirim bersamaan dengan pesan baru ke API.
- **Streaming Response:** Respons AI di-stream secara real-time (word-by-word rendering).

## **3.5 Web Admin Dashboard (Admin-Only)**

- **Control Center:** Aplikasi web Next.js untuk memonitor, menambah, mengedit, dan menghapus agen AI.
- **Akses Eksklusif Admin:** Dashboard ini tidak menggunakan sistem RBAC yang kompleks. Akses eksklusif untuk Admin.
- **Manajemen RAG:** UI terintegrasi untuk mengunggah file (PDF/Teks), chunking otomatis, embedding via Sumopod API, dan penyimpanan ke pgvector.
- **Chat Playground:** Interface untuk menguji agen secara langsung dari dashboard.
- **Agent Avatar Management:** Pengelolaan avatar untuk setiap agen AI.

## **3.6 Landing Page (Public)**

- **Hero Section:** Full-screen hero dengan background image, headline, dan CTA.
- **App Mockup:** Menampilkan screenshot aplikasi mobile.
- **Store Badges:** Link download ke App Store dan Google Play dengan rating.
- **Glassmorphism UI:** Desain modern dengan efek backdrop-blur.
- **Responsive:** Layout yang menyesuaikan desktop & mobile.

# **4\. Alur Pengguna (User Flow)**

| **Tahap**          | **Aktivitas Pengguna**                    | **Komponen Teknis Terlibat**                     |
| ------------------ | ----------------------------------------- | ------------------------------------------------ |
| **1\. Discovery**  | Mengunjungi landing page                  | Next.js Landing Page                             |
| **2\. Onboarding** | Download app, daftar akun                 | Supabase Auth (email/Google)                     |
| **3\. Verifikasi** | Verifikasi email via OTP                  | Supabase Auth + OTP Verification Screen          |
| **4\. Eksplorasi** | Lihat daftar agen spesialis               | Flutter (agents_screen, dashboard_screen)        |
| **5\. Konversi**   | Pilih agen Premium → muncul Paywall       | Flutter + Google Play Billing / Apple IAP        |
| **6\. Interaksi**  | Kirim pesan, terima balasan AI streaming  | Next.js API + Sumopod API + RAG                  |
| **7\. Retensi**    | Buka ulang app, lanjutkan obrolan         | Supabase + PostgreSQL (load history)             |

# **5\. Skema Database (Konseptual)**

Database PostgreSQL di Supabase terdiri dari tiga entitas utama yang saling berelasi:

| **Tabel**      | **Kolom Utama**                        | **Keterangan**                                                                       |
| -------------- | -------------------------------------- | ------------------------------------------------------------------------------------ |
| **users**      | id, email, plan_type, created_at       | Dikelola Supabase Auth. plan_type menentukan akses freemium/premium.                 |
| **chat_rooms** | id, user_id, agent_type, created_at    | Setiap baris = satu Ruang Obrolan. agent_type menentukan system prompt yang dipakai. |
| **messages**   | id, room_id, role, content, created_at | role: 'user' atau 'assistant'. Dikirim ke Sumopod API sebagai conversation history.  |
| **knowledge_base** | id, agent_type, chunk_content, embedding, metadata | Menggunakan ekstensi **pgvector** (`vector` type). Menyimpan potongan dokumen RAG. |
| **agents**     | id, name, system_prompt, avatar_url, created_at | Konfigurasi agen AI yang dikelola melalui Dashboard.                             |

### **Arsitektur RAG & Pemrosesan Vektor (Next.js ke Supabase)**

Sistem Next.js bertanggung jawab untuk memproses dokumen hingga menjadi data RAG siap pakai:
1. **Upload & Parsing:** Admin mengunggah dokumen referensi via Dashboard. Sistem mengekstrak teks dari dokumen (termasuk PDF via `pdf-parse`).
2. **Chunking:** Teks yang panjang secara otomatis dipecah menjadi bagian-bagian kecil yang bermakna (_chunks_).
3. **Embedding & Penyimpanan:** Next.js Server Actions memanggil Sumopod API (model _embedding_) untuk mengonversi setiap _chunk_ menjadi representasi vektor numerik, lalu menyimpannya ke tabel `knowledge_base` di Supabase PostgreSQL (**pgvector**).
4. **Retrieval:** Saat pengguna bertanya, pertanyaan diubah menjadi vektor, dicari kecocokannya via `match_documents` RPC (cosine similarity, threshold 0.3, max 3 dokumen), dan konteks relevan diberikan kepada LLM sebagai referensi.

# **6\. Kriteria Keberhasilan & Metrik**

Keberhasilan ChatIn diukur dari empat dimensi: kinerja teknis, kualitas AI, akuisisi pengguna, dan retensi jangka panjang.

| **Metrik**              | **Target** | **Catatan**                              |
| ----------------------- | ---------- | ---------------------------------------- |
| App Load Time           | < 2 detik  | Cold start on mid-range device           |
| UI Render               | 60 fps     | Flutter rendering pipeline               |
| AI Response Latency     | < 2 detik  | End-to-end: kirim pesan → terima balasan |
| Day-3 Retention         | \> 40%     | Benchmark aplikasi SaaS mobile           |
| Day-7 Retention         | \> 25%     | Benchmark aplikasi SaaS mobile           |
| Free-to-Paid Conversion | \> 5%      | Target awal fase growth                  |

# **7\. Analisis Risiko & Mitigasi**

Berikut adalah risiko teknis dan bisnis utama yang perlu dimonitor sejak fase development awal:

| **Risiko**                         | **Dampak** | **Mitigasi**                                     |
| ---------------------------------- | ---------- | ------------------------------------------------ |
| Latensi Sumopod API tinggi         | **Tinggi** | Streaming response + loading skeleton UI         |
| Kebijakan store terkait AI berubah | **Tinggi** | Pantau update Apple/Google guideline rutin       |
| Data obrolan sensitif bocor        | **Kritis** | RLS ketat + AES-256 encryption + API proxy       |
| Konteks percakapan terlalu panjang | **Sedang** | Auto-summarize + sliding window history          |
| Churn tinggi di tier Freemium      | **Sedang** | A/B test paywall copywriting & value proposition |

# **8\. Fase Pengembangan**

| **Fase**            | **Durasi (Est.)** | **Deliverable Utama**                                                                          | **Status** |
| ------------------- | ----------------- | ---------------------------------------------------------------------------------------------- | ---------- |
| **Phase 0**         | 1-2 minggu        | Setup project Flutter, Supabase, konfigurasi RLS, koneksi Sumopod API                         | ✅ Done    |
| **Phase 1 (MVP)**   | 4-6 minggu        | Auth, multi-agent chat, riwayat, RAG pipeline, Dashboard                                       | ✅ Done    |
| **Phase 1.5**       | 2-3 minggu        | Landing page, theme system, localization, encryption, OTP, auto-summarize                      | ✅ Done    |
| **Phase 2**         | 3-4 minggu        | Sistem freemium + paywall, integrasi Google Play Billing & Apple IAP                           | 🔜 Next   |
| **Phase 3**         | 2-3 minggu        | Polish UI/UX, push notifications, analytics, persiapan store submission                        | 🔜 Planned |

# **9\. Catatan Teknis Tambahan**

## **Manajemen Konteks AI**

Karena LLM memiliki batasan context window, aplikasi menerapkan strategi sliding window + auto-summarize: history percakapan di-summarize secara berkala melalui endpoint `/api/chat/summarize`, dan summary tersebut disisipkan ke system prompt untuk menjaga kelangsungan konteks tanpa mengirim seluruh riwayat.

## **Streaming Response**

Streaming response telah diimplementasikan: Next.js API menggunakan `ReadableStream` untuk mengirim token AI secara bertahap. Flutter me-render respons secara real-time (word-by-word).

## **Enkripsi Chat Content**

Konten chat dienkripsi menggunakan AES-256 di sisi client (Flutter) sebelum dikirim ke Supabase. Key enkripsi dikelola melalui `.env` file dan di-pad ke 32 byte. IV menggunakan 16 byte pertama dari key.

## **Pengelolaan API Key**

Kunci API Sumopod tidak pernah ada di kode Flutter (client-side). Seluruh panggilan ke LLM dirutekan melalui Next.js API (`/api/chat`) sebagai proxy aman. API key hanya ada di server environment (`.env.local`).

## **Multi-Language Support**

Aplikasi mendukung Bahasa Inggris dan Bahasa Indonesia menggunakan package `easy_localization`. File terjemahan disimpan di `assets/translations/` dalam format JSON.

_ChatIn Tech Concept Brief · v1.1 · Updated berdasarkan implementasi aktual_
