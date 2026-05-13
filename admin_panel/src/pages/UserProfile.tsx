import { useState } from "react";
import { useParams, Link } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { motion, AnimatePresence } from "framer-motion";
import { 
  ArrowLeft, Loader2, User, Mail, Phone, 
  Calendar, Briefcase, Activity, CheckCircle, 
  Ban, MapPin, Building, Save, 
  Download, ExternalLink, Trash2, Edit3
} from "lucide-react";

import { fetchUserDetail, fetchUserActivity } from "@/lib/api/user_profile";
import { updateUserStatus, type UserData } from "@/lib/api/users";
import { deletePostPermanently } from "@/lib/api/posts";
import { exportToPDF } from "@/lib/exportUtils";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

const TABS = [
  { id: "overview", label: "Overview", icon: User },
  { id: "activity", label: "Post History", icon: Activity },
  { id: "jobs", label: "Job Postings", icon: Briefcase },
];

export default function UserProfile() {
  const { uid } = useParams();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState("overview");
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState<Partial<UserData>>({});

  const { data: user, isLoading: userLoading } = useQuery({
    queryKey: ["user_detail", uid],
    queryFn: () => fetchUserDetail(uid!),
    enabled: !!uid,
  });

  const { data: activity, isLoading: activityLoading } = useQuery({
    queryKey: ["user_activity", uid],
    queryFn: () => fetchUserActivity(uid!),
    enabled: !!uid,
  });

  const updateMutation = useMutation({
    mutationFn: (data: Partial<UserData>) => updateUserStatus(uid!, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["user_detail", uid] });
      setIsEditing(false);
    }
  });

  const deletePostMutation = useMutation({
    mutationFn: (postId: string) => deletePostPermanently(postId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["user_activity", uid] });
    }
  });

  if (userLoading) {
    return (
      <div className="h-[80vh] flex flex-col items-center justify-center gap-4">
        <Loader2 className="w-12 h-12 animate-spin text-primary opacity-50" />
        <p className="text-muted-foreground animate-pulse">Syncing encrypted profile data...</p>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="h-[80vh] flex flex-col items-center justify-center space-y-4">
        <div className="p-6 rounded-3xl bg-destructive/10 border border-destructive/20 text-destructive">
          <Ban className="w-12 h-12 mx-auto mb-2" />
          <h2 className="text-2xl font-bold">User Not Found</h2>
          <p className="opacity-70">The requested profile does not exist or has been deleted.</p>
        </div>
        <Link to="/users">
          <Button variant="ghost" className="gap-2"><ArrowLeft className="w-4 h-4" /> Back to Directory</Button>
        </Link>
      </div>
    );
  }

  const handleStartEdit = () => {
    setFormData({
      name: user.name,
      email: user.email,
      phone: user.phone,
      credits: user.credits,
      role: user.role
    });
    setIsEditing(true);
  };

  const currentTabs = user.role === 'employer' ? TABS : TABS.filter(t => t.id !== 'jobs');

  return (
    <div className="max-w-[1400px] mx-auto space-y-8 pb-20">
      {/* Top Navigation Bar */}
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex items-center justify-between"
      >
        <div className="flex items-center gap-6">
          <Link to="/users">
            <Button variant="outline" size="icon" className="group rounded-2xl h-12 w-12 glass transition-all hover:w-28 overflow-hidden hover:bg-white/10">
              <div className="flex items-center gap-2 whitespace-nowrap px-3">
                <ArrowLeft className="w-5 h-5 transition-transform group-hover:-translate-x-1" />
                <span className="opacity-0 group-hover:opacity-100 transition-opacity font-medium">Back</span>
              </div>
            </Button>
          </Link>
          <div>
            <h2 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-white to-white/40 bg-clip-text text-transparent italic">
              User Core Index
            </h2>
            <div className="flex items-center gap-2 text-xs font-mono text-muted-foreground uppercase tracking-widest mt-1">
              <span className="text-primary/60">UID:</span>
              <span className="opacity-50">{uid}</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <Button variant="outline" className="glass rounded-2xl h-12 px-6 gap-2" onClick={() => exportToPDF(`${user.name} - Audit`, [], [], `audit_${uid}.pdf`)}>
            <Download className="w-4 h-4" /> Export Audit
          </Button>
          {!isEditing ? (
            <Button onClick={handleStartEdit} className="rounded-2xl h-12 px-6 gap-2 bg-primary shadow-lg shadow-primary/20 hover:scale-105 transition-transform">
              <Edit3 className="w-4 h-4" /> Modify Profile
            </Button>
          ) : (
            <Button onClick={() => updateMutation.mutate(formData)} disabled={updateMutation.isPending} className="rounded-2xl h-12 px-6 gap-2 bg-emerald-600 hover:bg-emerald-700">
              {updateMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              Commit Changes
            </Button>
          )}
        </div>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* SIDEBAR: Profile Identity Card */}
        <motion.div 
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.1 }}
          className="lg:col-span-4 space-y-6 lg:sticky lg:top-24"
        >
          <Card className="glass shadow-2xl border-none overflow-hidden relative group">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary/50 via-primary to-primary/50" />
            <CardContent className="pt-10 pb-8 space-y-8">
              <div className="flex flex-col items-center">
                <div className="relative mb-6">
                  <div className="h-32 w-32 rounded-[2.5rem] bg-gradient-to-br from-primary/20 to-primary/5 p-1">
                    <div className="h-full w-full rounded-[2.2rem] bg-background flex items-center justify-center border border-white/5 relative overflow-hidden group-hover:scale-105 transition-transform duration-500">
                      {user.profilePhotoUrl ? (
                        <img 
                          src={user.profilePhotoUrl} 
                          alt={user.name} 
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <User className="h-16 w-16 text-primary/40" />
                      )}
                      <div className="absolute inset-0 bg-gradient-to-tr from-primary/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                    </div>
                  </div>
                  {user.isVerified && (
                    <div className="absolute -bottom-2 -right-2 bg-background p-1 rounded-2xl border border-white/5 shadow-xl">
                      <div className="bg-emerald-500/20 p-2 rounded-xl text-emerald-500">
                        <CheckCircle className="w-5 h-5 fill-emerald-500/20" />
                      </div>
                    </div>
                  )}
                </div>

                <div className="text-center space-y-1">
                  <h3 className="text-2xl font-bold tracking-tight">{user.name}</h3>
                  <div className="flex items-center justify-center gap-2">
                    <Badge variant="outline" className="bg-primary/10 text-primary border-primary/20 uppercase tracking-tighter rounded-lg px-3">
                      {user.role}
                    </Badge>
                    {user.isBlocked && (
                      <Badge variant="destructive" className="uppercase tracking-tighter rounded-lg px-3">
                        Blocked
                      </Badge>
                    )}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 rounded-3xl bg-white/[0.03] border border-white/5 text-center space-y-1">
                   <p className="text-[10px] uppercase tracking-widest text-muted-foreground">Credits</p>
                   <p className="text-xl font-bold font-mono text-primary">{user.credits}</p>
                </div>
                <div className="p-4 rounded-3xl bg-white/[0.03] border border-white/5 text-center space-y-1">
                   <p className="text-[10px] uppercase tracking-widest text-muted-foreground">Activities</p>
                   <p className="text-xl font-bold font-mono">{activity?.posts.length || 0}</p>
                </div>
              </div>

              <div className="space-y-4 pt-4 border-t border-white/5">
                <div className="flex items-center gap-4 text-sm group/item cursor-default overflow-hidden">
                  <div className="h-10 w-10 min-w-10 rounded-xl bg-white/5 flex items-center justify-center group-hover/item:bg-primary/20 transition-colors">
                    <Mail className="w-4 h-4 text-primary/60" />
                  </div>
                  <span className="truncate text-muted-foreground group-hover/item:text-white transition-colors">{user.email}</span>
                </div>
                <div className="flex items-center gap-4 text-sm group/item cursor-default">
                  <div className="h-10 w-10 min-w-10 rounded-xl bg-white/5 flex items-center justify-center group-hover/item:bg-primary/20 transition-colors">
                    <Phone className="w-4 h-4 text-primary/60" />
                  </div>
                  <span className="text-muted-foreground group-hover/item:text-white transition-colors">{user.phone}</span>
                </div>
                <div className="flex items-center gap-4 text-sm group/item cursor-default">
                  <div className="h-10 w-10 min-w-10 rounded-xl bg-white/5 flex items-center justify-center group-hover/item:bg-primary/20 transition-colors">
                    <Calendar className="w-4 h-4 text-primary/60" />
                  </div>
                  <span className="text-muted-foreground group-hover/item:text-white transition-colors italic">
                    Joined {user.createdAt?.toDate ? user.createdAt.toDate().toLocaleDateString('en-US', { month: 'short', year: 'numeric' }) : 'Unknown'}
                  </span>
                </div>
              </div>

              <div className="pt-4 flex gap-2">
                 <Button 
                   variant="outline" 
                   className={`flex-1 rounded-2xl h-11 h-11 border-white/5 glass text-xs font-semibold uppercase tracking-tight ${user.isBlocked ? 'text-emerald-500' : 'text-destructive'}`}
                   onClick={() => updateMutation.mutate({ isBlocked: !user.isBlocked })}
                 >
                   {user.isBlocked ? 'Unblock' : 'Block User'}
                 </Button>
                 <Button 
                   variant="outline" 
                   className="flex-1 rounded-2xl h-11 border-white/5 glass text-xs font-semibold uppercase tracking-tight text-blue-400"
                   onClick={() => updateMutation.mutate({ isVerified: !user.isVerified })}
                 >
                   {user.isVerified ? 'Revoke' : 'Verify'}
                 </Button>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* MAIN CONTENT Area: Tabbed Dashboard */}
        <div className="lg:col-span-8 space-y-6">
          {/* CUSTOM ANIMATED TABS SWITCHER */}
          <div className="flex p-1.5 rounded-3xl bg-white/[0.03] border border-white/5 relative overflow-hidden glass backdrop-blur-2xl">
             <div className="flex w-full relative">
                {currentTabs.map((tab) => {
                  const isActive = activeTab === tab.id;
                  const Icon = tab.icon;
                  return (
                    <button
                      key={tab.id}
                      onClick={() => setActiveTab(tab.id)}
                      className={`relative flex-1 flex items-center justify-center gap-3 py-3 text-sm font-medium transition-colors duration-300 z-10 ${isActive ? 'text-white' : 'text-muted-foreground hover:text-white/60'}`}
                    >
                      <Icon className={`w-4 h-4 ${isActive ? 'text-primary' : 'opacity-40'}`} />
                      {tab.label}
                      {isActive && (
                        <motion.div
                          layoutId="activeTabBox"
                          className="absolute inset-0 bg-white/5 shadow-[0_0_20px_rgba(255,255,255,0.03)] rounded-2xl border border-white/5 z-[-1]"
                          transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                        />
                      )}
                    </button>
                  );
                })}
             </div>
          </div>

          <motion.div
            key={activeTab}
            initial={{ opacity: 0, scale: 0.98, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            transition={{ duration: 0.4, ease: "easeOut" }}
          >
            <AnimatePresence mode="wait">
              {activeTab === "overview" && (
                <div className="space-y-6">
                   <Card className="glass border-none shadow-none overflow-hidden">
                      <CardHeader className="border-b border-white/5 py-6">
                         <div className="flex items-center justify-between">
                            <div>
                               <CardTitle className="text-lg">User Metadata Overview</CardTitle>
                               <CardDescription>Primary account attributes and collection mapping.</CardDescription>
                            </div>
                         </div>
                      </CardHeader>
                      <CardContent className="p-8">
                         <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                            {isEditing ? (
                              <>
                                <div className="space-y-3">
                                  <label className="text-[10px] font-bold uppercase tracking-widest opacity-40">Display Name</label>
                                  <Input className="glass h-12 rounded-xl focus:ring-primary/50" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} />
                                </div>
                                <div className="space-y-3">
                                  <label className="text-[10px] font-bold uppercase tracking-widest opacity-40">System Email</label>
                                  <Input className="glass h-12 rounded-xl focus:ring-primary/50" value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} />
                                </div>
                                <div className="space-y-3">
                                  <label className="text-[10px] font-bold uppercase tracking-widest opacity-40">Phone Number</label>
                                  <Input className="glass h-12 rounded-xl focus:ring-primary/50" value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} />
                                </div>
                                <div className="space-y-3">
                                  <label className="text-[10px] font-bold uppercase tracking-widest opacity-40">Credit Pool</label>
                                  <Input className="glass h-12 rounded-xl focus:ring-primary/50" type="number" value={formData.credits} onChange={e => setFormData({...formData, credits: parseInt(e.target.value)})} />
                                </div>
                              </>
                            ) : (
                              <>
                                <div className="space-y-2">
                                  <p className="text-[10px] font-bold uppercase tracking-widest opacity-30">Bio / Profile Introduction</p>
                                  <p className="text-sm leading-relaxed opacity-80">{(user as any).bio || 'The user has not provided a biographical summary yet.'}</p>
                                </div>
                                <div className="space-y-4">
                                   <div className="space-y-2">
                                      <p className="text-[10px] font-bold uppercase tracking-widest opacity-30">Registered Location</p>
                                      <div className="flex items-center gap-3 py-3 px-4 rounded-2xl bg-white/[0.03] border border-white/5 text-sm">
                                         <MapPin className="w-4 h-4 text-primary/60" />
                                         {typeof (user as any).location === 'object' ? (user as any).location?.address : (user as any).location || 'Geo-data unavailable'}
                                      </div>
                                   </div>
                                   {user.role === 'worker' && (
                                     <>
                                       <div className="space-y-2">
                                          <p className="text-[10px] font-bold uppercase tracking-widest opacity-30">Skill Inventory</p>
                                          <div className="flex flex-wrap gap-2">
                                            {((user as any).skills || []).length > 0 
                                              ? (user as any).skills.map((s: string) => <Badge key={s} variant="outline" className="rounded-lg border-white/10 glass bg-white/5">{s}</Badge>) 
                                              : <span className="text-xs text-muted-foreground italic">No specialized skills listed.</span>
                                            }
                                          </div>
                                       </div>
                                       <div className="space-y-2 mt-4">
                                          <p className="text-[10px] font-bold uppercase tracking-widest opacity-30">Verification Details</p>
                                            <div className="p-3 rounded-2xl bg-white/5 border border-white/5">
                                              <span className="opacity-50 text-[10px] block uppercase font-bold tracking-widest mb-1">Aadhaar Verification</span>
                                              <span className="text-primary font-mono">{(user as any).aadhaarNumber || 'NOT PROVIDED'}</span>
                                            </div>
                                            <div className="p-3 rounded-2xl bg-white/5 border border-white/5">
                                              <span className="opacity-50 text-[10px] block uppercase font-bold tracking-widest mb-1">Gender / Nationality</span>
                                              <span>{(user as any).gender || 'N/A'} • {(user as any).nationality || 'N/A'}</span>
                                            </div>
                                            <div className="p-3 rounded-2xl bg-white/5 border border-white/5">
                                              <span className="opacity-50 text-[10px] block uppercase font-bold tracking-widest mb-1">Emergency Contact</span>
                                              <span>{(user as any).emergencyContact || 'N/A'}</span>
                                            </div>
                                            <div className="p-3 rounded-2xl bg-white/5 border border-white/5 col-span-2">
                                              <span className="opacity-50 text-[10px] block uppercase font-bold tracking-widest mb-1">Permanent Address</span>
                                              <span className="text-xs opacity-80">{(user as any).permanentAddress || 'N/A'}</span>
                                            </div>
                                       </div>
                                     </>
                                   )}
                                   {user.role === 'employer' && (
                                     <>
                                       <div className="space-y-2">
                                          <p className="text-[10px] font-bold uppercase tracking-widest opacity-30">Corporate Entity</p>
                                          <div className="flex items-center gap-3 py-3 px-4 rounded-2xl bg-white/[0.03] border border-white/5 text-sm">
                                             <Building className="w-4 h-4 text-emerald-500/60" />
                                             {(user as any).companyName || 'Private Professional'}
                                          </div>
                                       </div>
                                       <div className="space-y-2 mt-4">
                                          <p className="text-[10px] font-bold uppercase tracking-widest opacity-30">Verification Details</p>
                                          <div className="grid grid-cols-2 gap-4 text-sm pt-2">
                                            <div>
                                              <span className="opacity-50 text-[10px] block uppercase">Reg. Number</span>
                                              <span>{(user as any).companyRegistrationNumber || 'N/A'}</span>
                                            </div>
                                            <div>
                                              <span className="opacity-50 text-[10px] block uppercase">GST Number</span>
                                              <span>{(user as any).gstNumber || 'N/A'}</span>
                                            </div>
                                          </div>
                                       </div>
                                     </>
                                   )}
                                </div>
                              </>
                            )}
                         </div>
                      </CardContent>
                   </Card>
                </div>
              )}

              {activeTab === "activity" && (
                <div className="grid grid-cols-1 gap-4">
                   {activityLoading ? (
                     <div className="py-20 flex flex-col items-center justify-center gap-4">
                        <Loader2 className="animate-spin text-primary opacity-50" />
                        <span className="text-xs font-mono opacity-40 uppercase tracking-widest">Hydrating social index...</span>
                     </div>
                   ) : activity?.posts.length === 0 ? (
                     <div className="py-24 text-center glass rounded-[2.5rem] border-dashed border-2 border-white/5">
                        <Activity className="w-10 h-10 mx-auto opacity-10 mb-2" />
                        <p className="text-muted-foreground italic">Spectral profile. No post history detected.</p>
                     </div>
                   ) : (
                     <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {activity?.posts.map((post, idx) => (
                          <motion.div 
                            key={post.id} 
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: idx * 0.05 }}
                            className="p-5 rounded-[2rem] bg-white/[0.03] border border-white/5 flex flex-col justify-between hover:bg-white/[0.05] hover:border-white/10 transition-all group"
                          >
                             <div className="space-y-4">
                                <div className="flex justify-between items-start">
                                   <Badge variant="outline" className="rounded-lg border-white/10 text-[9px] uppercase tracking-widest opacity-50">{post.type || 'Standard'}</Badge>
                                   <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                      <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:bg-destructive/10" onClick={() => deletePostMutation.mutate(post.id)}>
                                         <Trash2 className="w-3.5 h-3.5" />
                                      </Button>
                                   </div>
                                </div>
                                <p className="text-sm leading-relaxed opacity-90 line-clamp-3">{post.displayContent || <span className="italic opacity-40">Attachment only post</span>}</p>
                             </div>
                             <div className="flex justify-between items-center pt-6">
                                <span className="text-[10px] font-mono opacity-30">{post.createdAt?.toDate ? post.createdAt.toDate().toLocaleString() : 'Recent'}</span>
                                <Button variant="ghost" size="sm" className="h-8 rounded-xl gap-2 text-[10px] uppercase tracking-widest opacity-40 hover:opacity-100 transition-opacity">
                                   View <ExternalLink className="w-3 h-3" />
                                </Button>
                             </div>
                          </motion.div>
                        ))}
                     </div>
                   )}
                </div>
              )}

              {activeTab === "jobs" && (
                <Card className="glass border-none shadow-none overflow-hidden">
                   <CardContent className="p-0">
                      {activityLoading ? (
                        <div className="py-20 flex justify-center"><Loader2 className="animate-spin text-primary opacity-50" /></div>
                      ) : activity?.jobs.length === 0 ? (
                        <div className="py-24 text-center italic text-muted-foreground opacity-50 font-mono text-sm tracking-widest">
                           NULL POINTER. NO EMPLOYER LISTINGS.
                        </div>
                      ) : (
                        <Table>
                           <TableHeader className="bg-white/[0.02]">
                              <TableRow className="border-white/5 hover:bg-transparent">
                                 <TableHead className="font-mono text-[10px] uppercase tracking-widest py-4 pl-8">Job Architecture</TableHead>
                                 <TableHead className="font-mono text-[10px] uppercase tracking-widest py-4">Budget / Salary</TableHead>
                                 <TableHead className="font-mono text-[10px] uppercase tracking-widest py-4">Location</TableHead>
                                 <TableHead className="font-mono text-[10px] uppercase tracking-widest py-4">State</TableHead>
                                 <TableHead className="font-mono text-[10px] uppercase tracking-widest py-4 text-right pr-8">Link</TableHead>
                              </TableRow>
                           </TableHeader>
                           <TableBody>
                              {activity?.jobs.map((job) => (
                                 <TableRow key={job.id} className="border-white/5 hover:bg-white/[0.02] group transition-colors">
                                    <TableCell className="font-medium py-6 pl-8">
                                       <div className="flex flex-col">
                                          <span>{job.jobTitle || job.title}</span>
                                          <span className="text-[10px] opacity-40 uppercase tracking-tighter mt-1">{job.jobExperience || 'Standard Experience'}</span>
                                       </div>
                                    </TableCell>
                                    <TableCell className="font-mono text-emerald-500 text-sm">
                                       {job.jobSalary || 'Negotiable'}
                                    </TableCell>
                                    <TableCell className="text-xs opacity-60">
                                       {typeof job.location === 'object' ? job.location?.address : job.location}
                                    </TableCell>
                                    <TableCell>
                                       <Badge className={`rounded-lg uppercase text-[9px] tracking-widest border-none ${job.hiringStatus === 'active' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-white/5 text-muted-foreground'}`}>
                                          {job.hiringStatus || 'active'}
                                       </Badge>
                                    </TableCell>
                                    <TableCell className="text-right pr-8">
                                       <Button variant="ghost" size="icon" className="group-hover:text-primary transition-colors"><ExternalLink className="w-4 h-4"/></Button>
                                    </TableCell>
                                 </TableRow>
                              ))}
                           </TableBody>
                        </Table>
                      )}
                   </CardContent>
                </Card>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
