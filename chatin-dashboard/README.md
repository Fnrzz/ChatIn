# ChatIn Dashboard — Admin Panel 🖥️

Web-based admin dashboard built with **Next.js 16** for managing AI agents, knowledge base (RAG), and testing chat interactions.

---

## 🌟 Overview

ChatIn Dashboard adalah pusat kontrol (**Control Center**) untuk mengelola seluruh ekosistem ChatIn. Melalui dashboard ini, admin dapat:
- Menambah, mengedit, dan menghapus agen AI beserta system prompt-nya
- Mengunggah dokumen ke Knowledge Base (RAG pipeline)
- Menguji interaksi dengan agen melalui Chat Playground
- Mengelola avatar agen AI

---

## ⚡ Tech Stack

| Package                | Version  | Purpose                              |
| ---------------------- | -------- | ------------------------------------ |
| `next`                 | 16.2.6   | React framework (App Router)         |
| `react` / `react-dom`  | 19.2.4   | UI library                           |
| `@supabase/supabase-js`| ^2.106.2 | Supabase client                      |
| `@supabase/ssr`        | ^0.10.3  | Supabase SSR helpers                 |
| `openai`               | ^6.39.0  | OpenAI-compatible API client         |
| `shadcn` + `radix-ui`  | ^4.8.1   | UI component library                 |
| `tailwindcss`          | ^4.3.0   | Utility-first CSS framework          |
| `lucide-react`         | ^1.16.0  | Icon library                         |
| `pdf-parse`            | ^1.1.1   | PDF document parsing for RAG         |
| `react-markdown`       | ^10.1.0  | Markdown rendering                   |
| `class-variance-authority` | ^0.7.1 | Component variant styling          |

---

## 📂 Project Structure

```
src/
├── app/
│   ├── (auth)/
│   │   └── login/page.tsx             # Admin login page
│   ├── (dashboard)/
│   │   ├── layout.tsx                 # Dashboard shell with sidebar
│   │   ├── agents/page.tsx            # Agent CRUD management
│   │   ├── avatars/page.tsx           # Agent avatar management
│   │   ├── chat/page.tsx              # Chat playground
│   │   └── knowledge-base/page.tsx    # RAG document management
│   ├── actions/
│   │   └── rag.actions.ts             # Server actions for RAG pipeline
│   ├── api/chat/
│   │   ├── route.ts                   # Main chat endpoint (streaming + RAG)
│   │   ├── generate-title/route.ts    # Auto chat title generation
│   │   └── summarize/route.ts         # Conversation summarization
│   ├── layout.tsx                     # Root layout
│   ├── page.tsx                       # Root redirect
│   └── globals.css                    # Global styles & Tailwind
├── components/
│   ├── layout/
│   │   ├── nav-config.ts              # Navigation menu configuration
│   │   ├── sidebar-brand.tsx          # Sidebar brand/logo
│   │   ├── sidebar-content.tsx        # Sidebar container
│   │   ├── sidebar-nav.tsx            # Sidebar navigation links
│   │   └── sidebar-user-footer.tsx    # Sidebar user info footer
│   └── ui/                            # shadcn/ui components
│       ├── avatar.tsx     ├── badge.tsx
│       ├── button.tsx     ├── card.tsx
│       ├── dialog.tsx     ├── input.tsx
│       ├── label.tsx      ├── select.tsx
│       ├── separator.tsx  ├── sheet.tsx
│       ├── table.tsx      ├── tabs.tsx
│       ├── textarea.tsx   └── tooltip.tsx
├── services/
│   ├── agent.service.ts               # Agent CRUD operations
│   ├── knowledge.service.ts           # Knowledge base operations
│   └── user.service.ts                # User management
├── types/
│   ├── agent.ts                       # Agent type definitions
│   ├── knowledge.ts                   # Knowledge base types
│   ├── navigation.ts                  # Navigation config types
│   ├── user.ts                        # User type definitions
│   └── pdf-parse.d.ts                 # PDF parse type declarations
├── utils/
│   ├── ai/sumopod.ts                  # Sumopod API client & embedding fn
│   └── supabase/
│       ├── client.ts                  # Browser Supabase client
│       └── server.ts                  # Server-side Supabase client
└── proxy.ts                           # API proxy configuration
```

---

## 🔑 Key Features

### Agent Management
- CRUD operasi untuk agen AI (nama, deskripsi, system prompt, avatar)
- Konfigurasi persona unik per agen

### Knowledge Base (RAG Pipeline)
- Upload dokumen (PDF/teks)
- Automatic text chunking
- Vector embedding via Sumopod API
- Storage ke Supabase pgvector

### Chat API
- **`POST /api/chat`** — Main chat endpoint dengan streaming response + RAG context
- **`POST /api/chat/generate-title`** — Auto-generate judul sesi chat
- **`POST /api/chat/summarize`** — Summarisasi konteks percakapan
- Dual authentication: API Key (Flutter) + Session (Dashboard)

### Chat Playground
- Interface untuk menguji interaksi langsung dengan agen AI
- Real-time streaming response
- Markdown rendering untuk balasan AI

---

## 🚀 Getting Started

### Prerequisites

- Node.js `>= 18`
- Supabase project with `pgvector` extension
- Sumopod API key

### Setup

```bash
# Navigate to the dashboard directory
cd chatin-dashboard

# Create .env.local file
cat > .env.local << EOF
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUMOPOD_API_KEY=your_sumopod_api_key
SUMOPOD_CHAT_MODEL=gpt-3.5-turbo
API_SECRET_KEY=your_secret_key
EOF

# Install dependencies
npm install

# Run development server
npm run dev
```

### Environment Variables

| Variable                         | Description                              |
| -------------------------------- | ---------------------------------------- |
| `NEXT_PUBLIC_SUPABASE_URL`       | Supabase project URL                     |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY`  | Supabase anonymous/public key            |
| `SUPABASE_SERVICE_ROLE_KEY`      | Supabase service role key (admin access) |
| `SUMOPOD_API_KEY`                | Sumopod API key for LLM & embeddings     |
| `SUMOPOD_CHAT_MODEL`            | LLM model name (default: `gpt-3.5-turbo`) |
| `API_SECRET_KEY`                 | Secret key for API authentication        |

---

## 🔒 API Authentication

Dashboard menggunakan **dual authentication**:

1. **API Key** (`x-api-key` header) — Untuk request dari Flutter mobile app
2. **Session Auth** — Untuk request dari dashboard itu sendiri (cookie-based)

Jika keduanya tidak valid, API mengembalikan `401 Unauthorized`.

---

## 📝 Notes

- Dashboard ini bersifat **admin-only** (tidak menggunakan RBAC kompleks)
- RAG pipeline berjalan di server-side via Next.js Server Actions
- Semua API key LLM hanya ada di server environment, tidak pernah di-expose ke client
