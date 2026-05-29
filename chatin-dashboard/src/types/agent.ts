export interface Agent {
  id: string;
  name: string;
  type: string;
  description: string;
  system_prompt: string;
  status: string;
  created_at?: string;
  knowledgeCount?: number; // Optional for now since it's not in the base table
}

export type InsertAgent = Omit<Agent, "id" | "created_at" | "knowledgeCount">;
export type UpdateAgent = Partial<InsertAgent>;
