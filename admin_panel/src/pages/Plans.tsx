import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Plus, 
  Edit2, 
  Trash2, 
  Save, 
  Sparkles, 
  CreditCard, 
  Clock, 
  ListChecks, 
  Palette,
  Loader2,
  RefreshCw
} from "lucide-react";

import { fetchAllPlans, createOrUpdatePlan, deletePlan, seedDefaultPlans } from "@/lib/api/plans";
import type { SubscriptionPlan } from "@/lib/api/plans";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function Plans() {
  const queryClient = useQueryClient();
  const [selectedPlan, setSelectedPlan] = useState<Partial<SubscriptionPlan> | null>(null);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isSeeding, setIsSeeding] = useState(false);

  const { data: plans, isLoading } = useQuery({
    queryKey: ["subscription_plans"],
    queryFn: fetchAllPlans,
  });

  const saveMutation = useMutation({
    mutationFn: (plan: SubscriptionPlan) => createOrUpdatePlan(plan),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["subscription_plans"] });
      setIsEditDialogOpen(false);
      setSelectedPlan(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deletePlan(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["subscription_plans"] });
    },
  });

  const handleEdit = (plan: SubscriptionPlan) => {
    setSelectedPlan({ ...plan });
    setIsEditDialogOpen(true);
  };

  const handleAddNew = () => {
    setSelectedPlan({
      id: "",
      name: "",
      price: 0,
      durationDays: 30,
      credits: 0,
      maxApplicationsPerDay: 10,
      features: [""],
      color: "#1D4ED8",
      isPopular: false,
      description: ""
    });
    setIsEditDialogOpen(true);
  };

  const handleSave = () => {
    if (selectedPlan && selectedPlan.id) {
      saveMutation.mutate(selectedPlan as SubscriptionPlan);
    }
  };

  const handleSeed = async () => {
    setIsSeeding(true);
    try {
      await seedDefaultPlans();
      queryClient.invalidateQueries({ queryKey: ["subscription_plans"] });
    } finally {
      setIsSeeding(false);
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
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Subscription Plans</h2>
          <p className="text-muted-foreground mt-1">Manage dynamic offerings, pricing, and user limits.</p>
        </div>
        <div className="flex gap-3">
          {(!plans || plans.length === 0) && (
            <Button variant="outline" onClick={handleSeed} disabled={isSeeding} className="gap-2">
               {isSeeding ? <Loader2 className="w-4 h-4 animate-spin" /> : <RefreshCw className="w-4 h-4" />}
               Seed Defaults
            </Button>
          )}
          <Button onClick={handleAddNew} className="gap-2 shadow-lg shadow-primary/20">
            <Plus className="w-4 h-4" /> Add New Plan
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6">
        <Card className="glass-card border-none shadow-xl overflow-hidden">
          <CardHeader className="bg-white/5 pb-6">
            <CardTitle className="text-lg">Active Plans</CardTitle>
            <CardDescription>All subscription tiers currently visible to users in the mobile app.</CardDescription>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow className="hover:bg-transparent border-white/5">
                  <TableHead className="pl-6">Plan Name</TableHead>
                  <TableHead>Price</TableHead>
                  <TableHead>Duration</TableHead>
                  <TableHead>Credits</TableHead>
                  <TableHead>Access Limit</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right pr-6">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {plans?.map((plan) => (
                  <TableRow key={plan.id} className="border-white/5 hover:bg-white/5 transition-colors">
                    <TableCell className="pl-6 font-medium">
                      <div className="flex items-center gap-3">
                        <div 
                          className="w-3 h-3 rounded-full" 
                          style={{ backgroundColor: plan.color }}
                        />
                        {plan.name}
                        {plan.isPopular && <Badge variant="secondary" className="bg-primary/20 text-primary border-none text-[10px]">Popular</Badge>}
                      </div>
                    </TableCell>
                    <TableCell className="font-bold">₹{plan.price}</TableCell>
                    <TableCell>{plan.durationDays} Days</TableCell>
                    <TableCell>
                       <div className="flex items-center gap-1.5 text-zinc-400">
                         <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                         {plan.credits}
                       </div>
                    </TableCell>
                    <TableCell>{plan.maxApplicationsPerDay} apps/day</TableCell>
                    <TableCell>
                      <Badge variant="outline" className="border-green-500/20 text-green-500 bg-green-500/5">Active</Badge>
                    </TableCell>
                    <TableCell className="text-right pr-6">
                      <div className="flex justify-end gap-2">
                        <Button variant="ghost" size="icon" onClick={() => handleEdit(plan)}>
                          <Edit2 className="w-4 h-4" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => deleteMutation.mutate(plan.id)} className="text-red-500 hover:text-red-600 hover:bg-red-500/10">
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
                {(!plans || plans.length === 0) && (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-20 text-muted-foreground italic">
                      No plans found. Click "Add New Plan" or "Seed Defaults" to begin.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="max-w-2xl glass-card border-white/10">
          <DialogHeader>
            <DialogTitle>{selectedPlan?.id ? "Edit Plan" : "Create New Subscription Plan"}</DialogTitle>
            <DialogDescription>
              Configure pricing, duration, and user benefits for this subscription tier.
            </DialogDescription>
          </DialogHeader>

          <div className="grid grid-cols-2 gap-6 py-4">
            <div className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Unique Plan ID (Tier)</label>
                <Input 
                  placeholder="e.g. pro, elite, starter" 
                  value={selectedPlan?.id || ""} 
                  onChange={e => setSelectedPlan({...selectedPlan, id: e.target.value})}
                  disabled={!!plans?.find(p => p.id === selectedPlan?.id && selectedPlan?.id !== "") && !selectedPlan?.id}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Display Name</label>
                <Input 
                  placeholder="e.g. Professional Plan" 
                  value={selectedPlan?.name || ""} 
                  onChange={e => setSelectedPlan({...selectedPlan!, name: e.target.value})}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium flex items-center gap-2">
                    <CreditCard className="w-3.5 h-3.5" /> Price (₹)
                  </label>
                  <Input 
                    type="number" 
                    value={selectedPlan?.price || 0} 
                    onChange={e => setSelectedPlan({...selectedPlan!, price: parseInt(e.target.value)})}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium flex items-center gap-2">
                    <Clock className="w-3.5 h-3.5" /> Days
                  </label>
                  <Input 
                    type="number" 
                    value={selectedPlan?.durationDays || 30} 
                    onChange={e => setSelectedPlan({...selectedPlan!, durationDays: parseInt(e.target.value)})}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium flex items-center gap-2">
                  <Palette className="w-3.5 h-3.5" /> Brand Color (Hex)
                </label>
                <div className="flex gap-2">
                   <Input 
                     placeholder="#1D4ED8" 
                     value={selectedPlan?.color || ""} 
                     onChange={e => setSelectedPlan({...selectedPlan!, color: e.target.value})}
                   />
                   <div className="w-10 h-10 rounded-md border border-white/10" style={{ backgroundColor: selectedPlan?.color || '#000' }} />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium flex items-center gap-2">
                    <Sparkles className="w-3.5 h-3.5 text-amber-500" /> Initial Credits
                  </label>
                  <Input 
                    type="number" 
                    value={selectedPlan?.credits || 0} 
                    onChange={e => setSelectedPlan({...selectedPlan!, credits: parseInt(e.target.value)})}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium flex items-center gap-2">
                    <ListChecks className="w-3.5 h-3.5" /> Apps / Day
                  </label>
                  <Input 
                    type="number" 
                    value={selectedPlan?.maxApplicationsPerDay || 0} 
                    onChange={e => setSelectedPlan({...selectedPlan!, maxApplicationsPerDay: parseInt(e.target.value)})}
                  />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Features (One per line)</label>
                <textarea 
                  className="w-full min-h-[100px] rounded-md border border-white/10 bg-white/5 p-3 text-sm"
                  placeholder="Unlimited Jobs&#10;Featured Profile"
                  value={selectedPlan?.features?.join('\n') || ""}
                  onChange={e => setSelectedPlan({...selectedPlan!, features: e.target.value.split('\n')})}
                />
              </div>
              <div className="flex items-center gap-2 pt-2">
                <input 
                  type="checkbox" 
                  id="isPopular" 
                  checked={selectedPlan?.isPopular || false}
                  onChange={e => setSelectedPlan({...selectedPlan!, isPopular: e.target.checked})}
                />
                <label htmlFor="isPopular" className="text-sm font-medium">Mark as "Most Popular"</label>
              </div>
            </div>
          </div>

          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saveMutation.isPending}>
              {saveMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4 mr-2" />}
              Save Plan
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
