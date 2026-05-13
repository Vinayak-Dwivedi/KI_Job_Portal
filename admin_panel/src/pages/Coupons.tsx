import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2, Tag, Calendar, Users, Percent, Save, Loader2 } from "lucide-react";
import { fetchAllCoupons, createOrUpdateCoupon, deleteCoupon, type Coupon } from "@/lib/api/coupons";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

export default function Coupons() {
  const queryClient = useQueryClient();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [selectedCoupon, setSelectedCoupon] = useState<Partial<Coupon> | null>(null);

  const { data: coupons, isLoading } = useQuery({
    queryKey: ["coupons"],
    queryFn: fetchAllCoupons,
  });

  const saveMutation = useMutation({
    mutationFn: (coupon: Coupon) => createOrUpdateCoupon(coupon),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["coupons"] });
      setIsDialogOpen(false);
      setSelectedCoupon(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteCoupon(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["coupons"] });
    },
  });

  const handleAddNew = () => {
    setSelectedCoupon({
      code: "",
      discountPercent: 10,
      maxUses: 100,
      usedCount: 0,
      isActive: true,
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    });
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    if (selectedCoupon && selectedCoupon.code) {
      saveMutation.mutate(selectedCoupon as Coupon);
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
          <h2 className="text-2xl font-bold tracking-tight">Coupon Management</h2>
          <p className="text-muted-foreground">Create and manage promotional discount codes for subscription plans.</p>
        </div>
        <Button onClick={handleAddNew} className="gap-2">
          <Plus className="w-4 h-4" /> Create Coupon
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-6">
        <Card className="glass-card">
          <CardHeader>
            <CardTitle>Active Coupons</CardTitle>
            <CardDescription>Coupons currently valid for use in the mobile app.</CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Code</TableHead>
                  <TableHead>Discount</TableHead>
                  <TableHead>Usage</TableHead>
                  <TableHead>Expires</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {coupons?.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-20 text-muted-foreground">No coupons found.</TableCell>
                  </TableRow>
                ) : (
                  coupons?.map((coupon) => (
                    <TableRow key={coupon.id}>
                      <TableCell className="font-bold tracking-widest text-primary">{coupon.code}</TableCell>
                      <TableCell>
                        <Badge variant="secondary" className="gap-1">
                          <Percent className="w-3 h-3" /> {coupon.discountPercent}% OFF
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col gap-1">
                          <span className="text-xs font-medium">{coupon.usedCount} / {coupon.maxUses} used</span>
                          <div className="w-24 h-1.5 bg-white/5 rounded-full overflow-hidden">
                             <div 
                               className="h-full bg-primary" 
                               style={{ width: `${(coupon.usedCount / coupon.maxUses) * 100}%` }}
                             />
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="text-sm">
                        {coupon.expiryDate?.toDate ? coupon.expiryDate.toDate().toLocaleDateString() : coupon.expiryDate}
                      </TableCell>
                      <TableCell>
                        <Badge variant={coupon.isActive ? "success" : "secondary"}>
                          {coupon.isActive ? "Active" : "Disabled"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <Button variant="ghost" size="icon" onClick={() => deleteMutation.mutate(coupon.id)} className="text-red-500 hover:bg-red-500/10">
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="glass-card border-white/10">
          <DialogHeader>
            <DialogTitle>Create New Coupon</DialogTitle>
            <DialogDescription>Set up a new discount code for your users.</DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium flex items-center gap-2"><Tag className="w-3.5 h-3.5" /> Coupon Code</label>
              <Input 
                placeholder="E.G. WELCOME50" 
                value={selectedCoupon?.code || ""} 
                onChange={e => setSelectedCoupon({...selectedCoupon!, code: e.target.value.toUpperCase()})}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium flex items-center gap-2"><Percent className="w-3.5 h-3.5" /> Discount (%)</label>
                <Input 
                  type="number"
                  value={selectedCoupon?.discountPercent || 0} 
                  onChange={e => setSelectedCoupon({...selectedCoupon!, discountPercent: parseInt(e.target.value)})}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium flex items-center gap-2"><Calendar className="w-3.5 h-3.5" /> Expiry Date</label>
                <Input 
                  type="date"
                  value={selectedCoupon?.expiryDate || ""} 
                  onChange={e => setSelectedCoupon({...selectedCoupon!, expiryDate: e.target.value})}
                />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium flex items-center gap-2"><Users className="w-3.5 h-3.5" /> Max Uses</label>
              <Input 
                type="number"
                value={selectedCoupon?.maxUses || 0} 
                onChange={e => setSelectedCoupon({...selectedCoupon!, maxUses: parseInt(e.target.value)})}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saveMutation.isPending}>
              {saveMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Save className="w-4 h-4 mr-2" />}
              Save Coupon
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
