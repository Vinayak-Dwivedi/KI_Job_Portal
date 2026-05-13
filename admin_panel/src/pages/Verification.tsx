import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { collection, query, where, getDocs, updateDoc, doc } from "firebase/firestore";
import { Search, Loader2, CheckCircle, XCircle, FileIcon, Download, Eye, ExternalLink, AlertCircle, ShieldCheck } from "lucide-react";

import { db } from "@/lib/firebase";
import { type UserData } from "@/lib/api/users";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";

export default function Verification() {
  const queryClient = useQueryClient();
  const [searchQuery, setSearchQuery] = useState("");
  const [viewingUser, setViewingUser] = useState<any>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [isRejectDialogOpen, setIsRejectDialogOpen] = useState(false);

  const { data: pendingUsers, isLoading } = useQuery({
    queryKey: ["verifications_pending"],
    queryFn: async () => {
      const q = query(collection(db, "users"), where("isVerified", "==", false));
      const snapshot = await getDocs(q);
      const users: UserData[] = [];
      snapshot.forEach(docSnap => {
        const data = docSnap.data();
        // Only include users who actually have documents uploaded
        if (data.documents && data.documents.length > 0) {
          users.push({
            id: docSnap.id,
            name: data.name || data.fullName || "Unknown",
            email: data.email || "No Email",
            role: data.role || "user",
            isVerified: false,
            documents: data.documents || [],
            verificationStatus: data.verificationStatus || 'pending'
          } as any);
        }
      });
      return users;
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ userId, isVerified, reason }: { userId: string, isVerified: boolean, reason?: string }) => {
      const userRef = doc(db, "users", userId);
      await updateDoc(userRef, { 
        isVerified,
        verificationStatus: isVerified ? 'approved' : 'rejected',
        verificationNote: reason || ""
      });
      return true;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["verifications_pending"] });
      queryClient.invalidateQueries({ queryKey: ["users"] });
      setViewingUser(null);
      setIsRejectDialogOpen(false);
      setRejectionReason("");
    }
  });

  const handleExportPDF = () => {
    if (!pendingUsers) return;
    
    const columns = [
      { header: "User Name", dataKey: "name" },
      { header: "Email", dataKey: "email" },
      { header: "Role", dataKey: "role" },
      { header: "Status", dataKey: "status" },
    ];

    const exportData = pendingUsers.map(u => ({
      name: u.name,
      email: u.email,
      role: u.role,
      status: "Verification Pending",
    }));

    exportToPDF("Pending Verifications Snapshot", columns, exportData, "pending_verifications.pdf");
  };

  const filtered = pendingUsers?.filter(u => 
    u.name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
    u.email.toLowerCase().includes(searchQuery.toLowerCase())
  ) || [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Verification Management</h2>
          <p className="text-muted-foreground">Review and approve pending user verifications with immersive document preview.</p>
        </div>
        <Button onClick={handleExportPDF} variant="outline" className="gap-2 border-primary/20 hover:bg-primary/10">
          <Download className="w-4 h-4" /> Export Report
        </Button>
      </div>

      <Card className="glass-card">
        <CardHeader className="pb-3 border-b border-white/10 dark:border-white/5 mb-4">
          <div className="relative w-full max-w-sm">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input 
              placeholder="Search pending verifications..." 
              className="pl-9 h-10 w-full"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="py-20 flex justify-center"><Loader2 className="animate-spin text-primary w-8 h-8"/></div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent">
                  <TableHead>User</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Documents</TableHead>
                  <TableHead>Submission Date</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.length === 0 ? (
                  <TableRow>
                     <TableCell colSpan={5} className="text-center py-20 text-muted-foreground italic">
                        No pending verifications found.
                     </TableCell>
                  </TableRow>
                ) : (
                  filtered.map((user: any) => (
                    <TableRow key={user.id} className="group">
                      <TableCell>
                        <div className="font-medium text-sm">{user.name}</div>
                        <div className="text-xs text-muted-foreground">{user.email}</div>
                      </TableCell>
                      <TableCell><Badge variant="outline" className="capitalize text-[10px] tracking-wider">{user.role}</Badge></TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                           <Badge variant="secondary" className="bg-primary/10 text-primary border-none">
                              {user.documents?.length || 0} Files
                           </Badge>
                           <Button variant="ghost" size="sm" className="h-7 px-2 text-xs gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={() => setViewingUser(user)}>
                              <Eye className="w-3 h-3" /> Preview
                           </Button>
                        </div>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground italic">
                        Recent
                      </TableCell>
                      <TableCell className="text-right space-x-2">
                         <Button 
                           variant="outline" 
                           className="h-8 text-destructive hover:bg-destructive/10 hover:text-destructive border-destructive/20"
                           size="sm"
                           onClick={() => {
                             setViewingUser(user);
                             setIsRejectDialogOpen(true);
                           }}
                         >
                           <XCircle className="w-4 h-4 mr-1"/> Reject
                         </Button>
                         <Button 
                           variant="default" 
                           className="h-8 bg-green-600 hover:bg-green-700 text-white shadow-lg shadow-green-500/20"
                           size="sm"
                           onClick={() => updateMutation.mutate({ userId: user.id, isVerified: true })}
                         >
                           <CheckCircle className="w-4 h-4 mr-1"/> Approve
                         </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Document Viewer Modal */}
      <Dialog open={!!viewingUser && !isRejectDialogOpen} onOpenChange={() => setViewingUser(null)}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-hidden flex flex-col glass-card border-white/10">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
               <ShieldCheck className="w-5 h-5 text-primary" />
               Review Documents: {viewingUser?.name}
            </DialogTitle>
            <DialogDescription>
               Carefully examine the uploaded identification and certificates.
            </DialogDescription>
          </DialogHeader>

          <div className="flex-1 overflow-y-auto py-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {viewingUser?.documents?.map((doc: any, i: number) => (
                <div key={i} className="group relative rounded-xl border border-white/10 bg-white/5 overflow-hidden flex flex-col">
                  <div className="aspect-video bg-zinc-900 flex items-center justify-center relative">
                    {doc.url?.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
                      <img src={doc.url} alt={doc.name} className="object-contain w-full h-full" />
                    ) : (
                      <div className="flex flex-col items-center gap-2">
                        <FileIcon className="w-12 h-12 text-zinc-700" />
                        <span className="text-xs text-zinc-500">PDF or Document File</span>
                      </div>
                    )}
                    <a 
                      href={doc.url} 
                      target="_blank" 
                      rel="noreferrer" 
                      className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2 text-white font-medium"
                    >
                      <ExternalLink className="w-4 h-4" /> Open Original
                    </a>
                  </div>
                  <div className="p-4 flex flex-col gap-1">
                    <span className="text-[10px] uppercase tracking-widest text-primary font-black">
                      {doc.category || "General Document"}
                    </span>
                    <span className="font-bold text-sm truncate">{doc.name}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <DialogFooter className="border-t border-white/10 pt-4">
             <div className="flex w-full justify-between items-center">
               <div className="flex items-center gap-2 text-amber-500 text-xs">
                 <AlertCircle className="w-4 h-4" />
                 Verify name and photo match profile
               </div>
               <div className="flex gap-2">
                 <Button variant="outline" onClick={() => setIsRejectDialogOpen(true)}>Reject</Button>
                 <Button className="bg-green-600 hover:bg-green-700" onClick={() => updateMutation.mutate({ userId: viewingUser.id, isVerified: true })}>
                    Approve Verification
                 </Button>
               </div>
             </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Rejection Reason Modal */}
      <Dialog open={isRejectDialogOpen} onOpenChange={setIsRejectDialogOpen}>
        <DialogContent className="glass-card border-white/10">
          <DialogHeader>
            <DialogTitle className="text-destructive">Reject Verification</DialogTitle>
            <DialogDescription>
              Provide a reason for rejection. This will be visible to the user.
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
             <label className="text-sm font-medium mb-2 block">Rejection Note</label>
             <Textarea 
               placeholder="e.g. ID photo is blurry, document expired, etc."
               value={rejectionReason}
               onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setRejectionReason(e.target.value)}
               className="min-h-[120px]"
             />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsRejectDialogOpen(false)}>Cancel</Button>
            <Button 
              variant="destructive" 
              disabled={!rejectionReason || updateMutation.isPending}
              onClick={() => updateMutation.mutate({ userId: viewingUser.id, isVerified: false, reason: rejectionReason })}
            >
              {updateMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : "Confirm Rejection"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
