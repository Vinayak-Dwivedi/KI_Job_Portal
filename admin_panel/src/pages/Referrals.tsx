import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { History, Settings, Save, Loader2, TrendingUp, Gift } from "lucide-react";
import { fetchReferralHistory, fetchReferralSettings } from "@/lib/api/referrals";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Checkbox } from "@/components/ui/checkbox";
import { doc, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";

export default function Referrals() {
  const queryClient = useQueryClient();
  const [bonus, setBonus] = useState<number>(0);
  const [isActive, setIsActive] = useState<boolean>(true);
  const [maxReferrals, setMaxReferrals] = useState<number>(0);
  const [validityWindow, setValidityWindow] = useState<number>(30);

  const { data: history, isLoading: isHistoryLoading } = useQuery({
    queryKey: ["referrals_history"],
    queryFn: fetchReferralHistory,
  });

  const { data: settings, isLoading: isSettingsLoading } = useQuery({
    queryKey: ["referrals_settings"],
    queryFn: async () => {
      const data = await fetchReferralSettings();
      setBonus(data.bonusPerReferral || 100);
      setIsActive(data.isActive ?? true);
      setMaxReferrals(data.maxReferralsPerUser || 0);
      setValidityWindow(data.validityWindowDays || 30);
      return data;
    },
  });

  const updateSettingsMutation = useMutation({
    mutationFn: async (payload: { newBonus: number; newActive: boolean; newMax: number; newWindow: number }) => {
      await setDoc(doc(db, "settings", "referrals"), { 
        bonusPerReferral: payload.newBonus, 
        isActive: payload.newActive,
        maxReferralsPerUser: payload.newMax,
        validityWindowDays: payload.newWindow
      }, { merge: true });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["referrals_settings"] });
    },
  });

  if (isHistoryLoading || isSettingsLoading) {
    return (
      <div className="h-[80vh] flex items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Referral Program</h2>
        <p className="text-muted-foreground">Monitor user referrals and configure incentive rewards.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="glass-card md:col-span-1">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="w-5 h-5 text-primary" />
              Program Settings
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Bonus per Referral (Credits)</label>
              <div className="relative">
                <Gift className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input 
                  type="number" 
                  className="pl-9" 
                  value={bonus} 
                  onChange={(e) => setBonus(parseInt(e.target.value))}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Max Referrals per User (0 = Unlimited)</label>
              <Input 
                type="number" 
                value={maxReferrals} 
                onChange={(e) => setMaxReferrals(parseInt(e.target.value))}
              />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Validity Window (Days)</label>
              <Input 
                type="number" 
                value={validityWindow} 
                onChange={(e) => setValidityWindow(parseInt(e.target.value))}
              />
            </div>
            
            <div className="flex items-center space-x-2 pt-2">
              <Checkbox 
                id="active" 
                checked={isActive} 
                onCheckedChange={(checked) => setIsActive(checked as boolean)} 
              />
              <label
                htmlFor="active"
                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
              >
                Enable Referral Program
              </label>
            </div>

            <Button className="w-full mt-4" onClick={() => updateSettingsMutation.mutate({ newBonus: bonus, newActive: isActive, newMax: maxReferrals, newWindow: validityWindow })}>
              <Save className="w-4 h-4 mr-2" /> Update Program
            </Button>
          </CardContent>
        </Card>

        <Card className="glass-card md:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
               <TrendingUp className="w-5 h-5 text-green-500" />
               Program Performance
            </CardTitle>
          </CardHeader>
          <CardContent>
             <div className="grid grid-cols-2 gap-4">
                <div className="p-4 rounded-xl bg-white/5 border border-white/10">
                   <div className="text-muted-foreground text-xs uppercase tracking-wider mb-1">Total Referrals</div>
                   <div className="text-3xl font-black">{history?.length || 0}</div>
                </div>
                <div className="p-4 rounded-xl bg-white/5 border border-white/10">
                   <div className="text-muted-foreground text-xs uppercase tracking-wider mb-1">Total Payout</div>
                   <div className="text-3xl font-black text-primary">{(history?.length || 0) * (settings?.bonusPerReferral || 0)} <span className="text-xs font-normal">Credits</span></div>
                </div>
             </div>
          </CardContent>
        </Card>
      </div>

      <Card className="glass-card">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="w-5 h-5 text-blue-500" />
            Referral Logs
          </CardTitle>
          <CardDescription>Real-time log of user acquisitions through the referral system.</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Referrer</TableHead>
                <TableHead>New User</TableHead>
                <TableHead>Bonus</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Timestamp</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {history?.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center py-20 text-muted-foreground italic">No referral activity recorded yet.</TableCell>
                </TableRow>
              ) : (
                history?.map((ref) => (
                  <TableRow key={ref.id}>
                    <TableCell>
                      <div className="flex flex-col">
                        <span className="font-medium text-sm">{ref.referrerName}</span>
                        <span className="text-[10px] text-muted-foreground font-mono">{ref.referrerUid}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-col">
                        <span className="font-medium text-sm">{ref.referredName}</span>
                        <span className="text-[10px] text-muted-foreground font-mono">{ref.referredUid}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary" className="gap-1">
                        +{ref.bonusAmount} Credits
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Badge variant={ref.status === 'paid' ? 'success' : 'outline'}>
                        {ref.status}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right text-xs text-muted-foreground">
                      {ref.timestamp?.toDate ? ref.timestamp.toDate().toLocaleString() : 'N/A'}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
