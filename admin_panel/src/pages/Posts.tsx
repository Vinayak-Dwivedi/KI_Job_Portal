import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { QueryDocumentSnapshot } from "firebase/firestore";
import { Search, Loader2, Eye, EyeOff, Trash2, Download, MessageSquare, Heart, ImageIcon } from "lucide-react";

import { fetchPosts, updatePostStatus, deletePostPermanently, type PostData } from "@/lib/api/posts";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Posts() {
  const queryClient = useQueryClient();
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
  const [filter, setFilter] = useState<"all" | "jobs" | "social">("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedPost, setSelectedPost] = useState<PostData | null>(null);
  const [actionType, setActionType] = useState<"hide" | "show" | "delete" | null>(null);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["posts", filter],
    queryFn: () => fetchPosts(lastDoc, filter),
  });

  const updateMutation = useMutation({
    mutationFn: async ({ postId, data, ownerUid }: { postId: string, data: Partial<PostData>, ownerUid?: string }) => {
      return updatePostStatus(postId, data, ownerUid);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["posts"] });
      setSelectedPost(null);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async ({ postId, ownerUid }: { postId: string, ownerUid?: string }) => {
      return deletePostPermanently(postId, ownerUid);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["posts"] });
      setSelectedPost(null);
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
      type: p.isJobPost ? "Job" : p.isAvailabilityPost ? "Availability" : "Social",
      stats: `${p.likes} Likes, ${p.comments} Comments`,
      status: p.isHidden ? "Hidden" : "Public",
    }));

    exportToPDF("Unified Feed Content Log", columns, exportData, "feed_moderation_report.pdf");
  };

  const confirmAction = () => {
    if (!selectedPost || !actionType) return;
    
    if (actionType === "delete") {
      deleteMutation.mutate({ 
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
          <p className="text-muted-foreground">Manage unified feed posts and social content.</p>
        </div>
        <Button onClick={handleExportPDF} variant="outline" className="gap-2 border-primary/20 hover:bg-primary/10">
          <Download className="w-4 h-4" /> Download Report
        </Button>
      </div>

      <Card>
        <CardHeader className="pb-3 border-b border-white/10 dark:border-white/5 mb-4">
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
            <div className="flex gap-2">
              <select 
                className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 glass"
                value={filter}
                onChange={(e) => {
                  setFilter(e.target.value as any);
                  setLastDoc(null);
                  setTimeout(() => refetch(), 0);
                }}
              >
                <option value="all">All Content</option>
                <option value="social">Social Only</option>
                <option value="jobs">Job Posts Only</option>
              </select>
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
                  <TableRow>
                    <TableHead>Author</TableHead>
                    <TableHead className="max-w-[300px]">Content</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Engagement</TableHead>
                    <TableHead>Visibility</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredPosts.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center py-10 text-muted-foreground">No posts found.</TableCell>
                    </TableRow>
                  ) : (
                    filteredPosts.map((post) => (
                      <TableRow key={post.id} className={post.isHidden ? "opacity-50" : ""}>
                        <TableCell>
                          <div className="flex flex-col">
                            <span className="font-medium">{post.name}</span>
                            <span className="text-xs text-muted-foreground capitalize">{post.role}</span>
                          </div>
                        </TableCell>
                        <TableCell className="max-w-[300px]">
                          <div className="flex items-start gap-2">
                            {post.imageUrl && (
                               <div className="mt-1 flex-shrink-0 bg-muted p-1 rounded border border-white/5">
                                  <ImageIcon className="w-4 h-4 text-primary" />
                               </div>
                            )}
                            <p className="text-sm line-clamp-2">{post.text}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                           {post.isJobPost ? (
                             <Badge variant="outline">Job</Badge>
                           ) : post.isAvailabilityPost ? (
                              <Badge variant="outline">Available</Badge>
                           ) : (
                              <Badge variant="secondary">Feed</Badge>
                           )}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-3 text-xs text-muted-foreground">
                            <span className="flex items-center gap-1"><Heart className="w-3 h-3"/> {post.likes}</span>
                            <span className="flex items-center gap-1"><MessageSquare className="w-3 h-3"/> {post.comments}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          {post.isHidden ? (
                            <Badge variant="destructive">Hidden</Badge>
                          ) : (
                            <Badge variant="success">Public</Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-right space-x-1">
                          <Button 
                            variant="ghost" 
                            size="sm" 
                            onClick={() => {
                              setSelectedPost(post);
                              setActionType(post.isHidden ? "show" : "hide");
                            }}
                          >
                            {post.isHidden ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4 text-orange-500" />}
                          </Button>
                          <Button 
                            variant="ghost" 
                            size="sm" 
                            onClick={() => {
                              setSelectedPost(post);
                              setActionType("delete");
                            }}
                            className="text-destructive hover:bg-destructive/10"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
              {data?.lastDoc && (
                <div className="mt-4 flex justify-center">
                   <Button variant="outline" onClick={() => { setLastDoc(data.lastDoc as any); setTimeout(() => refetch(), 0); }}>
                     Load More
                   </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      <Dialog open={!!selectedPost} onOpenChange={() => setSelectedPost(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Action</DialogTitle>
            <DialogDescription>
              Are you sure you want to {actionType === "delete" ? "permanently delete" : actionType} this post by <b>{selectedPost?.name}</b>?
              {actionType === "hide" && " It will be hidden from all users but kept in the database."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setSelectedPost(null)}>Cancel</Button>
            <Button 
               variant={actionType === "delete" ? "destructive" : "default"} 
               onClick={confirmAction}
               disabled={updateMutation.isPending || deleteMutation.isPending}
            >
              {(updateMutation.isPending || deleteMutation.isPending) ? <Loader2 className="w-4 h-4 animate-spin" /> : "Confirm"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
