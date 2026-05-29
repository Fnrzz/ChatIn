import OpenAI from "openai";

const sumopod = new OpenAI({
  baseURL: process.env.SUMOPOD_BASE_URL,
  apiKey: process.env.SUMOPOD_API_KEY,
});

/**
 * Generates an embedding for the given text using Sumopod API.
 * This is a placeholder function for the RAG processing pipeline.
 *
 * @param text The input text to generate embedding for
 * @returns An array of numbers representing the embedding vector
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  const embeddingModel =
    process.env.SUMOPOD_EMBEDDING_MODEL || "text-embedding-3-small";
  const response = await sumopod.embeddings.create({
    model: embeddingModel,
    input: text,
  });

  return response.data[0].embedding;
}

export default sumopod;
