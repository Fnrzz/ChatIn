export interface KnowledgeChunk {
  id: string;
  agent_id: string;
  document_name: string;
  chunk_content: string;
  embedding: number[];
  created_at?: string;
}

/** Summarized document view for the UI table (aggregated from chunks) */
export interface KnowledgeDocument {
  document_name: string;
  agent_id: string;
  agent_name: string;
  chunks: number;
  status: "embedded" | "processing";
  uploaded_at: string;
}
