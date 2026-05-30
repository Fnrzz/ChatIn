import { NextResponse } from "next/server";
import { createClient } from "@/utils/supabase/server";
import sumopod from "@/utils/ai/sumopod";

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
    const { oldSummary = "", newMessages = [] } = body;

    const summarizePrompt = `You are an AI memory summarization assistant. Your task is to update the conversation memory. Previous memory: ${oldSummary || 'None'}. New messages: ${JSON.stringify(newMessages)}. Write a single concise paragraph (maximum 4 sentences) summarizing the core context, user profile, and their problems. Do not answer the user's questions or continue the conversation. Only return the updated summary.`;

    const chatModel = process.env.SUMOPOD_CHAT_MODEL || "gpt-3.5-turbo";
    const response = await sumopod.chat.completions.create({
      model: chatModel,
      messages: [{ role: "user", content: summarizePrompt }],
      stream: false,
    });

    const summary = response.choices[0]?.message?.content || "";

    return NextResponse.json({ summary });
  } catch (error: any) {
    console.error("Error in summarize API:", error);
    return NextResponse.json(
      { error: "Internal server error", details: error.message },
      { status: 500 },
    );
  }
}
