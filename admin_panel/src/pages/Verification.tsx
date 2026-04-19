import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { collection, query, where, getDocs, updateDoc, doc } from "firebase/firestore";
import { Search, Loader2, CheckCircle, XCircle, FileIcon, Download } from "lucide-react";

import { db } from "@/lib/firebase";
import { type UserData } from "@/lib/api/users";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default function Verification() {
  const queryClient = useQueryClient();
  const [searchQuery, setSearchQuery] = useState("");

  const { data: pendingUsers, isLoading } = useQuery({
    queryKey: ["verifications_pending"],
    queryFn: async () => {
      // Assuming missing or false means pending in this context. 
      // Ideally we check for an explicit "pending" status if it was structured that way,
      // Here we filter for where isVerified == false in frontend if not indexed, or query natively.
      const q = query(collection(db, "users"), where("isVerified", "==", false));
      const snapshot = await getDocs(q);
      const users: UserData[] = [];
      snapshot.forEach(docSnap => {
        const data = docSnap.data();
        users.push({
          id: docSnap.id,
          name: data.name || data.fullName || "Unknown",
          email: data.email || "No Email",
          role: data.role || "user",
          isVerified: false,
          // documentUrl: data.documentUrl // Assume there might be some field for this
        });
      });
      return users;
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ userId, isVerified }: { userId: string, isVerified: boolean }) => {
      const userRef = doc(db, "users", userId);
      await updateDoc(userRef, { isVerified });
      return true;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["verifications_pending"] });
      queryClient.invalidateQueries({ queryKey: ["users"] });
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
          <p className="text-muted-foreground">Review and approve pending user verifications.</p>
        </div>
        <Button onClick={handleExportPDF} variant="outline" className="gap-2 border-primary/20 hover:bg-primary/10">
          <Download className="w-4 h-4" /> Export Report
        </Button>
      </div>

      <Card>
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
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Documents</TableHead>
                  <TableHead className="text-right">Decision</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.length === 0 ? (
                  <TableRow>
                     <TableCell colSpan={4} className="text-center py-10 text-muted-foreground">No pending verifications.</TableCell>
                  </TableRow>
                ) : (
                  filtered.map((user: any) => (
                    <TableRow key={user.id}>
                      <TableCell>
                        <div className="font-medium">{user.name}</div>
                        <div className="text-xs text-muted-foreground">{user.email}</div>
                      </TableCell>
                      <TableCell><Badge variant="outline" className="capitalize">{user.role}</Badge></TableCell>
                      <TableCell>
                        {user.documentUrl ? (
                          <a href={user.documentUrl} target="_blank" rel="noreferrer" className="flex items-center gap-2 text-primary hover:underline text-sm">
                            <FileIcon className="w-4 h-4"/> View Document
                          </a>
                        ) : (
                          <span className="text-xs text-muted-foreground italic">No document attached</span>
                        )}
                      </TableCell>
                      <TableCell className="text-right space-x-2">
                         <Button 
                           variant="outline" 
                           className="text-destructive hover:bg-destructive/10 hover:text-destructive border-destructive/20"
                           size="sm"
                           onClick={() => updateMutation.mutate({ userId: user.id, isVerified: false })} // Actually might want to set a 'rejected' status string if we expand schema
                         >
                           <XCircle className="w-4 h-4 mr-1"/> Reject
                         </Button>
                         <Button 
                           variant="default" 
                           className="bg-green-600 hover:bg-green-700 text-white"
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
    </div>
  );
}
