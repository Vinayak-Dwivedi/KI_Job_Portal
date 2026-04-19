import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { QueryDocumentSnapshot } from "firebase/firestore";
import { Search, Loader2, Star, Trash2, Download } from "lucide-react";

import { fetchJobs, updateJobStatus, deleteJobPost, type JobData } from "@/lib/api/jobs";
import { exportToPDF } from "@/lib/exportUtils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Jobs() {
  const queryClient = useQueryClient();
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot | null>(null);
  const [statusFilter, setStatusFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedJob, setSelectedJob] = useState<JobData | null>(null);
  const [actionType, setActionType] = useState<"close" | "feature" | "delete" | null>(null);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["jobs", statusFilter],
    queryFn: () => fetchJobs(lastDoc, statusFilter),
  });

  const updateMutation = useMutation({
    mutationFn: async ({ jobId, data }: { jobId: string, data: Partial<JobData> }) => {
      return updateJobStatus(jobId, data);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["jobs"] });
      setSelectedJob(null);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (jobId: string) => {
      return deleteJobPost(jobId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["jobs"] });
      setSelectedJob(null);
    }
  });

  const handleAction = (job: JobData, action: "close" | "feature" | "delete") => {
    setSelectedJob(job);
    setActionType(action);
  };

  const confirmAction = () => {
    if (!selectedJob || !actionType) return;
    
    if (actionType === "delete") {
      deleteMutation.mutate(selectedJob.id);
    } else if (actionType === "close") {
      updateMutation.mutate({ jobId: selectedJob.id, data: { status: "closed" } });
    } else if (actionType === "feature") {
      updateMutation.mutate({ jobId: selectedJob.id, data: { isFeatured: !selectedJob.isFeatured } });
    }
  };

  const handleExportPDF = () => {
    if (!data?.jobs) return;
    
    const columns = [
      { header: "Title", dataKey: "title" },
      { header: "Employer", dataKey: "employerName" },
      { header: "Status", dataKey: "status" },
      { header: "Featured", dataKey: "isFeatured" },
      { header: "Location", dataKey: "location" },
    ];

    const exportData = data.jobs.map(j => ({
      title: j.title,
      employerName: j.employerName,
      status: j.status.toUpperCase(),
      isFeatured: j.isFeatured ? "Yes" : "No",
      location: j.location || "N/A",
    }));

    exportToPDF("Job Postings Audit Report", columns, exportData, "jobs_report.pdf");
  };

  const jobs = data?.jobs || [];

  const filteredJobs = jobs.filter(j => 
    j.title?.toLowerCase().includes(searchQuery.toLowerCase()) || 
    j.employerName?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Job Management</h2>
          <p className="text-muted-foreground">Monitor, feature, and close job postings.</p>
        </div>
        <Button onClick={handleExportPDF} variant="outline" className="gap-2 border-primary/20 hover:bg-primary/10">
          <Download className="w-4 h-4" /> Export Report
        </Button>
      </div>

      <Card>
        <CardHeader className="pb-3 border-b border-white/10 dark:border-white/5 mb-4">
          <div className="flex flex-wrap gap-4 items-center justify-between">
            <div className="relative w-full max-w-sm">
              <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input 
                placeholder="Search jobs or employers..." 
                className="pl-9 h-10 w-full"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex gap-2">
              <select 
                className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 glass"
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value);
                  setLastDoc(null); 
                  setTimeout(() => refetch(), 0);
                }}
              >
                <option value="all">All Statuses</option>
                <option value="open">Open</option>
                <option value="closed">Closed</option>
                <option value="filled">Filled</option>
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
                    <TableHead>Job Role</TableHead>
                    <TableHead>Employer</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Featured</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredJobs.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center py-10 text-muted-foreground">
                        No jobs found.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredJobs.map((job) => (
                      <TableRow key={job.id}>
                        <TableCell>
                          <div className="flex flex-col">
                            <span className="font-medium text-foreground">{job.title}</span>
                            <span className="text-xs text-muted-foreground truncate max-w-[200px]">{job.description}</span>
                            <span className="text-xs text-primary">{job.location}</span>
                          </div>
                        </TableCell>
                        <TableCell className="font-medium">
                          {job.employerName}
                        </TableCell>
                        <TableCell>
                          {job.status === "open" ? (
                            <Badge variant="success" className="capitalize">{job.status}</Badge>
                          ) : (
                            <Badge variant="secondary" className="capitalize">{job.status}</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                           {job.isFeatured ? (
                             <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" />
                           ) : (
                             <Star className="w-5 h-5 text-muted-foreground" />
                           )}
                        </TableCell>
                        <TableCell className="text-right space-x-2">
                          <Button 
                             variant="outline" 
                             size="sm" 
                             onClick={() => handleAction(job, "feature")} 
                             className="text-yellow-600 dark:text-yellow-400 hover:text-yellow-700 hover:bg-yellow-500/10 border-yellow-500/20"
                          >
                            {job.isFeatured ? "Unfeature" : "Feature"}
                          </Button>
                          
                          {job.status === "open" && (
                            <Button variant="ghost" size="sm" onClick={() => handleAction(job, "close")} className="hover:text-orange-500 hover:bg-orange-500/10">
                              Close
                            </Button>
                          )}
                          
                          <Button variant="ghost" size="sm" onClick={() => handleAction(job, "delete")} className="text-destructive hover:text-destructive hover:bg-destructive/10">
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
                   <Button 
                     variant="outline" 
                     onClick={() => {
                        setLastDoc(data.lastDoc as QueryDocumentSnapshot);
                        setTimeout(() => refetch(), 0);
                     }}
                   >
                     Load More
                   </Button>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      <Dialog open={!!selectedJob} onOpenChange={() => setSelectedJob(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Action</DialogTitle>
            <DialogDescription>
              Are you sure you want to {actionType} the job <span className="font-bold text-foreground">{selectedJob?.title}</span>? 
              {actionType === "delete" && " This action cannot be undone."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setSelectedJob(null)}>Cancel</Button>
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
