import { LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { type UserProfile } from "@/types/user";

interface SidebarUserFooterProps {
  user: UserProfile | null;
  onLogout: () => void;
}

function getInitials(name?: string): string {
  if (!name) return "AD";
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export function SidebarUserFooter({ user, onLogout }: SidebarUserFooterProps) {
  return (
    <div className="p-3">
      <div className="flex items-center gap-3 rounded-lg px-3 py-2">
        <Avatar className="size-8">
          <AvatarFallback className="text-xs">
            {getInitials(user?.displayName)}
          </AvatarFallback>
        </Avatar>
        <div className="flex-1 truncate">
          <p className="truncate text-sm font-medium">
            {user?.displayName || "Loading..."}
          </p>
          <p className="truncate text-xs text-muted-foreground">
            {user?.email || ""}
          </p>
        </div>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="ghost" size="icon-sm" onClick={onLogout}>
              <LogOut className="size-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Logout</TooltipContent>
        </Tooltip>
      </div>
    </div>
  );
}
