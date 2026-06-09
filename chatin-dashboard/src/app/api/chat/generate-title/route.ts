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
    // Mendukung 'userMessage' dan 'aiMessage' (dari Flutter) atau 'message' sebagai fallback
    const userMessage = body.userMessage || body.message;
    const aiMessage = body.aiMessage || "";

    if (!userMessage) {
      return NextResponse.json(
        { error: "User message is required" },
        { status: 400 },
      );
    }

    // Call Sumopod Chat API to generate a title
    const chatModel = process.env.SUMOPOD_CHAT_MODEL || "gpt-3.5-turbo";
    
    const promptContent = `Generate a short, concise title (maximum 5 words) that summarizes the following conversation. Do not include quotation marks or phrases like 'Title:' in the output. Just return the raw title string.\n\nUser: ${userMessage}${aiMessage ? `\nAI: ${aiMessage}` : ''}`;

    const response = await sumopod.chat.completions.create({
      model: chatModel,
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant that generates short, concise titles for chat conversations.",
        },
        { role: "user", content: promptContent },
      ],
      temperature: 0.7,
      max_tokens: 500,
    });

    const title = response.choices[0]?.message?.content?.trim();

    return NextResponse.json({ title: title || "New Chat" });
  } catch (error: any) {
    console.error("Error in generate-title API:", error);
    return NextResponse.json(
      { error: "Internal server error", details: error.message },
      { status: 500 },
    );
  }
}
