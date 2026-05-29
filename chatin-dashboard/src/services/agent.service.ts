import { createClient } from "@/utils/supabase/client";
import { type Agent, type InsertAgent, type UpdateAgent } from "@/types/agent";

export async function getAgents(): Promise<Agent[]> {
  try {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("agents")
      .select("*, knowledge_base(document_name)")
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error fetching agents:", error);
      throw error;
    }

    if (!data) return [];

    return data.map((agent: any) => {
      const chunks = agent.knowledge_base || [];
      const uniqueDocs = new Set(chunks.map((c: any) => c.document_name));
      
      const { knowledge_base, ...agentData } = agent;
      return {
        ...agentData,
        knowledgeCount: uniqueDocs.size,
      };
    });
  } catch (error) {
    console.error("Error in getAgents service:", error);
    return [];
  }
}

export async function createAgent(agent: InsertAgent): Promise<Agent | null> {
  try {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("agents")
      .insert([agent])
      .select()
      .single();

    if (error) {
      console.error("Error creating agent:", error);
      throw error;
    }

    return data;
  } catch (error) {
    console.error("Error in createAgent service:", error);
    return null;
  }
}

export async function updateAgent(
  id: string,
  agent: UpdateAgent
): Promise<Agent | null> {
  try {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("agents")
      .update(agent)
      .eq("id", id)
      .select()
      .single();

    if (error) {
      console.error("Error updating agent:", error);
      throw error;
    }

    return data;
  } catch (error) {
    console.error("Error in updateAgent service:", error);
    return null;
  }
}

export async function deleteAgent(id: string): Promise<boolean> {
  try {
    const supabase = createClient();
    const { error } = await supabase.from("agents").delete().eq("id", id);

    if (error) {
      console.error("Error deleting agent:", error);
      throw error;
    }

    return true;
  } catch (error) {
    console.error("Error in deleteAgent service:", error);
    return false;
  }
}
