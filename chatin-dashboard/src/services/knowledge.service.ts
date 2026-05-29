import { createClient } from "@/utils/supabase/client";
import { type KnowledgeDocument } from "@/types/knowledge";

/**
 * Fetches all documents from the knowledge_base table,
 * grouped by document_name and agent_id for the summary UI.
 */
export async function getKnowledgeDocuments(): Promise<KnowledgeDocument[]> {
  try {
    const supabase = createClient();

    // Fetch all chunks with their agent info
    const { data, error } = await supabase
      .from("knowledge_base")
      .select("document_name, agent_id, created_at, agents(name)")
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error fetching knowledge documents:", error);
      throw error;
    }

    if (!data || data.length === 0) return [];

    // Group chunks by document_name + agent_id
    const docMap = new Map<
      string,
      {
        document_name: string;
        agent_id: string;
        agent_name: string;
        chunks: number;
        uploaded_at: string;
      }
    >();

    for (const row of data) {
      const key = `${row.document_name}__${row.agent_id}`;
      const agentData = row.agents as unknown as { name: string } | null;

      if (!docMap.has(key)) {
        docMap.set(key, {
          document_name: row.document_name,
          agent_id: row.agent_id,
          agent_name: agentData?.name || "Agen tidak diketahui",
          chunks: 0,
          uploaded_at: row.created_at || "",
        });
      }

      const existing = docMap.get(key)!;
      existing.chunks += 1;
    }

    // Convert map to array and mark all as embedded (since they've been saved with embeddings)
    return Array.from(docMap.values()).map((doc) => ({
      ...doc,
      status: "embedded" as const,
    }));
  } catch (error) {
    console.error("Error in getKnowledgeDocuments service:", error);
    return [];
  }
}

/**
 * Deletes all chunks belonging to a specific document for a given agent.
 */
export async function deleteKnowledgeDocument(
  documentName: string,
  agentId: string
): Promise<boolean> {
  try {
    const supabase = createClient();
    const { error } = await supabase
      .from("knowledge_base")
      .delete()
      .eq("document_name", documentName)
      .eq("agent_id", agentId);

    if (error) {
      console.error("Error deleting knowledge document:", error);
      throw error;
    }

    return true;
  } catch (error) {
    console.error("Error in deleteKnowledgeDocument service:", error);
    return false;
  }
}
