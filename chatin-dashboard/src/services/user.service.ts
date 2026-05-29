import { createClient } from "@/utils/supabase/client";
import { type UserProfile } from "@/types/user";


export async function getUserProfile(): Promise<UserProfile | null> {
  try {
    const supabase = createClient();

    // 1. Pastikan user sedang login
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return null;
    }

    // 2. Ambil data SECARA EKSKLUSIF dari tabel profiles
    const { data: profile, error: dbError } = await supabase
      .from("profiles")
      .select("display_name, role")
      .eq("id", user.id)
      .maybeSingle();

    if (dbError) {
      console.error("Gagal mengambil data dari profil:", dbError.message);
    }

    // 3. Kembalikan data yang rapi
    return {
      email: user.email || "",
      // Prioritaskan nama dari database. Jika NULL di database, gunakan nama depan dari email
      displayName:
        profile?.display_name || user.email?.split("@")[0] || "Admin",
      // Prioritaskan role dari database.
      role: profile?.role || "user",
    };
  } catch (error) {
    console.error("Error pada getUserProfile service:", error);
    return null;
  }
}
