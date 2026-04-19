import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { QueryDocumentSnapshot } from "firebase/firestore";
import { Search, Loader2, CreditCard, Download, Edit3, CheckCircle, Clock } from "lucide-react";

import { fetchAllSubscriptions, updateUserSubscriptionTier } from "@/lib/api/payments";
import { collection, query, getDocs, orderBy, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Payments() {
  const queryClient = useQueryClient();
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedSub, setSelectedSub] = useState<any | null>(null);
  const [newTier, setNewTier] = useState("");
  const [isEditOpen, setIsEditOpen] = useState(false);

  const { data: subsData, isLoading, refetch } = useQuery({
    queryKey: ["subscriptions"],
    queryFn: () => fetchAllSubscriptions(lastDoc),
  });

  const { data: transactions, isLoading: isTransLoading } = useQuery({
    queryKey: ["transactions"],
    queryFn: async () => {
      const q = query(collection(db, "transactions"), orderBy("createdAt", "desc"), limit(10));
      const snaps = await getDocs(q);
      return snaps.docs.map(d => ({ id: d.id, ...d.data() }));
    }
  });

  const updateMutation = useMutation({
    mutationFn: async ({ uid, tier }: { uid: string, tier: string }) => {
      return updateUserSubscriptionTier(uid, tier);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["subscriptions"] });
      setIsEditOpen(false);
      setSelectedSub(null);
    }
  });

  const handleExportPDF = () => {
    if (!subsData?.subscriptions) return;
    
    const columns = [
      { header: "User ID", dataKey: "id" },
      { header: "Tier", dataKey: "currentTier" },
      { header: "Valid Until", dataKey: "expiry" },
      { header: "Apps/Day", dataKey: "maxApp" },
    ];

    const exportData = subsData.subscriptions.map(s => ({
      id: s.id,
      currentTier: s.currentTier?.toUpperCase() || "FREE",
      expiry: s.validUntil?.toDate ? s.validUntil.toDate().toLocaleDateString() : "N/A",
      maxApp: s.maxApplicationsPerDay || 0,
    }));

    exportToPDF("Subscription & Billing Ledger", columns, exportData, "financial_report.pdf");
  };

  const handleEdit = (sub: any) => {
    setSelectedSub(sub);
    setNewTier(sub.currentTier || "basic");
    setIsEditOpen(true);
  };

  const confirmUpdate = () => {
    if (!selectedSub || !newTier) return;
    updateMutation.mutate({ uid: selectedSub.id, tier: newTier });
  };

  const subscriptions = subsData?.subscriptions || [];
  const filteredSubs = subscriptions.filter(s => 
    s.id.toLowerCase().includes(searchQuery.toLowerCase()) || 
    s.currentTier?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Billing & Revenue</h2>
          <p className="text-muted-foreground">Manage user subscriptions, tiers, and financial reporting.</p>
        </div>
        <Button onClick={handleExportPDF} variant="outline" className="gap-2 border-primary/20 hover:bg-primary/10">
          <Download className="w-4 h-4" /> Export Financials
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="glass-card">
          <CardContent className="pt-6">
            <div className="flex items-center gap-4">
              <div className="bg-primary/10 p-3 rounded-xl"><CreditCard className="text-primary w-6 h-6"/></div>
              <div>
                <p className="text-sm text-muted-foreground font-medium">Total Subscribers</p>
                <h3 className="text-2xl font-bold">{subscriptions.length}</h3>
              </div>
            </div>
          </CardContent>
        </Card>
        {/* Placeholder for Revenue Stats if we had a transactions collection */}
      </div>

      <Card>
        <CardHeader className="pb-3 border-b border-white/10 dark:border-white/5 mb-4">
          <div className="relative w-full max-w-sm">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
            <Input 
              placeholder="Search by User ID or Tier..." 
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
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>User ID</TableHead>
                    <TableHead>Current Plan</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Valid Until</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredSubs.length === 0 ? (
                    <TableRow><TableCell colSpan={5} className="text-center py-10">No subscription records found.</TableCell></TableRow>
                  ) : (
                    filteredSubs.map((sub) => {
                      const isValid = sub.validUntil?.toDate ? sub.validUntil.toDate() > new Date() : false;
                      return (
                        <TableRow key={sub.id}>
                          <TableCell className="font-mono text-xs">{sub.id}</TableCell>
                          <TableCell>
                            <Badge variant="secondary" className="uppercase font-bold tracking-wider">{sub.currentTier || "Free"}</Badge>
                          </TableCell>
                          <TableCell>
                            {isValid ? (
                              <div className="flex items-center gap-1.5 text-green-500 text-xs font-medium">
                                <CheckCircle className="w-3.5 h-3.5"/> Active
                              </div>
                            ) : (
                              <div className="flex items-center gap-1.5 text-muted-foreground text-xs font-medium">
                                <Clock className="w-3.5 h-3.5"/> Expired
                              </div>
                            )}
                          </TableCell>
                          <TableCell className="text-sm">
                            {sub.validUntil?.toDate ? sub.validUntil.toDate().toLocaleDateString() : "Never"}
                          </TableCell>
                          <TableCell className="text-right">
                             <Button variant="ghost" size="sm" onClick={() => handleEdit(sub)} className="gap-2">
                               <Edit3 className="w-4 h-4" /> Manage
                             </Button>
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
              {subsData?.lastDoc && (
                <div className="mt-4 flex justify-center">
                   <Button variant="outline" onClick={() => { setLastDoc(subsData.lastDoc as any); setTimeout(() => refetch(), 0); }}>Load More</Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      <Card className="glass-card">
        <CardHeader>
           <CardTitle>Recent Transactions</CardTitle>
           <CardDescription>Latest payment activity across the platform.</CardDescription>
        </CardHeader>
        <CardContent>
           {isTransLoading ? (
             <div className="py-10 flex justify-center"><Loader2 className="animate-spin text-primary w-6 h-6"/></div>
           ) : (
             <Table>
               <TableHeader>
                 <TableRow>
                   <TableHead>Reference</TableHead>
                   <TableHead>User</TableHead>
                   <TableHead>Amount</TableHead>
                   <TableHead>Status</TableHead>
                   <TableHead className="text-right">Date</TableHead>
                 </TableRow>
               </TableHeader>
               <TableBody>
                 {transactions && transactions.length > 0 ? (
                   transactions.map((t: any) => (
                     <TableRow key={t.id}>
                       <TableCell className="font-mono text-[10px]">{t.id}</TableCell>
                       <TableCell className="text-xs">{t.userName || t.uid}</TableCell>
                       <TableCell className="font-bold">₹{t.amount || 0}</TableCell>
                       <TableCell>
                          <Badge variant={t.status === "success" ? "success" : "secondary"}>{t.status || "completed"}</Badge>
                       </TableCell>
                       <TableCell className="text-right text-xs">
                         {t.createdAt?.toDate ? t.createdAt.toDate().toLocaleDateString() : "Just now"}
                       </TableCell>
                     </TableRow>
                   ))
                 ) : (
                   <TableRow>
                     <TableCell colSpan={5} className="text-center py-10 text-muted-foreground italic">No transaction records found.</TableCell>
                   </TableRow>
                 )}
               </TableBody>
             </Table>
           )}
        </CardContent>
      </Card>

      <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Adjust Subscription</DialogTitle>
            <DialogDescription>Manually update the subscription tier for user: <b>{selectedSub?.id}</b></DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
             <div className="space-y-2">
                <label className="text-sm font-medium">Select Tier</label>
                <select 
                  className="w-full h-10 rounded-md border border-input bg-background px-3 py-2 text-sm glass"
                  value={newTier}
                  onChange={(e) => setNewTier(e.target.value)}
                >
                  <option value="basic">Basic (50 Credits, 10 Apps/Day)</option>
                  <option value="pro">Pro (150 Credits, 50 Apps/Day)</option>
                  <option value="elite">Elite (500 Credits, Unlimited Apps/Day)</option>
                  <option value="none">None (Revert to Free)</option>
                </select>
             </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditOpen(false)}>Cancel</Button>
            <Button onClick={confirmUpdate} disabled={updateMutation.isPending}>
              {updateMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : "Update Subscription"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
