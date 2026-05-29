"use client";

import { useState, useEffect, useRef } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
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
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Upload,
  FileText,
  Search,
  Trash2,
  Database,
  Layers,
  HardDrive,
  Loader2,
  CheckCircle2,
} from "lucide-react";
import { type Agent } from "@/types/agent";
import { type KnowledgeDocument } from "@/types/knowledge";
import { getAgents } from "@/services/agent.service";
import {
  getKnowledgeDocuments,
  deleteKnowledgeDocument,
} from "@/services/knowledge.service";
import { processAndSaveDocument } from "@/app/actions/rag.actions";

export default function KnowledgeBasePage() {
  const [documents, setDocuments] = useState<KnowledgeDocument[]>([]);
  const [agents, setAgents] = useState<Agent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isUploading, setIsUploading] = useState(false);
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<KnowledgeDocument | null>(null);

  const [searchQuery, setSearchQuery] = useState("");
  const [isUploadOpen, setIsUploadOpen] = useState(false);

  // Upload form state
  const [selectedAgentId, setSelectedAgentId] = useState("");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadStatus, setUploadStatus] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const [docsData, agentsData] = await Promise.all([
        getKnowledgeDocuments(),
        getAgents(),
      ]);
      setDocuments(docsData);
      setAgents(agentsData);
    } catch (error) {
      console.error("Gagal memuat data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleUploadClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file) {
      setSelectedFile(file);
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
  };

  const resetUploadForm = () => {
    setSelectedAgentId("");
    setSelectedFile(null);
    setUploadStatus(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  const handleUploadAndProcess = async () => {
    if (!selectedFile || !selectedAgentId) return;

    setIsUploading(true);
    setUploadStatus("Mengunggah dan memulai proses...");

    try {
      const formData = new FormData();
      formData.append("file", selectedFile);
      formData.append("agentId", selectedAgentId);

      setUploadStatus("Memproses AI Embedding...");

      const result = await processAndSaveDocument(formData);

      if (result.success) {
        setUploadStatus(result.message || "Berhasil!");
        // Refresh table after short delay to show success message
        setTimeout(async () => {
          setIsUploadOpen(false);
          resetUploadForm();
          await fetchData();
        }, 1500);
      } else {
        setUploadStatus(null);
        console.error("Upload gagal:", result.error);
        alert(result.error || "Gagal memproses dokumen.");
      }
    } catch (error) {
      console.error("Error saat upload:", error);
      setUploadStatus(null);
      alert("Terjadi kesalahan saat memproses dokumen.");
    } finally {
      setIsUploading(false);
    }
  };

  const handleDeleteDocument = async () => {
    if (!deleteTarget) return;

    const key = `${deleteTarget.document_name}__${deleteTarget.agent_id}`;
    setIsDeleting(key);
    try {
      const success = await deleteKnowledgeDocument(
        deleteTarget.document_name,
        deleteTarget.agent_id
      );
      if (success) {
        setDocuments((prev) =>
          prev.filter(
            (d) =>
              !(
                d.document_name === deleteTarget.document_name &&
                d.agent_id === deleteTarget.agent_id
              )
          )
        );
      }
    } catch (error) {
      console.error("Gagal menghapus dokumen:", error);
    } finally {
      setIsDeleting(null);
      setDeleteTarget(null);
    }
  };

  const filteredDocs = documents.filter((doc) =>
    doc.document_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const formatDate = (dateStr: string) => {
    if (!dateStr) return "-";
    return new Date(dateStr).toLocaleDateString("id-ID", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Knowledge Base</h1>
        <p className="text-muted-foreground">
          Upload dokumen, lakukan proses chunking otomatis, dan generate vector
          embedding untuk memperkaya pengetahuan agen AI.
        </p>
      </div>

      <Separator />

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="flex items-center gap-2">
              <FileText className="size-4" />
              Total Dokumen
            </CardDescription>
            <CardTitle className="text-3xl">
              {isLoading ? (
                <Loader2 className="size-6 animate-spin text-muted-foreground" />
              ) : (
                documents.length
              )}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="flex items-center gap-2">
              <Layers className="size-4" />
              Total Chunks
            </CardDescription>
            <CardTitle className="text-3xl">
              {isLoading ? (
                <Loader2 className="size-6 animate-spin text-muted-foreground" />
              ) : (
                documents.reduce((sum, d) => sum + d.chunks, 0)
              )}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription className="flex items-center gap-2">
              <Database className="size-4" />
              Vector Embeddings
            </CardDescription>
            <CardTitle className="text-3xl">
              {isLoading ? (
                <Loader2 className="size-6 animate-spin text-muted-foreground" />
              ) : (
                documents
                  .filter((d) => d.status === "embedded")
                  .reduce((sum, d) => sum + d.chunks, 0)
              )}
            </CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="documents">
        <TabsList>
          <TabsTrigger value="documents">Dokumen</TabsTrigger>
          <TabsTrigger value="pipeline">RAG Pipeline</TabsTrigger>
        </TabsList>

        {/* Documents Tab */}
        <TabsContent value="documents" className="space-y-4">
          {/* Toolbar */}
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative max-w-sm flex-1">
              <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Cari dokumen..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>

            <Button onClick={() => { resetUploadForm(); setIsUploadOpen(true); }}>
              <Upload className="mr-2 size-4" />
              Upload Dokumen
            </Button>
          </div>

          {/* Upload Dialog */}
          <Dialog open={isUploadOpen} onOpenChange={(open) => { if (!isUploading) { setIsUploadOpen(open); if (!open) resetUploadForm(); } }}>
            <DialogContent className="max-w-lg">
              <DialogHeader>
                <DialogTitle>Upload Dokumen Baru</DialogTitle>
                <DialogDescription>
                  Upload file teks sebagai knowledge base untuk agen AI. Proses
                  chunking dan embedding akan berjalan otomatis.
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4 py-2">
                <div className="space-y-2">
                  <Label htmlFor="doc-agent">Agen Tujuan</Label>
                  <Select
                    value={selectedAgentId}
                    onValueChange={setSelectedAgentId}
                    disabled={isUploading}
                  >
                    <SelectTrigger id="doc-agent">
                      <SelectValue placeholder="Pilih agen tujuan" />
                    </SelectTrigger>
                    <SelectContent>
                      {agents.map((agent) => (
                        <SelectItem key={agent.id} value={agent.id}>
                          {agent.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="doc-file">File Dokumen</Label>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept=".txt,.md,.pdf"
                    className="hidden"
                    onChange={handleFileChange}
                    disabled={isUploading}
                  />
                  <div
                    className={`flex cursor-pointer items-center justify-center rounded-lg border-2 border-dashed p-8 transition-colors hover:border-primary/50 ${
                      selectedFile ? "border-primary/40 bg-primary/5" : ""
                    }`}
                    onClick={handleUploadClick}
                    onDrop={handleDrop}
                    onDragOver={handleDragOver}
                  >
                    <div className="text-center">
                      {selectedFile ? (
                        <>
                          <CheckCircle2 className="mx-auto size-8 text-primary" />
                          <p className="mt-2 text-sm font-medium">
                            {selectedFile.name}
                          </p>
                          <p className="mt-1 text-xs text-muted-foreground">
                            {(selectedFile.size / 1024).toFixed(1)} KB — Klik
                            untuk ganti file
                          </p>
                        </>
                      ) : (
                        <>
                          <HardDrive className="mx-auto size-8 text-muted-foreground" />
                          <p className="mt-2 text-sm font-medium">
                            Drag & drop file atau klik untuk memilih
                          </p>
                          <p className="mt-1 text-xs text-muted-foreground">
                            TXT, MD, PDF — Maks. 10 MB
                          </p>
                        </>
                      )}
                    </div>
                  </div>
                </div>

                {/* Upload Status */}
                {uploadStatus && (
                  <div className="flex items-center gap-2 rounded-lg border bg-muted/50 p-3 text-sm">
                    {isUploading ? (
                      <Loader2 className="size-4 shrink-0 animate-spin text-primary" />
                    ) : (
                      <CheckCircle2 className="size-4 shrink-0 text-green-500" />
                    )}
                    <span>{uploadStatus}</span>
                  </div>
                )}
              </div>
              <DialogFooter>
                <Button
                  variant="outline"
                  onClick={() => {
                    setIsUploadOpen(false);
                    resetUploadForm();
                  }}
                  disabled={isUploading}
                >
                  Batal
                </Button>
                <Button
                  onClick={handleUploadAndProcess}
                  disabled={
                    isUploading || !selectedFile || !selectedAgentId
                  }
                >
                  {isUploading ? (
                    <Loader2 className="mr-2 size-4 animate-spin" />
                  ) : (
                    <Upload className="mr-2 size-4" />
                  )}
                  {isUploading ? "Memproses..." : "Upload & Proses"}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>

          {/* Delete Confirmation Dialog */}
          <Dialog
            open={deleteTarget !== null}
            onOpenChange={(open) => !open && setDeleteTarget(null)}
          >
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>Hapus Dokumen</DialogTitle>
                <DialogDescription>
                  Apakah Anda yakin ingin menghapus dokumen{" "}
                  <strong>"{deleteTarget?.document_name}"</strong>? Semua chunk
                  dan embedding terkait akan dihapus. Tindakan ini tidak dapat
                  dibatalkan.
                </DialogDescription>
              </DialogHeader>
              <DialogFooter className="mt-4">
                <Button
                  variant="outline"
                  onClick={() => setDeleteTarget(null)}
                  disabled={isDeleting !== null}
                >
                  Batal
                </Button>
                <Button
                  variant="destructive"
                  onClick={handleDeleteDocument}
                  disabled={isDeleting !== null}
                >
                  {isDeleting !== null ? (
                    <Loader2 className="mr-2 size-4 animate-spin" />
                  ) : (
                    <Trash2 className="mr-2 size-4" />
                  )}
                  Hapus
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>

          {/* Documents Table */}
          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Dokumen</TableHead>
                    <TableHead className="hidden sm:table-cell">Agen</TableHead>
                    <TableHead className="hidden md:table-cell">
                      Chunks
                    </TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="w-[80px] text-right">Aksi</TableHead>
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
                  ) : filteredDocs.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="h-24 text-center">
                        <p className="text-muted-foreground">
                          Tidak ada dokumen ditemukan.
                        </p>
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredDocs.map((doc) => {
                      const key = `${doc.document_name}__${doc.agent_id}`;
                      return (
                        <TableRow key={key}>
                          <TableCell>
                            <div className="flex items-center gap-3">
                              <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                                <FileText className="size-4" />
                              </div>
                              <div>
                                <p className="font-medium">{doc.document_name}</p>
                                <p className="text-xs text-muted-foreground">
                                  {formatDate(doc.uploaded_at)}
                                </p>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell className="hidden sm:table-cell">
                            <Badge variant="secondary">{doc.agent_name}</Badge>
                          </TableCell>
                          <TableCell className="hidden md:table-cell">
                            {doc.chunks}
                          </TableCell>
                          <TableCell>
                            <Badge
                              variant={
                                doc.status === "embedded"
                                  ? "default"
                                  : "secondary"
                              }
                              className="capitalize"
                            >
                              {doc.status}
                            </Badge>
                          </TableCell>
                          <TableCell className="text-right">
                            <Button
                              variant="ghost"
                              size="icon-sm"
                              onClick={() => setDeleteTarget(doc)}
                              disabled={isDeleting === key}
                            >
                              {isDeleting === key ? (
                                <Loader2 className="size-3.5 animate-spin text-destructive" />
                              ) : (
                                <Trash2 className="size-3.5 text-destructive" />
                              )}
                            </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Pipeline Tab */}
        <TabsContent value="pipeline" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Alur Pemrosesan RAG</CardTitle>
              <CardDescription>
                Bagaimana dokumen diproses menjadi knowledge base siap pakai
                untuk agen AI.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {[
                  {
                    step: "1",
                    title: "Upload & Parsing",
                    desc: "Admin upload dokumen. Sistem mengekstrak teks dari file.",
                  },
                  {
                    step: "2",
                    title: "Chunking",
                    desc: "Teks dipecah menjadi bagian kecil yang bermakna secara otomatis.",
                  },
                  {
                    step: "3",
                    title: "Embedding",
                    desc: "Setiap chunk dikonversi menjadi vektor numerik via Sumopod API.",
                  },
                  {
                    step: "4",
                    title: "Retrieval",
                    desc: "Vektor disimpan di pgvector, siap dicari saat user bertanya.",
                  },
                ].map((item) => (
                  <div
                    key={item.step}
                    className="rounded-lg border p-4 text-center"
                  >
                    <div className="mx-auto mb-3 flex size-10 items-center justify-center rounded-full bg-primary text-sm font-bold text-primary-foreground">
                      {item.step}
                    </div>
                    <p className="font-medium">{item.title}</p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {item.desc}
                    </p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
