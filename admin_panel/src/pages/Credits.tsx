import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2, Coins, DollarSign, Save, Loader2 } from "lucide-react";
import { fetchCreditBundles, createOrUpdateBundle, deleteBundle, type CreditBundle } from "@/lib/api/credits";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Credits() {
  const queryClient = useQueryClient();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [selectedBundle, setSelectedBundle] = useState<Partial<CreditBundle> | null>(null);

  const { data: bundles, isLoading } = useQuery({
    queryKey: ["credit_bundles"],
    queryFn: fetchCreditBundles,
  });

  const saveMutation = useMutation({
    mutationFn: (bundle: CreditBundle) => createOrUpdateBundle(bundle),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["credit_bundles"] });
      setIsDialogOpen(false);
      setSelectedBundle(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteBundle(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["credit_bundles"] });
    },
  });

  const handleAddNew = () => {
    setSelectedBundle({
      name: "",
      credits: 500,
      price: 499,
      isActive: true,
      description: "Get more credits to post jobs."
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    if (selectedBundle && selectedBundle.name) {
      saveMutation.mutate(selectedBundle as CreditBundle);
    }
  };

  if (isLoading) {
    return (
      <div className="h-[80vh] flex items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Credit Bundles</h2>
          <p className="text-muted-foreground">Configure custom credit packages for users to purchase.</p>
        </div>
        <Button onClick={handleAddNew} className="gap-2">
          <Plus className="w-4 h-4" /> Add Bundle
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {bundles?.map((bundle) => (
          <Card key={bundle.id} className="glass-card relative overflow-hidden group">
             <div className="absolute top-0 right-0 p-2">
                <Button variant="ghost" size="icon" onClick={() => deleteMutation.mutate(bundle.id)} className="h-8 w-8 text-muted-foreground hover:text-red-500 hover:bg-red-500/10">
                   <Trash2 className="w-4 h-4" />
                </Button>
             </div>
             <CardHeader>
                <div className="h-12 w-12 rounded-2xl bg-primary/10 flex items-center justify-center mb-2 group-hover:scale-110 transition-transform">
                   <Coins className="h-6 w-6 text-primary" />
                </div>
                <CardTitle>{bundle.name}</CardTitle>
                <CardDescription className="line-clamp-1">{bundle.description}</CardDescription>
             </CardHeader>
             <CardContent className="space-y-4">
                <div className="flex items-end gap-1">
                   <span className="text-3xl font-black">{bundle.credits}</span>
                   <span className="text-muted-foreground text-sm mb-1 uppercase font-bold tracking-tighter">Credits</span>
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-white/5">
                   <div className="text-xl font-bold text-green-500">₹{(bundle.price / 100).toFixed(2)}</div>
                   <Badge variant={bundle.isActive ? "success" : "secondary"}>
                      {bundle.isActive ? "Active" : "Disabled"}
                   </Badge>
                </div>
             </CardContent>
          </Card>
        ))}
      </div>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="glass-card border-white/10">
          <DialogHeader>
            <DialogTitle>Add Credit Bundle</DialogTitle>
            <DialogDescription>Create a new credit package for the marketplace.</DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Bundle Name</label>
              <Input 
                placeholder="E.G. Starter Pack" 
                value={selectedBundle?.name || ""} 
                onChange={e => setSelectedBundle({...selectedBundle!, name: e.target.value})}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium flex items-center gap-2"><Coins className="w-3.5 h-3.5" /> Credits</label>
                <Input 
                  type="number"
                  value={selectedBundle?.credits || 0} 
                  onChange={e => setSelectedBundle({...selectedBundle!, credits: parseInt(e.target.value)})}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium flex items-center gap-2"><DollarSign className="w-3.5 h-3.5" /> Price (Paise)</label>
                <Input 
                  type="number"
                  placeholder="In Paise (e.g. 1000 = ₹10)"
                  value={selectedBundle?.price || 0} 
                  onChange={e => setSelectedBundle({...selectedBundle!, price: parseInt(e.target.value)})}
                />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Description</label>
              <Input 
                placeholder="Briefly describe this bundle..."
                value={selectedBundle?.description || ""} 
                onChange={e => setSelectedBundle({...selectedBundle!, description: e.target.value})}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saveMutation.isPending}>
              {saveMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Save className="w-4 h-4 mr-2" />}
              Save Bundle
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
