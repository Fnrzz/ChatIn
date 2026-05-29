"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Separator } from "@/components/ui/separator";
import { createClient } from "@/utils/supabase/client";
import { getUserProfile } from "@/services/user.service";
import { type UserProfile } from "@/types/user";
import { navItems } from "@/components/layout/nav-config";
import { SidebarBrand } from "@/components/layout/sidebar-brand";
import { SidebarNav } from "@/components/layout/sidebar-nav";
import { SidebarUserFooter } from "@/components/layout/sidebar-user-footer";

interface SidebarContentProps {
  pathname: string;
}

export function SidebarContent({ pathname }: SidebarContentProps) {
  const router = useRouter();
  const [user, setUser] = useState<UserProfile | null>(null);

  useEffect(() => {
    const fetchUser = async () => {
      const profile = await getUserProfile();
      if (profile) {
        setUser(profile);
      }
    };
    fetchUser();
  }, []);

  const handleLogout = async () => {
    try {
      const supabase = createClient();
      await supabase.auth.signOut();
      router.push("/login");
      router.refresh();
    } catch (error) {
      console.error("Gagal keluar:", error);
    }
  };

  return (
    <>
      <SidebarBrand />
      <Separator />
      <SidebarNav pathname={pathname} items={navItems} />
      <Separator />
      <SidebarUserFooter user={user} onLogout={handleLogout} />
    </>
  );
}
