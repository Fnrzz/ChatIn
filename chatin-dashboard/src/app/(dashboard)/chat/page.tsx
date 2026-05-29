"use client";

import { useState, useEffect, useRef } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Loader2, Send, Bot, User, DatabaseZap, RotateCcw } from "lucide-react";
import { type Agent } from "@/types/agent";
import { getAgents } from "@/services/agent.service";
import ReactMarkdown from "react-markdown";

type Message = {
  id: string;
  role: "user" | "assistant";
  content: string;
  contextUsed?: boolean;
};

export default function ChatPlaygroundPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [selectedAgentId, setSelectedAgentId] = useState<string>("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState("");
  const [isLoadingAgents, setIsLoadingAgents] = useState(true);
  const [isTyping, setIsTyping] = useState(false);
  const scrollAreaRef = useRef<HTMLDivElement>(null);

  // Auto scroll to bottom
  useEffect(() => {
    if (scrollAreaRef.current) {
      scrollAreaRef.current.scrollTop = scrollAreaRef.current.scrollHeight;
    }
  }, [messages, isTyping]);

  useEffect(() => {
    async function loadAgents() {
      setIsLoadingAgents(true);
      try {
        const data = await getAgents();
        setAgents(data);
        if (data.length > 0) {
          setSelectedAgentId(data[0].id);
        }
      } catch (error) {
        console.error("Gagal memuat agen:", error);
      } finally {
        setIsLoadingAgents(false);
      }
    }
    loadAgents();
  }, []);

  const handleSendMessage = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!inputValue.trim() || !selectedAgentId || isTyping) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content: inputValue.trim(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue("");
    setIsTyping(true);

    try {
      const response = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agentId: selectedAgentId,
          message: userMessage.content,
          history: messages.map((m) => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });

      if (!response.ok) {
        let errorData;
        try {
          errorData = await response.json();
        } catch {
          errorData = { error: "Gagal memanggil API chat" };
        }
        throw new Error(errorData.error || "Gagal memanggil API chat");
      }

      // Hide the typing indicator bubbles, start real typing
      setIsTyping(false);

      const contextUsed = response.headers.get("X-Context-Used") === "true";
      const reader = response.body?.getReader();
      const decoder = new TextDecoder("utf-8");

      if (!reader) throw new Error("No reader from response");

      const aiMessageId = (Date.now() + 1).toString();
      
      // Initialize empty message
      setMessages((prev) => [
        ...prev,
        {
          id: aiMessageId,
          role: "assistant",
          content: "",
          contextUsed,
        },
      ]);

      let currentText = "";
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value, { stream: true });
        currentText += chunk;

        setMessages((prev) =>
          prev.map((msg) =>
            msg.id === aiMessageId ? { ...msg, content: currentText } : msg
          )
        );
      }
    } catch (error: any) {
      console.error("Chat error:", error);
      setIsTyping(false);
      setMessages((prev) => [
        ...prev,
        {
          id: (Date.now() + 1).toString(),
          role: "assistant",
          content: `**Error:** ${error.message || "Terjadi kesalahan sistem."}`,
        },
      ]);
    }
  };

  const handleAgentChange = (value: string) => {
    setSelectedAgentId(value);
    setMessages([]); // Reset chat when switching agents
  };

  const selectedAgent = agents.find((a) => a.id === selectedAgentId);

  return (
    <div className="relative flex h-[calc(100vh-2rem)] flex-col bg-background/50 rounded-xl overflow-hidden border">
      {/* Top Header / Agent Selector */}
      <header className="absolute inset-x-0 top-0 z-10 flex h-14 items-center justify-between border-b bg-background/80 px-4 backdrop-blur-md">
        <div className="flex items-center gap-3">
          <Select
            value={selectedAgentId}
            onValueChange={handleAgentChange}
            disabled={isLoadingAgents || isTyping}
          >
            <SelectTrigger className="h-8 w-[200px] border-none bg-muted/50 font-medium hover:bg-muted/80">
              <SelectValue
                placeholder={
                  isLoadingAgents ? "Memuat agen..." : "Pilih Agen..."
                }
              />
            </SelectTrigger>
            <SelectContent>
              {agents.map((agent) => (
                <SelectItem key={agent.id} value={agent.id}>
                  {agent.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {selectedAgent && (
            <Badge variant="outline" className="hidden capitalize md:inline-flex text-xs">
              {selectedAgent.type} Agent
            </Badge>
          )}
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setMessages([])}
          disabled={messages.length === 0 || isTyping}
          className="text-muted-foreground hover:text-foreground h-8 px-2"
          title="Reset Percakapan"
        >
          <RotateCcw className="mr-2 size-4" />
          <span className="hidden sm:inline">Reset</span>
        </Button>
      </header>

      {/* Main Chat Area */}
      <main
        className="flex-1 overflow-y-auto overflow-x-hidden pt-14 pb-32"
        ref={scrollAreaRef}
      >
        <div className="mx-auto flex max-w-3xl flex-col px-4 py-8">
          {messages.length === 0 ? (
            <div className="flex h-full flex-col items-center justify-center space-y-4 text-center mt-32">
              <div className="flex size-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary/20 to-primary/10 text-primary shadow-sm">
                <Bot className="size-8" />
              </div>
              <div>
                <h2 className="text-xl font-semibold tracking-tight">
                  Halo! Saya {selectedAgent?.name || "Agen AI"}
                </h2>
                <p className="mx-auto mt-2 max-w-[80%] text-sm text-muted-foreground">
                  {selectedAgent?.description ||
                    "Pilih agen AI di kiri atas dan mulai obrolan Anda sekarang."}
                </p>
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-6">
              {messages.map((msg) => (
                <div
                  key={msg.id}
                  className={`flex ${
                    msg.role === "user" ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`flex max-w-[90%] gap-4 md:max-w-[85%] ${
                      msg.role === "user" ? "flex-row-reverse" : "flex-row"
                    }`}
                  >
                    {/* Avatar */}
                    <div
                      className={`flex size-8 shrink-0 items-center justify-center rounded-full mt-1 ${
                        msg.role === "user"
                          ? "bg-muted text-muted-foreground hidden"
                          : "bg-primary/10 text-primary"
                      }`}
                    >
                      {msg.role === "assistant" && <Bot className="size-5" />}
                    </div>

                    {/* Bubble */}
                    <div
                      className={`flex flex-col gap-1 ${
                        msg.role === "user" ? "items-end" : "items-start"
                      }`}
                    >
                      <div
                        className={`px-5 py-3.5 text-[15px] leading-relaxed ${
                          msg.role === "user"
                            ? "rounded-[1.5rem] rounded-br-sm bg-muted/80 text-foreground"
                            : "rounded-[1.5rem] bg-transparent text-foreground"
                        }`}
                      >
                        <div className="prose prose-sm dark:prose-invert max-w-none break-words">
                          <ReactMarkdown>{msg.content}</ReactMarkdown>
                        </div>
                      </div>

                      {/* RAG Indicator */}
                      {msg.role === "assistant" && msg.contextUsed && (
                        <div className="flex items-center gap-1.5 pl-2 pt-1 text-[11px] font-medium text-emerald-600 dark:text-emerald-400">
                          <DatabaseZap className="size-3.5" />
                          <span>Bersumber dari Knowledge Base</span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}

              {/* Typing Indicator */}
              {isTyping && (
                <div className="flex justify-start">
                  <div className="flex max-w-[90%] gap-4 md:max-w-[85%]">
                    <div className="flex size-8 shrink-0 items-center justify-center rounded-full mt-1 bg-primary/10 text-primary">
                      <Bot className="size-5" />
                    </div>
                    <div className="flex flex-col items-start gap-1">
                      <div className="px-5 py-4 rounded-[1.5rem] bg-transparent">
                        <div className="flex space-x-1.5 items-center h-4">
                          <div className="size-2 animate-bounce rounded-full bg-primary/50 [animation-delay:-0.3s]"></div>
                          <div className="size-2 animate-bounce rounded-full bg-primary/50 [animation-delay:-0.15s]"></div>
                          <div className="size-2 animate-bounce rounded-full bg-primary/50"></div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </main>

      {/* Floating Bottom Input */}
      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-background via-background/95 to-transparent pb-6 pt-12">
        <div className="mx-auto max-w-3xl px-4 md:px-0">
          <form
            onSubmit={handleSendMessage}
            className="relative flex items-center overflow-hidden rounded-[2rem] border bg-background shadow-sm transition-all focus-within:ring-2 focus-within:ring-primary/20"
          >
            <Input
              placeholder="Tanya sesuatu ke agen..."
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              disabled={isTyping || !selectedAgentId}
              className="min-h-[56px] border-0 bg-transparent px-6 py-4 text-base shadow-none focus-visible:ring-0"
              autoComplete="off"
            />
            <Button
              type="submit"
              size="icon"
              disabled={!inputValue.trim() || isTyping || !selectedAgentId}
              className="mr-2 h-10 w-10 shrink-0 rounded-full transition-transform active:scale-95"
            >
              {isTyping ? (
                <Loader2 className="size-5 animate-spin" />
              ) : (
                <Send className="size-4 ml-0.5" />
              )}
            </Button>
          </form>
          <div className="mt-2 text-center text-[10px] text-muted-foreground">
            Agen dapat membuat kesalahan. Harap periksa informasi penting.
          </div>
        </div>
      </div>
    </div>
  );
}
