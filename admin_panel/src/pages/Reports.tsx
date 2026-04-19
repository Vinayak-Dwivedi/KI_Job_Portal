import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { QueryDocumentSnapshot } from "firebase/firestore";
import { Loader2, Eye } from "lucide-react";

import { fetchReports, updateReportStatus } from "@/lib/api/reports";
import { deletePostPermanently, fetchPostById } from "@/lib/api/posts";
import { createPersonalNotification } from "@/lib/api/users";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Reports() {
  const queryClient = useQueryClient();
  const [lastDoc] = useState<QueryDocumentSnapshot | null>(null);
  const [selectedReport, setSelectedReport] = useState<any | null>(null);
  const [isActionOpen, setIsActionOpen] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ["reports"],
    queryFn: () => fetchReports(lastDoc),
  });

  const { data: originalPost, isLoading: isPostLoading } = useQuery({
    queryKey: ["post", selectedReport?.postId],
    queryFn: () => fetchPostById(selectedReport!.postId),
    enabled: !!selectedReport?.postId,
  });

  const resolveMutation = useMutation({
    mutationFn: async ({ reportId, action, postUid }: { reportId: string, action: "resolve" | "delete_post" | "warn", postUid?: string }) => {
      if (action === "delete_post" && selectedReport?.postId) {
        await deletePostPermanently(selectedReport.postId);
      } else if (action === "warn" && postUid) {
        await createPersonalNotification(
          postUid,
          "Content Warning",
          "One of your recent posts was flagged for violating community guidelines. Please ensure your content adheres to the rules.",
          "error"
        );
      }
      return updateReportStatus(reportId, "resolved");
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["reports"] });
      setIsActionOpen(false);
      setSelectedReport(null);
    }
  });

  const reports = data?.reports || [];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Reported Content</h2>
        <p className="text-muted-foreground">Moderate posts that have been flagged by the community.</p>
      </div>

      <Card>
        <CardContent className="pt-6">
          {isLoading ? (
            <div className="py-20 flex justify-center"><Loader2 className="animate-spin text-primary w-8 h-8" /></div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Reporter ID</TableHead>
                  <TableHead>Reason</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {reports.length === 0 ? (
                  <TableRow><TableCell colSpan={5} className="text-center py-10">No pending reports.</TableCell></TableRow>
                ) : (
                  reports.map((report) => (
                    <TableRow key={report.id}>
                      <TableCell className="font-mono text-xs">{report.reporterId}</TableCell>
                      <TableCell className="max-w-[200px] truncate">{report.reason}</TableCell>
                      <TableCell>
                        <Badge variant={report.status === "pending" ? "outline" : "secondary"}>
                          {report.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-xs">
                        {report.createdAt?.toDate ? report.createdAt.toDate().toLocaleDateString() : "Just now"}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="sm" onClick={() => { setSelectedReport(report); setIsActionOpen(true); }} className="gap-2">
                          <Eye className="w-4 h-4" /> Review
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

      <Dialog open={isActionOpen} onOpenChange={setIsActionOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Handle Report</DialogTitle>
            <DialogDescription asChild>
              <div className="space-y-4">
                <p>Review the reported content and take action.</p>
                <div className="p-4 bg-muted rounded-lg italic text-sm">
                  Reason: "{selectedReport?.reason}"
                </div>

                {selectedReport?.postId && (
                  <div className="border rounded-lg p-4 space-y-3 bg-card mt-4">
                    <h4 className="font-semibold text-sm">Original Post Content:</h4>
                    {isPostLoading ? (
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Loader2 className="w-4 h-4 animate-spin" /> Loading post...
                      </div>
                    ) : originalPost ? (
                      <div className="space-y-2">
                        <p className="text-sm border-l-2 border-primary pl-3 whitespace-pre-wrap">
                          {originalPost.text || "No text content provided."}
                        </p>
                        {originalPost.imageUrl && (
                          <div className="mt-2 rounded-md overflow-hidden max-h-48 flex justify-center bg-black/5">
                            <img src={originalPost.imageUrl} alt="Post content" className="object-contain max-h-48" />
                          </div>
                        )}
                      </div>
                    ) : (
                      <p className="text-sm text-destructive italic">Post not found or has been deleted.</p>
                    )}
                  </div>
                )}
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-6 flex gap-2 sm:justify-end">
            <Button variant="outline" onClick={() => resolveMutation.mutate({ reportId: selectedReport!.id, action: "resolve" })}>
              Ignore
            </Button>
            <Button variant="secondary" onClick={() => resolveMutation.mutate({ reportId: selectedReport!.id, action: "warn", postUid: selectedReport?.postUid })}>
              Warn User
            </Button>
            <Button variant="destructive" onClick={() => resolveMutation.mutate({ reportId: selectedReport!.id, action: "delete_post" })}>
              Delete Post
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
