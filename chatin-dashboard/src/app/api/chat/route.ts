import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";
import sumopod, { generateEmbedding } from "@/utils/ai/sumopod";

export async function POST(req: Request) {
  try {
    const apiKey = req.headers.get("x-api-key");
    const supabase = await createClient();
    
    // Validasi: Gunakan API Key (untuk external/Flutter) ATAU Session (untuk Dashboard)
    if (!apiKey || apiKey !== process.env.API_SECRET_KEY) {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        return NextResponse.json(
          { error: "Unauthorized: Invalid API Key or Session" },
          { status: 401 },
        );
      }
    }

    const body = await req.json();
    const { message, agentId, history = [], sessionId, summary } = body;

    if (!message || !agentId) {
      return NextResponse.json(
        { error: "Message and agentId are required" },
        { status: 400 },
      );
    }

    // 1. Fetch Agent's system prompt
    const { data: agent, error: agentError } = await supabase
      .from("agents")
      .select("system_prompt")
      .eq("id", agentId)
      .single();

    if (agentError || !agent) {
      console.error("Error fetching agent:", agentError);
      return NextResponse.json({ error: "Agent not found" }, { status: 404 });
    }

    let baseSystemPrompt =
      agent.system_prompt || "You are a helpful AI assistant.";

    // 2. Generate embedding for user message
    const queryEmbedding = await generateEmbedding(message);

    // 3. Search RAG context via Supabase RPC
    const { data: matchedDocuments, error: matchError } = await supabase.rpc(
      "match_documents",
      {
        query_embedding: queryEmbedding,
        match_threshold: 0.3,
        match_count: 3,
        p_agent_id: agentId,
      },
    );

    if (matchError) {
      console.error("Error matching documents:", matchError);
      // We don't fail the whole request if RAG fails, we just proceed without context
    }

    // 4. Combine context if found
    let contextText = "";
    if (matchedDocuments && matchedDocuments.length > 0) {
      contextText = matchedDocuments
        .map((doc: any) => doc.chunk_content)
        .join("\n\n---\n\n");
    }

    // 5. Build final system prompt (UNIVERSAL RAG)
    let finalSystemPrompt = baseSystemPrompt;

    if (summary) {
      finalSystemPrompt += `\n\nPrevious conversation context: ${summary}`;
    }

    if (contextText) {
      finalSystemPrompt += `
=== REFERENCE INFORMATION (KNOWLEDGE BASE) ===
${contextText}

INSTRUCTIONS FOR USING REFERENCES:
1. Use the references above to enrich your answer if they are relevant to the user's question.
2. Stick to your character, persona, and core rules (as defined in your initial system prompt).
3. Answer as naturally as possible and NEVER use phrases like "According to the document," "According to the reference," or similar.
4. If the user is simply greeting, making small talk, or if the references above don't answer the user's question, ignore them and answer purely using your persona.`;
    }

    // 6. Build messages array for LLM
    const messages = [
      { role: "system", content: finalSystemPrompt },
      ...history.map((msg: any) => ({
        role: msg.role === "assistant" ? "assistant" : "user",
        content: msg.content,
      })),
      { role: "user", content: message },
    ];

    // 7. Call Sumopod Chat API with streaming
    const chatModel = process.env.SUMOPOD_CHAT_MODEL || "gpt-3.5-turbo";
    const responseStream = await sumopod.chat.completions.create({
      model: chatModel,
      messages: messages as any,
      stream: true,
    });

    // 8. Create a readable stream
    const stream = new ReadableStream({
      async start(controller) {
        for await (const chunk of responseStream) {
          const content = chunk.choices[0]?.delta?.content || "";
          if (content) {
            controller.enqueue(new TextEncoder().encode(content));
          }
        }
        controller.close();
      },
    });

    return new Response(stream, {
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "X-Context-Used": contextText.length > 0 ? "true" : "false",
      },
    });
  } catch (error: any) {
    console.error("Error in chat API:", error);
    return NextResponse.json(
      { error: "Internal server error", details: error.message },
      { status: 500 },
    );
  }
}
