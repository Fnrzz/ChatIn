**ChatIn**

Tech Concept Brief

_Platform Mobile AI - Android & iOS_

Versi Dokumen: 1.0 · Status: Draf

Berdasarkan PRD Revisi 1

# **1\. Gambaran Produk**

ChatIn adalah aplikasi mobile berbasis AI yang menyediakan ekosistem "Ruang Obrolan Spesialis" - di mana setiap ruang dihuni oleh agen AI dengan persona, keahlian, dan instruksi (system prompt) yang berbeda-beda. Pengguna dapat berinteraksi dengan AI layaknya berkonsultasi dengan seorang spesialis: psikolog, mentor desain, atau asisten koding. 

Sebagai pendukung di balik layar, terdapat **Web Admin Dashboard** (chatin-dashboard) yang bertindak sebagai Control Center. Melalui dashboard ini, admin dan tim pengelola dapat mengatur agen AI serta memperkaya pengetahuan agen tersebut dengan menyuntikkan dokumen _knowledge base_ spesifik melalui sistem _Retrieval-Augmented Generation_ (RAG).

Produk ini dibangun di atas model bisnis freemium berbasis langganan (SaaS), dengan akses tak terbatas ke semua agen spesialis sebagai nilai utama paket premium.

## **Proposisi Nilai Utama**

- Konteks terisolasi per-agen: obrolan dengan Psikolog AI tidak pernah tercampur dengan sesi Mentor UI/UX.
- Memori percakapan lintas sesi: AI mengingat detail diskusi sebelumnya berkat sinkronisasi cloud realtime.
- UI native-like di Android & iOS dari satu codebase Flutter.
- Proses onboarding dan pembayaran in-app yang mulus sesuai kebijakan masing-masing store.

# **2\. Arsitektur Teknis**

Sistem ChatIn dibangun dengan pendekatan three-tier: mobile client (Flutter), backend-as-a-service (Supabase), dan integrasi LLM (Sumopod). Setiap lapisan memiliki tanggung jawab yang terdefinisi jelas untuk memaksimalkan keamanan, skalabilitas, dan kecepatan pengembangan.

## **2.1 Diagram Arsitektur (Konseptual)**

```text
┌──────────────────────┐     ┌──────────────────────────────────────────┐
│                      │     │           Supabase (BaaS)                │
│   Flutter App        │◄───►│  ┌─────────┐ ┌────────┐ ┌───────────┐  │
│   (Android & iOS)    │     │  │  Auth    │ │ Postgres│ │ pgvector  │  │
│                      │     │  │(Google,  │ │   DB    │ │ (RAG)     │  │
└───────┬──────────────┘     │  │ Email)   │ └────────┘ └───────────┘  │
        │                    └──────────┬───────────────────────────────┘
        │ (Chat API)                    │
        ▼                               │
┌──────────────────────┐                │
│   Next.js Dashboard  │◄───────────────┘
│   (Admin Panel)      │◄──────────────────► Sumopod API (LLM & Embedding)
│   • Agent Management │
│   • Knowledge Base   │
│   • RAG Pipeline     │
└──────────────────────┘
```

## **2.2 Stack Teknologi**

| **Layer**         | **Teknologi**                   | **Justifikasi**                                                   |
| ----------------- | ------------------------------- | ----------------------------------------------------------------- |
| Mobile Framework  | Flutter (Dart)                  | Single codebase untuk Android & iOS, native-like UI, 60fps        |
| Web Dashboard     | Next.js                         | Framework React modern untuk backend admin dan Control Center     |
| Backend & Auth    | Supabase                        | PostgreSQL + Auth + RLS bawaan, mudah di-scale, realtime support  |
| Database & Vector | PostgreSQL + pgvector (Supabase)| Relasional terstruktur dan pencarian semantik (RAG) untuk AI      |
| AI / LLM Provider | Sumopod API                     | Dikonfigurasi per-ruang obrolan (LLM) dan menghasilkan embeddings |
| In-App Purchase   | Google Play Billing + Apple IAP | Wajib untuk distribusi di Play Store dan App Store                |
| Cloud Sync        | Supabase Realtime               | WebSocket-based, sinkronisasi histori obrolan lintas perangkat    |

## **2.3 Keamanan Data**

Keamanan data menjadi prioritas utama, terutama mengingat sensitivitas konten obrolan pengguna (termasuk konsultasi psikologis).

- **RLS Supabase:** Row Level Security (RLS) di PostgreSQL memastikan setiap query secara otomatis terfilter berdasarkan user_id yang terautentikasi.
- **Manajemen Sesi:** Token sesi dienkripsi dan dikelola sepenuhnya oleh Supabase Auth, mendukung social login (Google, Apple).
- **Isolasi Konteks:** Setiap Ruang Obrolan memiliki konteks terisolasi di level database, bukan hanya di level UI.
- **Enkripsi Transit:** Seluruh komunikasi menggunakan HTTPS/TLS. Tidak ada data sensitif yang disimpan di local storage perangkat.

# **3\. Breakdown Fitur**

## **3.1 Autentikasi Pengguna**

- **Metode Login:** Email & Password, Google Sign-In, Apple ID - semuanya melalui Supabase Auth.
- **Manajemen Sesi:** Token sesi terenkripsi yang persisten antar session (tidak perlu login ulang).
- **Onboarding:** Pengguna baru mendapatkan welcome screen dan tur fitur singkat.

## **3.2 Sistem Langganan (Freemium)**

- **Tier Gratis:** Akses terbatas: 5 pesan per hari ke agen umum. Cukup untuk memvalidasi produk sebelum konversi.
- **Tier Premium:** Akses tak terbatas ke semua Ruang Spesialis, prioritas respons, konteks ingatan lebih panjang.
- **Mekanisme Pembayaran:** Google Play Billing (Android) dan Apple In-App Purchases (iOS) - sesuai kebijakan distribusi resmi.
- **Paywall Trigger:** Paywall ditampilkan saat pengguna mencoba mengakses agen berlabel Premium.

## **3.3 Manajemen Riwayat Obrolan**

- **Real-time Sync:** Setiap pesan langsung di-sync ke PostgreSQL via Supabase Realtime (WebSocket).
- **Sesi Berkelanjutan:** Saat aplikasi dibuka kembali, Flutter me-load riwayat dari DB sehingga percakapan langsung dapat dilanjutkan.
- **Privasi & Kontrol:** Pengguna dapat mencari riwayat obrolan dan mereset konteks AI per-ruang jika diinginkan.

## **3.4 Ruang Obrolan Spesialis**

- **Konfigurasi Persona:** Setiap agen dikonfigurasi dengan system prompt unik yang dikirim bersama setiap request ke Sumopod API.
- Psikolog/Konselor AI (empati, tidak menghakimi, teknik relaksasi dasar).
- Mentor UI/UX (prinsip desain, studi kasus, fase product design).
- Asisten Koding & Generalist (debugging, tanya jawab umum, pemrograman).
- **Manajemen Konteks:** Konteks percakapan sebelumnya dikirim bersamaan dengan pesan baru ke API (sliding window history).

## **3.5 Web Admin Dashboard (Admin-Only)**

- **Control Center:** Aplikasi web Next.js untuk memonitor, menambah, mengedit, dan menghapus agen AI.
- **Akses Eksklusif Admin:** Mempertahankan arsitektur MVP yang ramping, dashboard ini tidak menggunakan sistem RBAC yang kompleks. Akses ke _dashboard_ eksklusif hanya untuk **Admin**, yang memiliki wewenang penuh atas manajemen agen, _system prompt_, dan pengelolaan data RAG secara langsung.
- **Manajemen RAG (Retrieval-Augmented Generation):** UI terintegrasi bagi pengguna dashboard untuk mengunggah file (PDF/Teks), membaginya (_chunking_), mengubahnya menjadi vektor _embedding_ melalui Sumopod API, dan menyimpannya ke Supabase (`pgvector`).

# **4\. Alur Pengguna (User Flow)**

| **Tahap**          | **Aktivitas Pengguna**                    | **Komponen Teknis Terlibat**                     |
| ------------------ | ----------------------------------------- | ------------------------------------------------ |
| **1\. Onboarding** | Download app, daftar akun                 | Supabase Auth (email/Google/Apple)               |
| **2\. Eksplorasi** | Lihat grid Ruang Spesialis di Home Screen | Flutter Widget, Supabase DB (fetch katalog agen) |
| **3\. Konversi**   | Pilih agen Premium → muncul Paywall       | Flutter + Google Play Billing / Apple IAP        |
| **4\. Interaksi**  | Kirim pesan, terima balasan AI            | Next.js API + Sumopod API                        |
| **5\. Retensi**    | Buka ulang app, lanjutkan obrolan         | Supabase Realtime + PostgreSQL (load history)    |

# **5\. Skema Database (Konseptual)**

Database PostgreSQL di Supabase terdiri dari tiga entitas utama yang saling berelasi:

| **Tabel**      | **Kolom Utama**                        | **Keterangan**                                                                       |
| -------------- | -------------------------------------- | ------------------------------------------------------------------------------------ |
| **users**      | id, email, plan_type, created_at       | Dikelola Supabase Auth. plan_type menentukan akses freemium/premium.                 |
| **chat_rooms** | id, user_id, agent_type, created_at    | Setiap baris = satu Ruang Obrolan. agent_type menentukan system prompt yang dipakai. |
| **messages**   | id, room_id, role, content, created_at | role: 'user' atau 'assistant'. Dikirim ke Sumopod API sebagai conversation history.  |
| **knowledge_base** | id, agent_type, chunk_content, embedding, metadata | Menggunakan ekstensi **pgvector** (`vector` type). Menyimpan potongan dokumen RAG. |

### **Arsitektur RAG & Pemrosesan Vektor (Next.js ke Supabase)**

Sistem Next.js bertanggung jawab untuk memproses dokumen hingga menjadi data RAG siap pakai:
1. **Upload & Parsing:** Admin mengunggah dokumen referensi (contoh: panduan desain UX). Sistem Next.js mengekstrak teks dari dokumen.
2. **Chunking:** Teks yang panjang secara otomatis dipecah menjadi bagian-bagian kecil yang bermakna (_chunks_).
3. **Embedding & Penyimpanan:** Tanpa proses _approval_ yang rumit, Next.js langsung memanggil Sumopod API (model _embedding_) untuk mengonversi setiap _chunk_ teks menjadi representasi vektor numerik, lalu menyimpannya ke dalam tabel `knowledge_base` di Supabase PostgreSQL (**pgvector**).
5. **Retrieval:** Saat pengguna bertanya di aplikasi Flutter, pertanyaan diubah menjadi vektor, dicari kecocokannya secara matematis (seperti _cosine similarity_) di database `pgvector`, dan konteks relevan ditarik untuk diberikan kepada LLM Sumopod sebagai referensi jawaban agen.

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
| Latensi Sumopod API tinggi         | **Tinggi** | Tambah loading skeleton UI + streaming response  |
| Kebijakan store terkait AI berubah | **Tinggi** | Pantau update Apple/Google guideline rutin       |
| Data obrolan sensitif bocor        | **Kritis** | RLS ketat di Supabase + enkripsi token sesi      |
| Konteks percakapan terlalu panjang | **Sedang** | Truncate history + simpan ringkasan di DB        |
| Churn tinggi di tier Freemium      | **Sedang** | A/B test paywall copywriting & value proposition |

# **8\. Saran Fase Pengembangan**

| **Fase**          | **Durasi (Est.)** | **Deliverable Utama**                                                                          |
| ----------------- | ----------------- | ---------------------------------------------------------------------------------------------- |
| **Phase 0**       | 1-2 minggu        | Setup project Flutter, Supabase, konfigurasi RLS dasar, koneksi Sumopod API (smoke test)       |
| **Phase 1 (MVP)** | 4-6 minggu        | Auth pengguna, 1 Ruang Obrolan (Asisten Umum), simpan & load riwayat dari Supabase             |
| **Phase 2**       | 3-4 minggu        | Tambah 2+ agen spesialis, sistem freemium + paywall, integrasi Google Play Billing & Apple IAP |
| **Phase 3**       | 2-3 minggu        | Polish UI/UX, optimasi latensi, notifikasi push, analytics dasar, persiapan store submission   |

# **9\. Catatan Teknis Tambahan**

## **Manajemen Konteks AI**

Karena LLM memiliki batasan context window, aplikasi harus menerapkan strategi sliding window: hanya N pesan terakhir yang dikirim ke Sumopod API bersamaan dengan pesan baru. Pesan-pesan lama tetap tersimpan di DB untuk referensi pengguna, namun tidak dikirim ke API.

## **Streaming Response**

Untuk pengalaman pengguna yang lebih responsif (tidak menunggu seluruh balasan selesai), direkomendasikan mengimplementasikan streaming response dari Sumopod API. Flutter dapat merender token AI secara bertahap menggunakan StreamBuilder widget.

## **Offline Graceful Degradation**

Jika koneksi internet terputus, aplikasi harus menampilkan pesan error yang ramah dan menonaktifkan input sementara. Riwayat obrolan yang sudah di-load tetap dapat dibaca secara offline.

## **Pengelolaan API Key**

Kunci API Sumopod tidak boleh di-hardcode di kode Flutter (client-side). Seluruh panggilan ke LLM harus dirutekan melalui Next.js API sebagai proxy aman, sehingga API key hanya ada di server environment.

_ChatIn Tech Concept Brief · Draf v1.0 · Berdasarkan PRD Revisi 1_
