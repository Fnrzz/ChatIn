-- ==============================================================================
-- SCRIPT SQL UNTUK SUPABASE CLOUD SYNC & PRIVACY
-- Copy dan paste script ini ke SQL Editor di dashboard Supabase Anda lalu RUN.
-- ==============================================================================

-- 1. Buat tabel chat_sessions
CREATE TABLE IF NOT EXISTS chat_sessions (
  id UUID PRIMARY KEY,
  agent_id UUID,
  title TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at BIGINT,
  summary TEXT
);

-- 2. Buat tabel chat_messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id SERIAL PRIMARY KEY,
  session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
  role TEXT,
  content TEXT,
  is_summarized SMALLINT DEFAULT 0,
  created_at BIGINT
);

-- 3. Mengaktifkan Row Level Security (RLS) di kedua tabel
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- 4. Hapus policy lama jika ada (mencegah error saat run ulang)
DROP POLICY IF EXISTS "Users can manage their own sessions" ON chat_sessions;
DROP POLICY IF EXISTS "Users can manage their own messages" ON chat_messages;

-- 5. Buat Policy untuk chat_sessions
-- Pengguna hanya bisa melakukan SELECT, INSERT, UPDATE, DELETE pada sesi milik mereka sendiri
CREATE POLICY "Users can manage their own sessions" 
ON chat_sessions 
FOR ALL 
USING (auth.uid() = user_id);

-- 6. Buat Policy untuk chat_messages
-- Pengguna hanya bisa melakukan operasi pada pesan yang session_id-nya terhubung dengan user_id mereka
CREATE POLICY "Users can manage their own messages" 
ON chat_messages 
FOR ALL 
USING (
  session_id IN (SELECT id FROM chat_sessions WHERE user_id = auth.uid())
);
