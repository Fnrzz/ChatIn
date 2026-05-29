"use server";

import { createClient } from "@/utils/supabase/server";
import { generateEmbedding } from "@/utils/ai/sumopod";

/**
 * Splits text into meaningful chunks based on paragraphs.
 * Each chunk is ~500-1000 characters, split at paragraph boundaries
 * to preserve context.
 */
function chunkText(text: string, maxChunkSize = 800): string[] {
  const paragraphs = text.split(/\n\s*\n/);
  const chunks: string[] = [];
  let currentChunk = "";

  for (const paragraph of paragraphs) {
    const trimmedParagraph = paragraph.trim();
    if (!trimmedParagraph) continue;

    // If adding this paragraph exceeds the limit, save the current chunk first
    if (
      currentChunk.length > 0 &&
      currentChunk.length + trimmedParagraph.length + 2 > maxChunkSize
    ) {
      chunks.push(currentChunk.trim());
      currentChunk = "";
    }

    // If a single paragraph is larger than maxChunkSize, split it by sentences
    if (trimmedParagraph.length > maxChunkSize) {
      if (currentChunk.length > 0) {
        chunks.push(currentChunk.trim());
        currentChunk = "";
      }
      const sentences = trimmedParagraph.split(/(?<=[.!?])\s+/);
      let sentenceChunk = "";
      for (const sentence of sentences) {
        if (
          sentenceChunk.length > 0 &&
          sentenceChunk.length + sentence.length + 1 > maxChunkSize
        ) {
          chunks.push(sentenceChunk.trim());
          sentenceChunk = "";
        }
        sentenceChunk += (sentenceChunk ? " " : "") + sentence;
      }
      if (sentenceChunk.trim()) {
        currentChunk = sentenceChunk.trim();
      }
    } else {
      currentChunk += (currentChunk ? "\n\n" : "") + trimmedParagraph;
    }
  }

  if (currentChunk.trim()) {
    chunks.push(currentChunk.trim());
  }

  return chunks.filter((c) => c.length > 0);
}

interface ProcessResult {
  success: boolean;
  message?: string;
  error?: string;
}

export async function processAndSaveDocument(
  formData: FormData,
): Promise<ProcessResult> {
  try {
    const file = formData.get("file") as File | null;
    const agentId = formData.get("agentId") as string | null;

    if (!file) {
      return { success: false, error: "File tidak ditemukan." };
    }

    if (!agentId) {
      return { success: false, error: "Agen tujuan belum dipilih." };
    }

    // Validate file type
    const fileName = file.name.toLowerCase();
    const isTextFile = fileName.endsWith(".txt") || fileName.endsWith(".md");
    const isPdf = fileName.endsWith(".pdf");

    if (!isTextFile && !isPdf) {
      return {
        success: false,
        error: "Format file tidak didukung. Gunakan file .txt, .md, atau .pdf.",
      };
    }

    // Read file content
    let text: string;
    if (isTextFile) {
      text = await file.text();
    } else if (isPdf) {
      try {
        // Import directly from lib to bypass pdf-parse's buggy index.js
        // which tries to read a test file when module.parent is falsy
        const pdfParse = (await import("pdf-parse/lib/pdf-parse.js")).default;
        const buffer = Buffer.from(await file.arrayBuffer());
        const pdfData = await pdfParse(buffer);
        text = pdfData.text;
      } catch (pdfError: any) {
        console.error("Error extracting text from PDF:", pdfError);
        return {
          success: false,
          error:
            "Gagal mengekstrak teks dari PDF. Pastikan file tidak dikunci dengan password dan berisi teks (bukan hanya gambar hasil scan).",
        };
      }
    } else {
      return {
        success: false,
        error: "Dukungan format ini belum tersedia.",
      };
    }

    if (!text.trim()) {
      return {
        success: false,
        error: "File kosong atau tidak memiliki konten teks.",
      };
    }

    // Chunk the text
    const chunks = chunkText(text);

    if (chunks.length === 0) {
      return { success: false, error: "Gagal memecah teks menjadi chunks." };
    }

    // Initialize Supabase server client
    const supabase = await createClient();

    // Process each chunk: generate embedding and save to database
    for (const chunk of chunks) {
      const embedding = await generateEmbedding(chunk);

      const { error: insertError } = await supabase
        .from("knowledge_base")
        .insert({
          agent_id: agentId,
          document_name: file.name,
          chunk_content: chunk,
          embedding: embedding,
        });

      if (insertError) {
        console.error("Error inserting chunk:", insertError);
        return {
          success: false,
          error: `Gagal menyimpan chunk ke database: ${insertError.message}`,
        };
      }
    }

    return {
      success: true,
      message: `Berhasil memproses "${file.name}" — ${chunks.length} chunk telah di-embed dan disimpan.`,
    };
  } catch (error) {
    console.error("Error in processAndSaveDocument:", error);
    return {
      success: false,
      error: "Terjadi kesalahan saat memproses dokumen. Silakan coba lagi.",
    };
  }
}
