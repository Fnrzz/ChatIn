"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { createClient } from "@/utils/supabase/client";
import { Trash2, Plus, Image as ImageIcon, Loader2 } from "lucide-react";

type DefaultAvatar = {
  id: string;
  name: string;
  image_url: string;
  created_at: string;
};

export default function AvatarsPage() {
  const [avatars, setAvatars] = useState<DefaultAvatar[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isUploading, setIsUploading] = useState(false);
  const [isDeleting, setIsDeleting] = useState<string | null>(null);

  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [newAvatarName, setNewAvatarName] = useState("");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  const supabase = createClient();

  useEffect(() => {
    fetchAvatars();
  }, []);

  const fetchAvatars = async () => {
    setIsLoading(true);
    try {
      const { data, error } = await supabase
        .from("default_avatars")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) throw error;
      setAvatars(data || []);
    } catch (error: any) {
      alert(`Gagal memuat avatar: ${error.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpload = async () => {
    if (!newAvatarName || !selectedFile) {
      alert("Data tidak lengkap: Mohon isi nama karakter dan pilih file gambar.");
      return;
    }

    setIsUploading(true);
    try {
      // 1. Upload file to storage
      const fileExt = selectedFile.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2, 15)}_${Date.now()}.${fileExt}`;
      const filePath = `avatars/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from("avatars")
        .upload(fileName, selectedFile);

      if (uploadError) throw uploadError;

      // 2. Get Public URL
      const { data: publicUrlData } = supabase.storage
        .from("avatars")
        .getPublicUrl(fileName);

      const publicUrl = publicUrlData.publicUrl;

      // 3. Insert into database
      const { error: dbError } = await supabase
        .from("default_avatars")
        .insert({
          name: newAvatarName,
          image_url: publicUrl,
        });

      if (dbError) throw dbError;

      alert("Berhasil: Avatar baru berhasil ditambahkan.");

      setIsAddDialogOpen(false);
      setNewAvatarName("");
      setSelectedFile(null);
      fetchAvatars();
    } catch (error: any) {
      alert(`Gagal mengunggah avatar: ${error.message}`);
    } finally {
      setIsUploading(false);
    }
  };

  const handleDelete = async (id: string, imageUrl: string) => {
    if (!confirm("Apakah Anda yakin ingin menghapus avatar ini?")) return;

    setIsDeleting(id);
    try {
      // 1. Delete from database
      const { error: dbError } = await supabase
        .from("default_avatars")
        .delete()
        .eq("id", id);

      if (dbError) throw dbError;

      // 2. Optionally delete from storage if we can parse the filename
      try {
        const urlObj = new URL(imageUrl);
        const parts = urlObj.pathname.split('/');
        const fileName = parts[parts.length - 1];
        if (fileName) {
          await supabase.storage.from("avatars").remove([fileName]);
        }
      } catch (e) {
        // ignore storage delete errors
      }

      alert("Berhasil: Avatar berhasil dihapus.");
      fetchAvatars();
    } catch (error: any) {
      alert(`Gagal menghapus avatar: ${error.message}`);
    } finally {
      setIsDeleting(null);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Default Avatars</h1>
          <p className="text-muted-foreground">
            Kelola pilihan gambar profil karakter untuk pengguna aplikasi.
          </p>
        </div>
        <Button onClick={() => setIsAddDialogOpen(true)}>
          <Plus className="mr-2 size-4" />
          Tambah Avatar
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {isLoading ? (
          <div className="col-span-full flex items-center justify-center p-12">
            <Loader2 className="size-8 animate-spin text-muted-foreground" />
          </div>
        ) : avatars.length === 0 ? (
          <div className="col-span-full rounded-lg border border-dashed p-12 text-center">
            <ImageIcon className="mx-auto mb-4 size-12 text-muted-foreground opacity-50" />
            <h3 className="mb-1 text-lg font-medium">Belum ada avatar</h3>
            <p className="text-sm text-muted-foreground">
              Klik "Tambah Avatar" untuk mengunggah karakter baru.
            </p>
          </div>
        ) : (
          avatars.map((avatar) => (
            <Card key={avatar.id} className="overflow-hidden">
              <div className="aspect-square w-full bg-muted/50 p-6">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={avatar.image_url}
                  alt={avatar.name}
                  className="size-full rounded-full border-4 border-background object-cover shadow-sm"
                />
              </div>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-semibold">{avatar.name}</h3>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="text-destructive hover:bg-destructive/10 hover:text-destructive"
                    onClick={() => handleDelete(avatar.id, avatar.image_url)}
                    disabled={isDeleting === avatar.id}
                  >
                    {isDeleting === avatar.id ? (
                      <Loader2 className="size-4 animate-spin" />
                    ) : (
                      <Trash2 className="size-4" />
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Tambah Avatar Karakter</DialogTitle>
            <DialogDescription>
              Unggah gambar karakter baru untuk digunakan oleh pengguna sebagai foto profil mereka.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Nama Karakter</Label>
              <Input
                id="name"
                placeholder="Misal: Robot Biru"
                value={newAvatarName}
                onChange={(e) => setNewAvatarName(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="image">File Gambar</Label>
              <Input
                id="image"
                type="file"
                accept="image/*"
                onChange={(e) => setSelectedFile(e.target.files?.[0] || null)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
              Batal
            </Button>
            <Button onClick={handleUpload} disabled={isUploading}>
              {isUploading ? (
                <>
                  <Loader2 className="mr-2 size-4 animate-spin" />
                  Mengunggah...
                </>
              ) : (
                "Simpan Avatar"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
