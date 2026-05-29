"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Plus, Pencil, Trash2, Bot, Search, Loader2 } from "lucide-react";
import { type Agent, type InsertAgent } from "@/types/agent";
import { getAgents, createAgent, updateAgent, deleteAgent } from "@/services/agent.service";

const initialFormData: InsertAgent = {
  name: "",
  type: "specialist",
  description: "",
  system_prompt: "",
  status: "active",
};

export default function AgentsPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  
  const [searchQuery, setSearchQuery] = useState("");
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingAgentId, setEditingAgentId] = useState<string | null>(null);
  const [agentToDelete, setAgentToDelete] = useState<string | null>(null);

  const [formData, setFormData] = useState<InsertAgent>(initialFormData);

  const fetchAgents = async () => {
    setIsLoading(true);
    try {
      const data = await getAgents();
      setAgents(data);
    } catch (error) {
      console.error("Gagal mengambil data agen", error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAgents();
  }, []);

  const handleOpenAdd = () => {
    setEditingAgentId(null);
    setFormData(initialFormData);
    setIsDialogOpen(true);
  };

  const handleOpenEdit = (agent: Agent) => {
    setEditingAgentId(agent.id);
    setFormData({
      name: agent.name,
      type: agent.type,
      description: agent.description,
      system_prompt: agent.system_prompt,
      status: agent.status,
    });
    setIsDialogOpen(true);
  };

  const handleSaveAgent = async () => {
    if (!formData.name || !formData.system_prompt) return;
    
    setIsSubmitting(true);
    try {
      if (editingAgentId) {
        // Mode Edit
        const updatedAgent = await updateAgent(editingAgentId, formData);
        if (updatedAgent) {
          setAgents((prev) => 
            prev.map((a) => (a.id === editingAgentId ? { ...a, ...updatedAgent } : a))
          );
          setIsDialogOpen(false);
        }
      } else {
        // Mode Tambah Baru
        const newAgent = await createAgent(formData);
        if (newAgent) {
          setAgents((prev) => [newAgent, ...prev]);
          setIsDialogOpen(false);
        }
      }
    } catch (error) {
      console.error("Gagal menyimpan data agen", error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteAgent = async () => {
    if (!agentToDelete) return;
    
    setIsDeleting(agentToDelete);
    try {
      const success = await deleteAgent(agentToDelete);
      if (success) {
        setAgents((prev) => prev.filter((a) => a.id !== agentToDelete));
      }
    } catch (error) {
      console.error("Gagal menghapus agen", error);
    } finally {
      setIsDeleting(null);
      setAgentToDelete(null);
    }
  };

  const filteredAgents = agents.filter((agent) =>
    agent.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight">AI Agents</h1>
        <p className="text-muted-foreground">
          Kelola persona agen AI, konfigurasikan system prompt, dan atur detail
          karakter untuk masing-masing spesialis.
        </p>
      </div>

      <Separator />

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Total Agents</CardDescription>
            <CardTitle className="text-3xl">
              {isLoading ? <Loader2 className="size-6 animate-spin text-muted-foreground" /> : agents.length}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Active</CardDescription>
            <CardTitle className="text-3xl">
              {isLoading ? <Loader2 className="size-6 animate-spin text-muted-foreground" /> : agents.filter((a) => a.status === "active").length}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Knowledge Docs</CardDescription>
            <CardTitle className="text-3xl">
              {isLoading ? <Loader2 className="size-6 animate-spin text-muted-foreground" /> : agents.reduce((sum, a) => sum + (a.knowledgeCount || 0), 0)}
            </CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Toolbar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="relative max-w-sm flex-1">
          <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Cari agen..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-9"
          />
        </div>

        <Button onClick={handleOpenAdd}>
          <Plus className="mr-2 size-4" />
          Tambah Agen
        </Button>
      </div>

      {/* Form Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingAgentId ? "Edit Agen AI" : "Tambah Agen AI Baru"}</DialogTitle>
            <DialogDescription>
              {editingAgentId 
                ? "Perbarui persona dan system prompt untuk agen ini." 
                : "Buat persona agen baru dengan system prompt khusus."}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4 max-h-[65vh] overflow-y-auto px-2">
            <div className="space-y-2">
              <Label htmlFor="agent-name">Nama Agen</Label>
              <Input 
                id="agent-name" 
                placeholder="Contoh: Psikolog AI" 
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="agent-type">Tipe</Label>
              <Select 
                value={formData.type} 
                onValueChange={(value) => setFormData({...formData, type: value})}
              >
                <SelectTrigger id="agent-type">
                  <SelectValue placeholder="Pilih tipe agen" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="specialist">Specialist</SelectItem>
                  <SelectItem value="generalist">Generalist</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="agent-desc">Deskripsi Singkat</Label>
              <Input
                id="agent-desc"
                placeholder="Deskripsi singkat tentang agen ini"
                value={formData.description}
                onChange={(e) => setFormData({...formData, description: e.target.value})}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="agent-prompt">System Prompt</Label>
              <Textarea
                id="agent-prompt"
                placeholder="Masukkan instruksi system prompt untuk agen ini..."
                rows={5}
                value={formData.system_prompt}
                onChange={(e) => setFormData({...formData, system_prompt: e.target.value})}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="agent-status">Status</Label>
              <Select 
                value={formData.status} 
                onValueChange={(value) => setFormData({...formData, status: value})}
              >
                <SelectTrigger id="agent-status">
                  <SelectValue placeholder="Pilih status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="draft">Draft</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setIsDialogOpen(false)}
              disabled={isSubmitting}
            >
              Batal
            </Button>
            <Button onClick={handleSaveAgent} disabled={isSubmitting || !formData.name || !formData.system_prompt}>
              {isSubmitting ? <Loader2 className="mr-2 size-4 animate-spin" /> : null}
              {editingAgentId ? "Simpan Perubahan" : "Simpan Agen"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={agentToDelete !== null} onOpenChange={(open) => !open && setAgentToDelete(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Hapus Agen</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus agen ini? Tindakan ini tidak dapat dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-4">
            <Button
              variant="outline"
              onClick={() => setAgentToDelete(null)}
              disabled={isDeleting !== null}
            >
              Batal
            </Button>
            <Button 
              variant="destructive"
              onClick={handleDeleteAgent} 
              disabled={isDeleting !== null}
            >
              {isDeleting !== null ? <Loader2 className="mr-2 size-4 animate-spin" /> : <Trash2 className="mr-2 size-4" />}
              Hapus
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Agents Table */}
      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Agen</TableHead>
                <TableHead className="hidden sm:table-cell">Tipe</TableHead>
                <TableHead className="hidden md:table-cell">
                  Knowledge
                </TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="w-[100px] text-right">Aksi</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell colSpan={5} className="h-24 text-center">
                    <div className="flex flex-col items-center justify-center gap-2 text-muted-foreground">
                      <Loader2 className="size-6 animate-spin" />
                      <span>Memuat data...</span>
                    </div>
                  </TableCell>
                </TableRow>
              ) : filteredAgents.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="h-24 text-center">
                    <p className="text-muted-foreground">
                      Tidak ada agen ditemukan.
                    </p>
                  </TableCell>
                </TableRow>
              ) : (
                filteredAgents.map((agent) => (
                  <TableRow key={agent.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                          <Bot className="size-4" />
                        </div>
                        <div>
                          <p className="font-medium">{agent.name}</p>
                          <p className="hidden text-xs text-muted-foreground md:block truncate max-w-[200px] lg:max-w-[300px]">
                            {agent.description}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="hidden sm:table-cell">
                      <Badge variant="secondary" className="capitalize">
                        {agent.type}
                      </Badge>
                    </TableCell>
                    <TableCell className="hidden md:table-cell">
                      {agent.knowledgeCount || 0} docs
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          agent.status === "active" ? "default" : "secondary"
                        }
                        className="capitalize"
                      >
                        {agent.status}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button 
                          variant="ghost" 
                          size="icon-sm" 
                          onClick={() => handleOpenEdit(agent)}
                          disabled={isDeleting === agent.id || isSubmitting}
                        >
                          <Pencil className="size-3.5" />
                        </Button>
                        <Button 
                          variant="ghost" 
                          size="icon-sm" 
                          onClick={() => setAgentToDelete(agent.id)}
                          disabled={isDeleting === agent.id || isSubmitting}
                        >
                          <Trash2 className="size-3.5 text-destructive" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
