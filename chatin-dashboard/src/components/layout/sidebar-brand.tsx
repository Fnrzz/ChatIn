import { Bot } from "lucide-react";

export function SidebarBrand() {
  return (
    <div className="flex h-14 items-center gap-2 px-4">
      <div className="flex size-8 items-center justify-center rounded-xl bg-primary text-primary-foreground">
        <Bot className="size-4" />
      </div>
      <div className="flex flex-col">
        <span className="text-sm font-semibold">ChatIn</span>
        <span className="text-[10px] leading-tight text-muted-foreground">
          Control Center
        </span>
      </div>
    </div>
  );
}
