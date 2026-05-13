import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Link, useSearchParams } from "react-router-dom";
import { QueryDocumentSnapshot } from "firebase/firestore";
import { Search, Loader2, CheckCircle, Ban, Download, Edit3, ExternalLink, Plus, ShieldAlert, MessageSquare, MessageCircle } from "lucide-react";

import { fetchUsers, updateUserStatus, registerAdminAccount, fetchActiveWorkConnections, type UserData } from "@/lib/api/users";
import { sendMessageToUser } from "@/lib/api/chats";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { cn } from "@/lib/utils";

export default function Users() {
  const queryClient = useQueryClient();
  const [searchParams] = useSearchParams();
  const filterParam = searchParams.get("filter");
  
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState(filterParam === "unverified" ? "unverified" : "all");
  const [searchQuery, setSearchQuery] = useState("");

  // Sync statusFilter if param changes
  useEffect(() => {
    if (filterParam === "unverified") {
      setStatusFilter("unverified");
    }
  }, [filterParam]);
  const [selectedUser, setSelectedUser] = useState<UserData | null>(null);
  const [actionType, setActionType] = useState<"block" | "unblock" | "verify" | "edit" | null>(null);
  const [showRegisterAdmin, setShowRegisterAdmin] = useState(false);
  const [adminForm, setAdminForm] = useState({ name: "", email: "", phone: "" });
  const [editForm, setEditForm] = useState<Partial<UserData>>({});
  const [showMessageDialog, setShowMessageDialog] = useState(false);
  const [messageText, setMessageText] = useState("");
  const [isSendingMessage, setIsSendingMessage] = useState(false);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["users", roleFilter],
    queryFn: () => fetchUsers(lastDoc, roleFilter),
  });

  const { data: connections } = useQuery({
    queryKey: ["active_connections"],
    queryFn: fetchActiveWorkConnections,
  });

  const updateMutation = useMutation({
    mutationFn: async ({ userId, data }: { userId: string, data: Partial<UserData> }) => {
      return updateUserStatus(userId, data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      setSelectedUser(null);
    }
  });

  const registerAdminMutation = useMutation({
    mutationFn: async (data: { name: string, email: string, phone: string }) => {
      return registerAdminAccount(data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
      setShowRegisterAdmin(false);
      setAdminForm({ name: "", email: "", phone: "" });
    }
  });

  const handleAction = (user: UserData, action: "block" | "unblock" | "verify" | "edit") => {
    setSelectedUser(user);
    setActionType(action);
    if (action === "edit") {
      setEditForm({
        name: user.name,
        email: user.email,
        phone: user.phone,
        credits: user.credits,
        role: user.role
      });
    }
  };

  const confirmAction = () => {
    if (!selectedUser || !actionType) return;
    
    let updateData = {};
    if (actionType === "block") updateData = { isBlocked: true };
    if (actionType === "unblock") updateData = { isBlocked: false };
    if (actionType === "verify") updateData = { isVerified: true };
    if (actionType === "edit") updateData = editForm;

    updateMutation.mutate({ userId: selectedUser.id, data: updateData });
  };

  const handleRegisterAdmin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!adminForm.name || !adminForm.email || !adminForm.phone) return;
    registerAdminMutation.mutate(adminForm);
  };

  const handleSendMessage = async () => {
    if (!selectedUser || !messageText.trim()) return;
    
    setIsSendingMessage(true);
    try {
      await sendMessageToUser(
        selectedUser.id, 
        selectedUser.name || "User", 
        selectedUser.profilePhotoUrl || "", 
        messageText
      );
      setShowMessageDialog(false);
      setMessageText("");
      setSelectedUser(null);
    } catch (error) {
      console.error(error);
    } finally {
      setIsSendingMessage(false);
    }
  };

  const handleExportPDF = () => {
    if (!data?.users) return;
    
    const columns = [
      { header: "Name", dataKey: "name" },
      { header: "Email", dataKey: "email" },
      { header: "Role", dataKey: "role" },
      { header: "Verified", dataKey: "isVerified" },
      { header: "Status", dataKey: "status" },
      { header: "Tokens", dataKey: "credits" },
      { header: "Active Work", dataKey: "activeWork" },
    ];

    const exportData = data.users.map(u => ({
      name: u.name,
      email: u.email,
      role: u.role,
      isVerified: u.isVerified ? "Yes" : "No",
      status: u.isBlocked ? "Blocked" : "Active",
      credits: u.credits || 0,
      activeWork: connections ? (connections[u.id] ? connections[u.id].join(', ') : 'None') : 'Loading...',
    }));

    exportToPDF("User Management Report", columns, exportData, "users_report.pdf");
  };

  const users = data?.users || [];

  // Client side search and status filter
  const filteredUsers = users.filter(u => {
    const matchesSearch = u.name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          u.email.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === "all" || (statusFilter === "unverified" && !u.isVerified);
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6 max-w-[1400px] mx-auto pb-12">
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold tracking-tight font-serif italic text-primary">User Cluster <span className="text-zinc-400 not-italic">Management</span></h2>
          <p className="text-zinc-500 dark:text-zinc-400">Moderating roles, verifications, and institutional access.</p>
        </div>
        <div className="flex gap-3">
          <Button onClick={() => setShowRegisterAdmin(true)} className="gap-2 emerald-gradient text-white font-bold h-11 px-6 shadow-lg hover:scale-[1.02] transition-all">
            <Plus className="w-4 h-4" /> Add Admin
          </Button>
          <Button onClick={handleExportPDF} variant="outline" className="gap-2 h-11 px-6 border-zinc-200 dark:border-zinc-800">
            <Download className="w-4 h-4" /> Export
          </Button>
        </div>
      </div>

      <Card className="no-line-card p-1">
        <CardHeader className="pb-3 border-b border-white/5 mb-4">
          <div className="flex flex-wrap gap-4 items-center justify-between">
            <div className="relative w-full max-w-sm">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input 
                placeholder="Search institutional records..." 
                className="pl-9 h-10 w-full bg-zinc-50 dark:bg-zinc-950/40 border-none shadow-inner"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex gap-2">
              <select 
                className="h-10 rounded-md border-none bg-zinc-50 dark:bg-zinc-950/40 px-3 py-2 text-sm font-bold shadow-inner focus:outline-none cursor-pointer"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
              >
                <option value="all">All Status</option>
                <option value="unverified">Pending Verification</option>
              </select>
              <select 
                className="h-10 rounded-md border-none bg-zinc-50 dark:bg-zinc-950/40 px-3 py-2 text-sm font-bold shadow-inner focus:outline-none cursor-pointer"
                value={roleFilter}
                onChange={(e) => {
                  setRoleFilter(e.target.value);
                  setLastDoc(null); 
                  setTimeout(() => refetch(), 0);
                }}
              >
                <option value="all">Global (All Roles)</option>
                <option value="worker">Verified Workers</option>
                <option value="employer">Registered Employers</option>
                <option value="admin">System Admins</option>
              </select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="py-20 flex flex-col items-center gap-4">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
              <p className="text-sm font-medium text-zinc-400">Accessing secure database...</p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow className="border-white/5 hover:bg-transparent uppercase tracking-widest text-[10px] font-black text-zinc-500">
                    <TableHead>User Profile</TableHead>
                    <TableHead>Privilege Level</TableHead>
                    <TableHead>Auth Status</TableHead>
                    <TableHead>State</TableHead>
                    <TableHead>Units</TableHead>
                    <TableHead>Active Work</TableHead>
                    <TableHead className="text-right">Administration</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredUsers.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center py-20 text-muted-foreground italic font-serif">
                        No historical records found for this cluster.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredUsers.map((user) => (
                      <TableRow key={user.id} className="border-white/5 hover:bg-zinc-50/50 dark:hover:bg-zinc-900/40 transition-colors">
                        <TableCell>
                          <div className="flex flex-col">
                            <Link to={`/users/${user.id}`} className="font-bold text-zinc-900 dark:text-zinc-100 hover:text-primary hover:underline transition-colors flex items-center gap-1">
                              {user.name} <ExternalLink className="w-3 h-3 opacity-30" />
                            </Link>
                            <span className="text-xs text-zinc-400 font-mono tracking-tighter">{user.email}</span>
                            <span className="text-[10px] text-zinc-500 font-bold">{user.phone}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={user.role === 'admin' ? "default" : "outline"} className={cn(
                            "capitalize font-black tracking-wider text-[10px] px-2 py-0.5",
                            user.role === 'admin' ? "bg-primary/20 text-primary border-none shadow-sm" : ""
                          )}>
                            {user.role}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {user.isVerified ? (
                            <Badge variant="success" className="gap-1 text-[10px] font-bold"><CheckCircle className="w-3 h-3"/> Verified</Badge>
                          ) : (
                            <Badge variant="secondary" className="text-[10px] font-bold">Pending</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          {user.isBlocked ? (
                            <Badge variant="destructive" className="gap-1 text-[10px] font-bold"><Ban className="w-3 h-3"/> Restricted</Badge>
                          ) : (
                            <Badge className="bg-emerald-500/10 text-emerald-500 border-none text-[10px] font-bold">Active</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <span className="font-mono font-black text-sm text-zinc-600 dark:text-zinc-400">{user.credits || 0}</span>
                        </TableCell>
                        <TableCell>
                          {connections && connections[user.id] && connections[user.id].length > 0 ? (
                            <div className="flex flex-col gap-1 max-w-[150px]">
                              {user.role === 'employer' ? <span className="text-[10px] font-bold text-zinc-500 uppercase">Hired:</span> : <span className="text-[10px] font-bold text-zinc-500 uppercase">Working with:</span>}
                              <div className="flex flex-wrap gap-1">
                                {connections[user.id].map(name => (
                                  <Badge key={name} variant="secondary" className="text-[9px] px-1 py-0">{name}</Badge>
                                ))}
                              </div>
                            </div>
                          ) : (
                            <span className="text-xs text-zinc-500 italic">None</span>
                          )}
                        </TableCell>
                        <TableCell className="text-right space-x-1">
                          {!user.isVerified && (
                             <Button variant="ghost" size="sm" onClick={() => handleAction(user, "verify")} className="text-emerald-500 font-bold hover:bg-emerald-500/10">AUTHENTICATE</Button>
                          )}
                          {user.isBlocked ? (
                             <Button variant="ghost" size="sm" onClick={() => handleAction(user, "unblock")} className="text-primary font-bold">RESTORE</Button>
                          ) : (
                             <Button variant="ghost" size="sm" onClick={() => handleAction(user, "block")} className="text-destructive font-bold hover:bg-destructive/10">DISABLE</Button>
                          )}
                          <Link to={`/chats?userId=${user.id}`}>
                            <Button variant="ghost" size="sm" className="hover:bg-primary/10">
                              <MessageCircle className="w-4 h-4 text-primary" />
                            </Button>
                          </Link>
                          <Button variant="ghost" size="sm" onClick={() => { setSelectedUser(user); setShowMessageDialog(true); }} className="hover:bg-zinc-100 dark:hover:bg-zinc-800">
                            <MessageSquare className="w-4 h-4 text-zinc-400" />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => handleAction(user, "edit")} className="hover:bg-zinc-100 dark:hover:bg-zinc-800">
                            <Edit3 className="w-4 h-4 text-zinc-400" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
              
              {/* Load More Pagination */}
              {data?.lastDoc && (
                <div className="mt-8 flex justify-center">
                   <Button 
                     variant="outline" 
                     className="rounded-xl px-8 h-11 font-bold border-zinc-200 dark:border-zinc-800 shadow-sm"
                     onClick={() => {
                        setLastDoc(data.lastDoc as QueryDocumentSnapshot);
                        setTimeout(() => refetch(), 0);
                     }}
                   >
                     Sequence More Records
                   </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Confirmation/Edit Dialog */}
      <Dialog open={!!selectedUser} onOpenChange={() => setSelectedUser(null)}>
        <DialogContent className={actionType === "edit" ? "max-w-2xl no-line-card p-1" : "no-line-card p-1"}>
          <div className="p-6">
            <DialogHeader>
              <DialogTitle className="text-2xl font-serif">{actionType === "edit" ? "Modify Institutional Node" : "Confirm Protocol"}</DialogTitle>
              <DialogDescription className="text-base mt-2">
                {actionType === "edit" ? (
                  "Adjust profile parameters and permission levels for this node."
                ) : (
                  <>Are you sure you want to {actionType} <span className="font-bold text-foreground">{selectedUser?.name}</span>? This change propagates immediately.</>
                )}
              </DialogDescription>
            </DialogHeader>

            {actionType === "edit" ? (
              <div className="grid grid-cols-2 gap-6 py-8">
                 <div className="space-y-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500">Legal Name</label>
                    <Input value={editForm.name} onChange={(e) => setEditForm({...editForm, name: e.target.value})} className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-12 shadow-inner" />
                 </div>
                 <div className="space-y-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500">Node Email</label>
                    <Input value={editForm.email} onChange={(e) => setEditForm({...editForm, email: e.target.value})} className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-12 shadow-inner" />
                 </div>
                 <div className="space-y-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500">Telecom Contact</label>
                    <Input value={editForm.phone} onChange={(e) => setEditForm({...editForm, phone: e.target.value})} className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-12 shadow-inner" />
                 </div>
                  <div className="space-y-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500">Credit Allocations</label>
                    <Input 
                      type="number" 
                      value={editForm.credits ?? 0} 
                      onChange={(e) => {
                        const val = parseInt(e.target.value);
                        setEditForm({...editForm, credits: isNaN(val) ? 0 : val});
                      }} 
                      className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-12 shadow-inner" 
                    />
                  </div>
                 <div className="space-y-2 col-span-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-zinc-500">Permission Role</label>
                    <select 
                       className="w-full h-12 rounded-xl border-none bg-zinc-50 dark:bg-zinc-950/40 px-4 text-sm font-bold shadow-inner"
                       value={editForm.role}
                       onChange={(e) => setEditForm({...editForm, role: e.target.value})}
                    >
                      <option value="worker">Verified Worker</option>
                      <option value="employer">Registered Employer</option>
                      <option value="admin">System Administrator</option>
                    </select>
                 </div>
              </div>
            ) : null}

            <DialogFooter className="mt-4 gap-3">
              <Button variant="outline" onClick={() => setSelectedUser(null)} className="h-12 px-8 rounded-xl">Cancel</Button>
              <Button 
                 variant={actionType === "block" ? "destructive" : "default"} 
                 className="h-12 px-10 rounded-xl font-bold"
                 onClick={confirmAction}
                 disabled={updateMutation.isPending}
              >
                {updateMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : "Authorize Change"}
              </Button>
            </DialogFooter>
          </div>
        </DialogContent>
      </Dialog>

      {/* Register Admin Dialog */}
      <Dialog open={showRegisterAdmin} onOpenChange={setShowRegisterAdmin}>
        <DialogContent className="no-line-card p-1 max-w-lg">
          <div className="p-8">
            <DialogHeader className="mb-8">
              <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mb-4">
                <ShieldAlert className="w-8 h-8 text-primary" />
              </div>
              <DialogTitle className="text-3xl font-serif">Provision <span className="text-primary italic">Admin</span></DialogTitle>
              <DialogDescription className="text-base mt-2">
                Register a new administrator node within the KI institutional infrastructure.
              </DialogDescription>
            </DialogHeader>

            <form onSubmit={handleRegisterAdmin} className="space-y-6">
               <div className="space-y-2">
                  <label className="text-[11px] font-black uppercase tracking-[0.1em] text-zinc-500">Administrator Name</label>
                  <Input 
                    placeholder="e.g. Alexander Pierce"
                    value={adminForm.name} 
                    onChange={(e) => setAdminForm({...adminForm, name: e.target.value})} 
                    className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-14 shadow-inner text-lg font-serif"
                    required 
                  />
               </div>
               <div className="space-y-2">
                  <label className="text-[11px] font-black uppercase tracking-[0.1em] text-zinc-500">Official Email</label>
                  <Input 
                    type="email"
                    placeholder="admin@kiportal.com"
                    value={adminForm.email} 
                    onChange={(e) => setAdminForm({...adminForm, email: e.target.value})} 
                    className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-14 shadow-inner"
                    required 
                  />
               </div>
               <div className="space-y-2">
                  <label className="text-[11px] font-black uppercase tracking-[0.1em] text-zinc-500">Secure Telecom Contact</label>
                  <Input 
                    placeholder="+91 XXXXX XXXXX"
                    value={adminForm.phone} 
                    onChange={(e) => setAdminForm({...adminForm, phone: e.target.value})} 
                    className="bg-zinc-50 dark:bg-zinc-950/40 border-none h-14 shadow-inner"
                    required 
                  />
               </div>

               <div className="pt-4 flex gap-4">
                 <Button type="button" variant="ghost" onClick={() => setShowRegisterAdmin(false)} className="flex-1 h-14 font-bold border border-zinc-200 dark:border-zinc-800 rounded-xl">Discard</Button>
                 <Button 
                   type="submit" 
                   className="flex-[2] h-14 text-lg font-black shadow-2xl hover:scale-[1.02] active:scale-[0.98] transition-all"
                   disabled={registerAdminMutation.isPending}
                 >
                   {registerAdminMutation.isPending ? <Loader2 className="w-6 h-6 animate-spin" /> : "PROVISION ACCESS"}
                 </Button>
               </div>
            </form>
          </div>
        </DialogContent>
      </Dialog>
      {/* Message Dialog */}
      <Dialog open={showMessageDialog} onOpenChange={(open) => { if (!open) setShowMessageDialog(false); if (!open) setSelectedUser(null); }}>
        <DialogContent className="no-line-card p-1 max-w-lg">
          <div className="p-8">
            <DialogHeader className="mb-6">
              <DialogTitle className="text-2xl font-serif">Message <span className="text-primary italic">{selectedUser?.name}</span></DialogTitle>
              <DialogDescription>
                Send a direct secure message to this user's mobile application.
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4">
              <textarea 
                className="w-full h-40 rounded-xl border-none bg-zinc-50 dark:bg-zinc-950/40 p-4 text-sm font-medium shadow-inner focus:outline-none resize-none"
                placeholder="Type your message here..."
                value={messageText}
                onChange={(e) => setMessageText(e.target.value)}
              />
              
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => { setShowMessageDialog(false); setSelectedUser(null); }} className="flex-1 h-12 rounded-xl">Cancel</Button>
                <Button 
                  onClick={handleSendMessage} 
                  className="flex-[2] h-12 rounded-xl font-bold emerald-gradient text-white"
                  disabled={isSendingMessage || !messageText.trim()}
                >
                  {isSendingMessage ? <Loader2 className="w-4 h-4 animate-spin" /> : "SEND MESSAGE"}
                </Button>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
