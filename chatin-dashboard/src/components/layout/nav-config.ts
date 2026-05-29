import { Users, BookOpen, MessageSquare } from "lucide-react";
import { type NavItem } from "@/types/navigation";

export const navItems: NavItem[] = [
  {
    title: "AI Agents",
    href: "/agents",
    icon: Users,
    description: "Kelola persona dan system prompt agen AI",
  },
  {
    title: "Knowledge Base",
    href: "/knowledge-base",
    icon: BookOpen,
    description: "Upload dokumen dan manajemen RAG",
  },
  {
    title: "Chat Playground",
    href: "/chat",
    icon: MessageSquare,
    description: "Simulator untuk menguji agen dan RAG",
  },
];
