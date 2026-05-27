import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { QueryDocumentSnapshot } from "firebase/firestore";
import { Search, Loader2, Eye, EyeOff, Trash2, Download, MessageSquare, Heart, ImageIcon, Check, X, Calendar, Filter, MapPin, Edit3 } from "lucide-react";
import { fetchPosts, updatePostStatus, deletePostPermanently, approvePostEdit, rejectPostEdit, type PostData } from "@/lib/api/posts";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Checkbox } from "@/components/ui/checkbox";

export default function Posts() {
  const queryClient = useQueryClient();
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
  const [filter, setFilter] = useState<"all" | "jobs" | "social">("all");
  const [statusFilter, setStatusFilter] = useState<"all" | "pending" | "approved" | "rejected">("all");
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedPost, setSelectedPost] = useState<PostData | null>(null);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [actionType, setActionType] = useState<"hide" | "show" | "delete" | "approve" | "reject" | "bulk_approve" | "bulk_reject" | "bulk_delete" | "approve_edit" | "reject_edit" | null>(null);
  const [reviewEditPost, setReviewEditPost] = useState<PostData | null>(null);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["posts", filter, statusFilter, startDate, endDate],
    queryFn: () => fetchPosts(
      lastDoc, 
      filter, 
      statusFilter, 
      startDate ? new Date(startDate) : undefined, 
      endDate ? new Date(endDate + 'T23:59:59') : undefined
    ),
  });

  const updateMutation = useMutation({
    mutationFn: async ({ postId, data, ownerUid }: { postId: string, data: Partial<PostData>, ownerUid?: string }) => {
      return updatePostStatus(postId, data, ownerUid);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["posts"] });
      setSelectedPost(null);
      setSelectedIds([]);
      setActionType(null);
    }
  });

  const approveEditMutation = useMutation({
    mutationFn: async ({ postId, ownerUid }: { postId: string, ownerUid?: string }) => {
      return approvePostEdit(postId, ownerUid);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["posts"] });
      setReviewEditPost(null);
      setActionType(null);
    }
  });

  const rejectEditMutation = useMutation({
    mutationFn: async ({ postId, ownerUid }: { postId: string, ownerUid?: string }) => {
      return rejectPostEdit(postId, ownerUid);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["posts"] });
      setReviewEditPost(null);
      setActionType(null);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async ({ postId, ownerUid }: { postId: string, ownerUid?: string }) => {
      return deletePostPermanently(postId, ownerUid);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["posts"] });
      setSelectedPost(null);
      setSelectedIds([]);
      setActionType(null);
    }
  });

  const handleExportPDF = () => {
    if (!data?.posts) return;
    
    const columns = [
      { header: "Author", dataKey: "name" },
      { header: "Role", dataKey: "role" },
      { header: "Content", dataKey: "text" },
      { header: "Type", dataKey: "type" },
      { header: "Stats", dataKey: "stats" },
      { header: "Status", dataKey: "status" },
    ];

    const exportData = data.posts.map(p => ({
      name: p.name,
      role: p.role,
      text: p.text.substring(0, 50) + (p.text.length > 50 ? "..." : ""),
      type: p.isJobPost ? "Job" : p.isAvailabilityPost ? "Availability" : p.eventTitle ? "Event" : "Social",
      stats: `${p.likes} Likes, ${p.comments} Comments`,
      status: p.isHidden ? "Hidden" : "Public",
    }));

    exportToPDF("Unified Feed Content Log", columns, exportData, "feed_moderation_report.pdf");
  };

  const toggleSelectAll = () => {
    if (selectedIds.length === filteredPosts.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(filteredPosts.map(p => p.id));
    }
  };

  const toggleSelect = (id: string) => {
    setSelectedIds(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  const [previewPost, setPreviewPost] = useState<PostData | null>(null);

  const confirmAction = async () => {
    if (actionType?.startsWith("bulk_")) {
      const ids = [...selectedIds];
      for (const id of ids) {
        const post = posts.find(p => p.id === id);
        if (!post) continue;
        
        if (actionType === "bulk_delete") {
          await deleteMutation.mutateAsync({ postId: id, ownerUid: post.uid });
        } else if (actionType === "bulk_approve") {
          await updateMutation.mutateAsync({ postId: id, data: { status: "approved" }, ownerUid: post.uid });
        } else if (actionType === "bulk_reject") {
          await updateMutation.mutateAsync({ postId: id, data: { status: "rejected" }, ownerUid: post.uid });
        }
      }
    } else if (selectedPost && actionType) {
      if (actionType === "delete") {
        deleteMutation.mutate({ 
          postId: selectedPost.id, 
          ownerUid: selectedPost.uid 
        });
      } else if (actionType === "approve") {
        updateMutation.mutate({ 
          postId: selectedPost.id, 
          data: { status: "approved" },
          ownerUid: selectedPost.uid
        });
      } else if (actionType === "reject") {
        updateMutation.mutate({ 
          postId: selectedPost.id, 
          data: { status: "rejected" },
          ownerUid: selectedPost.uid
        });
      } else if (actionType === "approve_edit") {
        approveEditMutation.mutate({ 
          postId: selectedPost.id, 
          ownerUid: selectedPost.uid
        });
      } else if (actionType === "reject_edit") {
        rejectEditMutation.mutate({ 
          postId: selectedPost.id, 
          ownerUid: selectedPost.uid
        });
      } else {
        updateMutation.mutate({ 
          postId: selectedPost.id, 
          data: { isHidden: actionType === "hide" },
          ownerUid: selectedPost.uid
        });
      }
    }
  };

  const posts = data?.posts || [];
  const filteredPosts = posts.filter(p => 
    p.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
    p.text.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Post Moderation</h2>
          <p className="text-muted-foreground">Manage unified feed posts and social content with advanced tools.</p>
        </div>
        <div className="flex gap-2">
          {selectedIds.length > 0 && (
            <div className="flex items-center gap-2 mr-4 px-4 py-1.5 bg-primary/10 rounded-full border border-primary/20 animate-in zoom-in duration-200">
               <span className="text-xs font-bold text-primary">{selectedIds.length} Selected</span>
               <div className="h-4 w-[1px] bg-primary/20 mx-1" />
               <Button size="sm" variant="ghost" className="h-7 text-green-500 hover:text-green-600 hover:bg-green-500/10" onClick={() => setActionType("bulk_approve")}>Approve</Button>
               <Button size="sm" variant="ghost" className="h-7 text-orange-500 hover:text-orange-600 hover:bg-orange-500/10" onClick={() => setActionType("bulk_reject")}>Reject</Button>
               <Button size="sm" variant="ghost" className="h-7 text-red-500 hover:text-red-600 hover:bg-red-500/10" onClick={() => setActionType("bulk_delete")}>Delete</Button>
            </div>
          )}
          <Button onClick={handleExportPDF} variant="outline" className="gap-2 border-primary/20 hover:bg-primary/10">
            <Download className="w-4 h-4" /> Download Report
          </Button>
        </div>
      </div>

      <Card className="glass-card">
        <CardHeader className="pb-6 border-b border-white/10 dark:border-white/5 mb-4">
          <div className="space-y-4">
            <div className="flex flex-wrap gap-4 items-center justify-between">
              <div className="relative w-full max-w-sm">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input 
                  placeholder="Search post content or author..." 
                  className="pl-9 h-10 w-full"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <div className="flex flex-wrap gap-2">
                <div className="flex items-center gap-2 bg-white/5 px-3 py-1.5 rounded-md border border-white/10">
                  <Calendar className="w-4 h-4 text-muted-foreground" />
                  <input 
                    type="date" 
                    className="bg-transparent text-sm outline-none w-28" 
                    value={startDate}
                    onChange={(e) => { setStartDate(e.target.value); setLastDoc(null); }}
                  />
                  <span className="text-muted-foreground">to</span>
                  <input 
                    type="date" 
                    className="bg-transparent text-sm outline-none w-28" 
                    value={endDate}
                    onChange={(e) => { setEndDate(e.target.value); setLastDoc(null); }}
                  />
                  {(startDate || endDate) && (
                    <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => { setStartDate(""); setEndDate(""); setLastDoc(null); }}>
                      <X className="w-3 h-3" />
                    </Button>
                  )}
                </div>

                <select 
                  className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm glass"
                  value={filter}
                  onChange={(e) => {
                    setFilter(e.target.value as any);
                    setLastDoc(null);
                  }}
                >
                  <option value="all">All Types</option>
                  <option value="social">Social Only</option>
                  <option value="jobs">Job Posts Only</option>
                </select>
                <select 
                  className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm glass"
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value as any);
                    setLastDoc(null);
                  }}
                >
                  <option value="all">All Status</option>
                  <option value="pending">Pending</option>
                  <option value="approved">Approved</option>
                  <option value="rejected">Rejected</option>
                </select>
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="py-20 flex justify-center">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                   <TableRow className="hover:bg-transparent">
                    <TableHead className="w-12">
                       <Checkbox 
                        checked={selectedIds.length === filteredPosts.length && filteredPosts.length > 0}
                        onCheckedChange={toggleSelectAll}
                       />
                    </TableHead>
                    <TableHead>Author</TableHead>
                    <TableHead className="max-w-[250px]">Content</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Date & Time</TableHead>
                    <TableHead>Engagement</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredPosts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-20 text-muted-foreground italic">
                         No posts found for current filters.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredPosts.map((post) => (
                      <TableRow key={post.id} className={`${post.isHidden ? "opacity-50" : ""} transition-opacity`}>
                        <TableCell>
                           <Checkbox 
                            checked={selectedIds.includes(post.id)}
                            onCheckedChange={() => toggleSelect(post.id)}
                           />
                        </TableCell>
                        <TableCell>
                          <div className="flex flex-col">
                            <span className="font-medium text-sm">{post.name}</span>
                            <span className="text-[10px] text-muted-foreground uppercase tracking-wider">{post.role}</span>
                          </div>
                        </TableCell>
                        <TableCell className="max-w-[250px]">
                          <div className="flex items-start gap-2">
                            {(post.imageUrl || (post.media && post.media.length > 0)) && (
                               <div className="mt-1 flex-shrink-0 bg-primary/10 p-1.5 rounded-lg border border-primary/20">
                                  {post.media?.some(m => m.type === 'video') ? (
                                     <div className="relative">
                                        <ImageIcon className="w-3.5 h-3.5 text-primary opacity-30" />
                                        <div className="absolute inset-0 flex items-center justify-center">
                                           <div className="w-1.5 h-1.5 bg-primary rounded-full animate-pulse" />
                                        </div>
                                     </div>
                                  ) : (
                                     <ImageIcon className="w-3.5 h-3.5 text-primary" />
                                  )}
                               </div>
                            )}
                            <p className="text-sm line-clamp-2 leading-relaxed">{post.text}</p>
                          </div>
                        </TableCell>
                         <TableCell>
                            {post.isJobPost ? (
                              <Badge variant="outline" className="text-blue-500 border-blue-500/20 bg-blue-500/5">Job</Badge>
                            ) : post.isAvailabilityPost ? (
                               <Badge variant="outline" className="text-amber-500 border-amber-500/20 bg-amber-500/5">Available</Badge>
                            ) : post.eventTitle ? (
                               <Badge variant="outline" className="text-purple-500 border-purple-500/20 bg-purple-500/5">Event</Badge>
                            ) : (
                               <Badge variant="secondary" className="bg-white/5 border-none">Social</Badge>
                            )}
                         </TableCell>
                         <TableCell>
                            <div className="flex flex-col">
                              <span className="text-xs font-medium">
                                 {post.createdAt?.toDate ? post.createdAt.toDate().toLocaleDateString() : 'N/A'}
                              </span>
                              <span className="text-[10px] text-muted-foreground">
                                 {post.createdAt?.toDate ? post.createdAt.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}
                              </span>
                            </div>
                         </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-3 text-[10px] text-muted-foreground">
                            <span className="flex items-center gap-1"><Heart className="w-3 h-3 text-red-500/50"/> {post.likes}</span>
                            <span className="flex items-center gap-1"><MessageSquare className="w-3 h-3 text-blue-500/50"/> {post.comments}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          {post.hasPendingEdit ? (
                            <Badge variant="outline" className="text-blue-500 border-blue-500/30 bg-blue-500/5 cursor-help" title="This post has an unapproved edit">
                              Edit Pending
                            </Badge>
                          ) : post.status === 'pending' ? (
                            <Badge variant="outline" className="text-orange-500 border-orange-500/30 bg-orange-500/5 animate-pulse">Pending</Badge>
                          ) : post.status === 'rejected' ? (
                            <Badge variant="destructive" className="bg-red-500/10 text-red-500 border-red-500/20">Rejected</Badge>
                          ) : post.isHidden ? (
                            <Badge variant="secondary" className="bg-zinc-500/10 text-zinc-500 border-zinc-500/20">Hidden</Badge>
                          ) : (
                            <Badge variant="success" className="bg-green-500/10 text-green-500 border-green-500/20">Approved</Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-right space-x-1">
                          <div className="flex justify-end items-center gap-1">
                             {post.hasPendingEdit && (
                               <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  className="h-8 w-8 text-blue-500 hover:bg-blue-500/10"
                                  onClick={() => setReviewEditPost(post)}
                                  title="Review Pending Edit"
                               >
                                  <Edit3 className="w-4 h-4" />
                               </Button>
                             )}
                             <Button 
                                variant="ghost" 
                                size="icon" 
                                className="h-8 w-8 text-primary hover:bg-primary/10"
                                onClick={() => setPreviewPost(post)}
                                title="Preview Post"
                             >
                                <Eye className="w-4 h-4" />
                             </Button>

                            {post.status === 'pending' ? (
                              <>
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => {
                                    setSelectedPost(post);
                                    setActionType("approve");
                                  }}
                                  className="h-8 w-8 text-green-500 hover:bg-green-500/10"
                                >
                                  <Check className="w-4 h-4" />
                                </Button>
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => {
                                    setSelectedPost(post);
                                    setActionType("reject");
                                  }}
                                  className="h-8 w-8 text-red-500 hover:bg-red-500/10"
                                >
                                  <X className="w-4 h-4" />
                                </Button>
                              </>
                            ) : (
                              <Button 
                                variant="ghost" 
                                size="icon" 
                                className="h-8 w-8"
                                onClick={() => {
                                  setSelectedPost(post);
                                  setActionType(post.isHidden ? "show" : "hide");
                                }}
                              >
                                {post.isHidden ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4 text-orange-500" />}
                              </Button>
                            )}
                            <Button 
                              variant="ghost" 
                              size="icon" 
                              onClick={() => {
                                setSelectedPost(post);
                                setActionType("delete");
                              }}
                              className="h-8 w-8 text-destructive hover:bg-destructive/10"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
              {data?.lastDoc && (
                <div className="mt-6 flex justify-center">
                   <Button variant="outline" className="rounded-full px-8" onClick={() => { setLastDoc(data.lastDoc as any); setTimeout(() => refetch(), 0); }}>
                     Load More Content
                   </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* POST PREVIEW DIALOG */}
      <Dialog open={!!previewPost} onOpenChange={() => setPreviewPost(null)}>
        <DialogContent className="max-w-md p-0 overflow-hidden bg-zinc-950 border-white/10 rounded-[2.5rem]">
           <div className="relative">
              {/* Profile Header */}
              <div className="p-6 flex items-center gap-4">
                 <div className="h-12 w-12 rounded-2xl bg-primary/20 flex items-center justify-center overflow-hidden border border-white/10">
                    {previewPost?.profilePhotoUrl ? (
                       <img src={previewPost.profilePhotoUrl} className="h-full w-full object-cover" />
                    ) : (
                       <span className="text-xl font-bold text-primary">{previewPost?.name[0]}</span>
                    )}
                 </div>
                 <div className="flex-1">
                    <div className="flex items-center gap-2">
                       <h4 className="font-bold text-white">{previewPost?.name}</h4>
                       {previewPost?.isVerified && <Check className="w-4 h-4 fill-primary text-black bg-primary rounded-full p-0.5" />}
                    </div>
                    <p className="text-[10px] text-muted-foreground uppercase tracking-widest">{previewPost?.role}</p>
                 </div>
                  <Badge className="bg-white/5 text-[10px] border-white/10 uppercase tracking-tighter">
                     {previewPost?.isJobPost ? 'Hiring' : previewPost?.isAvailabilityPost ? 'Available' : previewPost?.eventTitle ? 'Event' : 'Post'}
                  </Badge>
              </div>

              {/* Media Content */}
              {(previewPost?.imageUrl || (previewPost?.media && previewPost.media.length > 0)) && (
                 <div className="aspect-square w-full bg-zinc-900 border-y border-white/5 overflow-hidden relative group/media">
                    {(() => {
                       const mainMedia = previewPost?.media?.[0] || { url: previewPost?.imageUrl, type: 'image' };
                       const isVideo = mainMedia.type === 'video' || mainMedia.url?.toLowerCase().match(/\.(mp4|mov|webm)$/);
                       
                       if (isVideo) {
                          return (
                             <video 
                               src={mainMedia.url} 
                               className="w-full h-full object-cover" 
                               controls 
                               autoPlay 
                               muted 
                               loop
                             />
                          );
                       }
                       return <img src={mainMedia.url} className="w-full h-full object-cover" />;
                    })()}
                    
                    {previewPost?.media && previewPost.media.length > 1 && (
                       <div className="absolute bottom-4 right-4 bg-black/60 backdrop-blur-md px-3 py-1 rounded-full text-[10px] text-white font-bold border border-white/10">
                          + {previewPost.media.length - 1} more
                       </div>
                    )}
                 </div>
              )}

              {/* Job Details Card if Job Post */}
              {previewPost?.isJobPost && (
                 <div className="mx-6 mt-6 p-5 rounded-3xl bg-blue-500/10 border border-blue-500/20 space-y-4">
                    <div className="flex justify-between items-start">
                       <div>
                          <h3 className="text-lg font-bold text-blue-400">{previewPost.jobTitle}</h3>
                          <p className="text-xs text-muted-foreground">{previewPost.companyName}</p>
                       </div>
                       <Badge className="bg-blue-500 text-white font-bold">{previewPost.jobSalary}</Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                       <div className="p-3 rounded-2xl bg-black/40 border border-white/5">
                          <span className="text-[8px] text-muted-foreground uppercase block mb-1">Experience</span>
                          <span className="text-xs font-semibold">{previewPost.jobExperience}</span>
                       </div>
                       <div className="p-3 rounded-2xl bg-black/40 border border-white/5">
                          <span className="text-[8px] text-muted-foreground uppercase block mb-1">Location</span>
                          <span className="text-xs font-semibold truncate block">{previewPost.location}</span>
                       </div>
                    </div>
                    <div>
                       <span className="text-[8px] text-muted-foreground uppercase block mb-1">Skills Required</span>
                       <div className="flex flex-wrap gap-1">
                          {previewPost.jobSkills?.split(',').map(s => (
                             <Badge key={s} variant="outline" className="text-[10px] py-0 border-blue-500/30">{s.trim()}</Badge>
                          ))}
                       </div>
                    </div>
                 </div>
              )}

              {/* Availability Card if Worker Post */}
              {previewPost?.isAvailabilityPost && (
                 <div className="mx-6 mt-6 p-5 rounded-3xl bg-amber-500/10 border border-amber-500/20 space-y-3">
                    <h3 className="text-lg font-bold text-amber-500">I am available for work!</h3>
                    <div className="flex items-center gap-2 text-xs opacity-70">
                       <MapPin className="w-3 h-3" />
                       {previewPost.location}
                    </div>
                    <p className="text-xs leading-relaxed italic opacity-80">"Looking for immediate opportunities in this sector. Contact for details."</p>
                 </div>
              )}

              {/* Event Details Card if Event Post */}
              {previewPost?.eventTitle && (
                 <div className="mx-6 mt-6 p-5 rounded-3xl bg-purple-500/10 border border-purple-500/20 space-y-4">
                    <div className="flex justify-between items-start">
                       <div>
                          <h3 className="text-lg font-bold text-purple-400">{previewPost.eventTitle}</h3>
                          <p className="text-xs text-muted-foreground">{previewPost.eventLocation}</p>
                       </div>
                       <Calendar className="w-5 h-5 text-purple-400" />
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                       <div className="p-3 rounded-2xl bg-black/40 border border-white/5">
                          <span className="text-[8px] text-muted-foreground uppercase block mb-1">Date</span>
                          <span className="text-xs font-semibold">{previewPost.eventDate?.toDate ? previewPost.eventDate.toDate().toLocaleDateString() : 'N/A'}</span>
                       </div>
                       <div className="p-3 rounded-2xl bg-black/40 border border-white/5">
                          <span className="text-[8px] text-muted-foreground uppercase block mb-1">Time</span>
                          <span className="text-xs font-semibold">{previewPost.eventTime || 'N/A'}</span>
                       </div>
                    </div>
                 </div>
              )}

              {/* Text Content */}
              <div className="p-6 space-y-4">
                 <p className="text-sm leading-relaxed text-zinc-300">
                    {previewPost?.text}
                 </p>
                 <div className="flex items-center gap-4 text-muted-foreground pt-4 border-t border-white/5">
                    <div className="flex items-center gap-1.5">
                       <Heart className="w-4 h-4" />
                       <span className="text-xs">{previewPost?.likes}</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                       <MessageSquare className="w-4 h-4" />
                       <span className="text-xs">{previewPost?.comments}</span>
                    </div>
                    <span className="ml-auto text-[10px] font-mono opacity-30">
                       {previewPost?.createdAt?.toDate ? previewPost.createdAt.toDate().toLocaleString() : 'Recent'}
                    </span>
                 </div>
              </div>

              {/* Moderation Actions Footer */}
              <div className="p-4 bg-zinc-900 flex gap-2">
                 {previewPost?.status === 'pending' ? (
                    <>
                       <Button 
                         className="flex-1 bg-green-600 hover:bg-green-700 rounded-2xl h-12 gap-2"
                         onClick={() => {
                            setSelectedPost(previewPost);
                            setActionType('approve');
                            setPreviewPost(null);
                         }}
                       >
                          <Check className="w-4 h-4" /> Approve Post
                       </Button>
                       <Button 
                         variant="destructive"
                         className="flex-1 rounded-2xl h-12 gap-2"
                         onClick={() => {
                            setSelectedPost(previewPost);
                            setActionType('reject');
                            setPreviewPost(null);
                         }}
                       >
                          <X className="w-4 h-4" /> Reject
                       </Button>
                    </>
                 ) : (
                    <Button 
                      variant="outline" 
                      className="w-full rounded-2xl h-12 border-white/10"
                      onClick={() => setPreviewPost(null)}
                    >
                       Close Preview
                    </Button>
                 )}
              </div>
           </div>
        </DialogContent>
      </Dialog>

      <Dialog open={!!actionType} onOpenChange={() => setActionType(null)}>
        <DialogContent className="glass-card border-white/10">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Filter className="w-5 h-5 text-primary" />
              Confirm Moderation Action
            </DialogTitle>
            <DialogDescription className="pt-2 text-base">
              {actionType?.startsWith("bulk_") ? (
                <>
                  Are you sure you want to <b>{actionType?.replace("bulk_", "")}</b> {selectedIds.length} selected posts?
                  This will process all items simultaneously.
                </>
              ) : (
                <>
                  Are you sure you want to <b>{actionType?.replace("_", " ")}</b> this post by <b>{selectedPost?.name}</b>?
                  {actionType === "delete" && " This action is permanent and cannot be undone."}
                  {actionType === "hide" && " It will be hidden from all users but kept in the database."}
                  {actionType === "approve" && " It will become visible to all users on the community feed."}
                  {actionType === "reject" && " It will not be shown to users and the author will be notified."}
                  {actionType === "approve_edit" && " This will apply the proposed changes to the live post."}
                  {actionType === "reject_edit" && " This will discard the proposed changes and keep the original post."}
                </>
              )}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-6">
            <Button variant="outline" onClick={() => setActionType(null)}>Cancel</Button>
            <Button 
               variant={actionType?.includes("delete") || actionType === "reject_edit" ? "destructive" : "default"} 
               onClick={confirmAction}
               disabled={updateMutation.isPending || deleteMutation.isPending || approveEditMutation.isPending || rejectEditMutation.isPending}
               className={actionType?.includes("approve") ? "bg-green-600 hover:bg-green-700" : ""}
            >
              {(updateMutation.isPending || deleteMutation.isPending || approveEditMutation.isPending || rejectEditMutation.isPending) ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
              Confirm Action
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* REVIEW EDIT DIALOG */}
      <Dialog open={!!reviewEditPost} onOpenChange={() => setReviewEditPost(null)}>
        <DialogContent className="max-w-4xl glass-card border-white/10">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Edit3 className="w-5 h-5 text-blue-500" />
              Review Pending Edit
            </DialogTitle>
            <DialogDescription>
              Compare the original post with the proposed changes from the user.
            </DialogDescription>
          </DialogHeader>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4 max-h-[60vh] overflow-y-auto pr-2">
            {/* ORIGINAL COLUMN */}
            <div className="space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-widest text-muted-foreground bg-white/5 p-2 rounded">Original Content</h4>
              <div className="p-4 rounded-xl border border-white/5 bg-black/20">
                <p className="text-sm whitespace-pre-wrap">{reviewEditPost?.text}</p>
                {reviewEditPost?.media && reviewEditPost.media.length > 0 && (
                  <div className="mt-4 grid grid-cols-2 gap-2">
                    {reviewEditPost.media.map((m, i) => (
                      <div key={i} className="aspect-square rounded-lg overflow-hidden border border-white/5 bg-zinc-900">
                        {m.type === 'video' ? (
                          <div className="w-full h-full flex items-center justify-center bg-zinc-800">
                            <span className="text-[10px] text-zinc-500">Video</span>
                          </div>
                        ) : (
                          <img src={m.url} className="w-full h-full object-cover" />
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* EDITED COLUMN */}
            <div className="space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-widest text-blue-500 bg-blue-500/5 p-2 rounded">Proposed Changes</h4>
              <div className="p-4 rounded-xl border border-blue-500/20 bg-blue-500/5">
                <p className="text-sm whitespace-pre-wrap font-medium">
                  {reviewEditPost?.pendingEdit?.text || reviewEditPost?.text}
                </p>
                {/* Show new media if any */}
                {(reviewEditPost?.pendingEdit?.media || reviewEditPost?.media) && (
                  <div className="mt-4 grid grid-cols-2 gap-2">
                    {(reviewEditPost?.pendingEdit?.media || reviewEditPost?.media || []).map((m, i) => (
                      <div key={i} className="aspect-square rounded-lg overflow-hidden border border-blue-500/20 bg-zinc-900 relative">
                        {m.type === 'video' ? (
                          <div className="w-full h-full flex items-center justify-center bg-zinc-800">
                            <span className="text-[10px] text-blue-400">Video</span>
                          </div>
                        ) : (
                          <img src={m.url} className="w-full h-full object-cover" />
                        )}
                        {!reviewEditPost?.media?.some(om => om.url === m.url) && (
                          <Badge className="absolute top-1 right-1 bg-green-500 text-[8px] h-4">NEW</Badge>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>
              <div className="text-[10px] text-muted-foreground italic px-2">
                Submitted: {reviewEditPost?.pendingEdit?.submittedAt?.toDate ? reviewEditPost.pendingEdit.submittedAt.toDate().toLocaleString() : 'N/A'}
              </div>
            </div>
          </div>

          <DialogFooter className="mt-6 flex gap-2">
            <Button 
              variant="outline" 
              onClick={() => {
                setSelectedPost(reviewEditPost);
                setActionType('reject_edit');
              }}
              className="flex-1 border-red-500/20 hover:bg-red-500/10 text-red-500"
            >
              <X className="w-4 h-4 mr-2" /> Reject Changes
            </Button>
            <Button 
              onClick={() => {
                setSelectedPost(reviewEditPost);
                setActionType('approve_edit');
              }}
              className="flex-1 bg-green-600 hover:bg-green-700"
            >
              <Check className="w-4 h-4 mr-2" /> Approve & Update
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
