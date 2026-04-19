import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2, Send, CheckCircle, Clock } from "lucide-react";

import { fetchSupportTickets, resolveTicket, type SupportTicket } from "@/lib/api/support";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Support() {
  const queryClient = useQueryClient();
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
  const [response, setResponse] = useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["support_tickets"],
    queryFn: () => fetchSupportTickets(),
  });

  const resolveMutation = useMutation({
    mutationFn: async ({ ticketId, response }: { ticketId: string, response: string }) => {
      return resolveTicket(ticketId, response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["support_tickets"] });
      setSelectedTicket(null);
      setResponse("");
    }
  });

  const tickets = data?.tickets || [];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Helpdesk & Support</h2>
        <p className="text-muted-foreground">Respond to user complaints and support requests.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="glass-card">
          <CardContent className="pt-6">
            <h4 className="text-sm font-medium text-muted-foreground">Open Tickets</h4>
            <p className="text-2xl font-bold">{tickets.filter(t => t.status === "open").length}</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="pt-6">
          {isLoading ? (
            <div className="py-20 flex justify-center"><Loader2 className="animate-spin text-primary w-8 h-8"/></div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User ID</TableHead>
                  <TableHead>Subject</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {tickets.length === 0 ? (
                  <TableRow><TableCell colSpan={5} className="text-center py-10 text-muted-foreground italic">No tickets found.</TableCell></TableRow>
                ) : (
                  tickets.map((ticket) => (
                    <TableRow key={ticket.id}>
                      <TableCell className="font-mono text-xs">{ticket.uid}</TableCell>
                      <TableCell className="font-medium text-sm">{ticket.subject}</TableCell>
                      <TableCell>
                        <Badge variant={ticket.status === "open" ? "destructive" : "success"} className="gap-1 px-2 py-0.5">
                          {ticket.status === "open" ? <Clock className="w-3 h-3"/> : <CheckCircle className="w-3 h-3"/>}
                          {ticket.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-xs">
                        {ticket.createdAt?.toDate ? ticket.createdAt.toDate().toLocaleDateString() : "Just now"}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="sm" onClick={() => setSelectedTicket(ticket)} className="gap-2">
                           View Request
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

      <Dialog open={!!selectedTicket} onOpenChange={() => setSelectedTicket(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{selectedTicket?.subject}</DialogTitle>
            <DialogDescription>From: <b>{selectedTicket?.uid}</b></DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            <div className="p-4 bg-muted rounded-xl space-y-2">
               <p className="text-xs font-semibold uppercase text-muted-foreground tracking-wider">Message Content</p>
               <p className="text-sm leading-relaxed">{selectedTicket?.message}</p>
            </div>

            {selectedTicket?.status === "resolved" ? (
               <div className="p-4 bg-primary/10 border border-primary/20 rounded-xl space-y-2">
                  <p className="text-xs font-semibold uppercase text-primary tracking-wider">Admin Response</p>
                  <p className="text-sm leading-relaxed">{selectedTicket?.response}</p>
               </div>
            ) : (
               <div className="space-y-3 pt-2">
                  <p className="text-sm font-medium">Your Response</p>
                  <textarea 
                    className="w-full min-h-[120px] rounded-md border border-input bg-background/50 px-3 py-2 text-sm glass"
                    placeholder="Type your answer to help the user..."
                    value={response}
                    onChange={(e) => setResponse(e.target.value)}
                  />
               </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setSelectedTicket(null)}>Close</Button>
            {selectedTicket?.status === "open" && (
              <Button onClick={() => resolveMutation.mutate({ ticketId: selectedTicket!.id, response })} disabled={!response || resolveMutation.isPending}>
                {resolveMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Send className="w-4 h-4 mr-2"/> Resolve & Reply</>}
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
