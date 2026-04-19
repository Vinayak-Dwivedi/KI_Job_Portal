import { useState, useEffect, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { ShieldCheck, Server, Coins, Save, Loader2, AlertTriangle, Plus, Trash2, Tag, User, Camera, Mail } from "lucide-react";
import { useAuth } from "@/providers/AuthContext";
import { uploadMediaFile } from "@/lib/api/upload";
import { fetchSystemSettings, updateSystemSettings, type SystemSettings } from "@/lib/api/settings";
import { fetchCategories, addCategory, deleteCategory } from "@/lib/api/categories";
import { updateUserStatus } from "@/lib/api/users";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default function Settings() {
  const { user, refreshUser } = useAuth();
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [adminName, setAdminName] = useState("");
  const [profileFile, setProfileFile] = useState<File | null>(null);
  const [profilePreview, setProfilePreview] = useState<string | null>(null);

  useEffect(() => {
    if (user?.name) setAdminName(user.name);
    if (user?.profilePhotoUrl) setProfilePreview(user.profilePhotoUrl);
  }, [user]);

  const { data: currentSettings, isLoading } = useQuery({
    queryKey: ["system_settings"],
    queryFn: fetchSystemSettings
  });

  const [formData, setFormData] = useState<SystemSettings>({
    maintenanceMode: false,
    minAppVersion: "1.0.0",
    freeCreditsThreshold: 50
  });

  useEffect(() => {
    if (currentSettings) {
      setFormData(currentSettings);
    }
  }, [currentSettings]);

  const mutation = useMutation({
    mutationFn: (data: Partial<SystemSettings>) => updateSystemSettings(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["system_settings"] });
      alert("Settings updated successfully!");
    }
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate(formData);
  };

  const adminMutation = useMutation({
    mutationFn: async () => {
      if (!user?.uid) return;
      
      let photoUrl = user.profilePhotoUrl;
      if (profileFile) {
        const uploadResult = await uploadMediaFile(profileFile, "profile_photos");
        photoUrl = uploadResult.url;
      }

      await updateUserStatus(user.uid, {
        name: adminName,
        fullName: adminName,
        profilePhotoUrl: photoUrl
      });
      
      await refreshUser();
    },
    onSuccess: () => {
      alert("Admin profile updated successfully!");
      setProfileFile(null);
    }
  });

  const handleAdminSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    adminMutation.mutate();
  };

  if (isLoading) return <div className="h-full flex items-center justify-center"><Loader2 className="animate-spin text-primary"/></div>;

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Platform Configuration</h2>
        <p className="text-muted-foreground">Adjust global system variables and administrative control flags.</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* Maintenance Settings */}
          <Card className={`glass-card border-none transition-all ${formData.maintenanceMode ? 'ring-2 ring-destructive/50' : ''}`}>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Server className="w-5 h-5 text-primary" /> System Availability
              </CardTitle>
              <CardDescription>Toggle maintenance mode to restrict user access.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-4 rounded-xl bg-background/40 border border-white/5">
                 <div className="space-y-0.5">
                   <p className="text-sm font-semibold">Maintenance Mode</p>
                   <p className="text-xs text-muted-foreground">Enable to lock the platform.</p>
                 </div>
                 <button 
                   type="button"
                   onClick={() => setFormData({...formData, maintenanceMode: !formData.maintenanceMode})}
                   className={`w-12 h-6 rounded-full transition-colors relative ${formData.maintenanceMode ? 'bg-destructive' : 'bg-muted-foreground/30'}`}
                 >
                   <div className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full transition-transform ${formData.maintenanceMode ? 'translate-x-6' : ''}`} />
                 </button>
              </div>
              
              {formData.maintenanceMode && (
                <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg flex items-start gap-3">
                   <AlertTriangle className="w-4 h-4 text-destructive mt-0.5" />
                   <p className="text-xs text-destructive font-medium leading-relaxed">
                     Warning: Enabling maintenance mode will block all app interactions for standard users.
                   </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Credits Settings */}
          <Card className="glass-card border-none">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Coins className="w-5 h-5 text-primary" /> Credit Economy
              </CardTitle>
              <CardDescription>Manage default credit balances for new users.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Free Initial Credits</label>
                <Input 
                  type="number" 
                  value={formData.freeCreditsThreshold}
                  onChange={(e) => setFormData({...formData, freeCreditsThreshold: parseInt(e.target.value)})}
                  className="bg-background/40"
                />
                <p className="text-[10px] text-muted-foreground italic">New accounts will start with this balance.</p>
              </div>
            </CardContent>
          </Card>

          {/* Version Control */}
          <Card className="glass-card border-none md:col-span-2">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-primary" /> Security & Versioning
              </CardTitle>
            </CardHeader>
            <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <label className="text-sm font-medium">Minimum Required App Version</label>
                <Input 
                  placeholder="e.g., 2.1.0" 
                  value={formData.minAppVersion}
                  onChange={(e) => setFormData({...formData, minAppVersion: e.target.value})}
                  className="bg-background/40 font-mono"
                />
                <p className="text-[10px] text-muted-foreground">Users below this version will be prompted to update.</p>
              </div>
            </CardContent>
          </Card>

        </div>

        {/* Category Management */}
        <SettingsCategories />

        <div className="flex justify-end gap-3 pt-4 border-t border-white/5 mt-8">
           <Button type="submit" disabled={mutation.isPending} className="px-10 h-11 text-base font-bold gap-2">
              {mutation.isPending ? <Loader2 className="w-5 h-5 animate-spin" /> : <><Save className="w-5 h-5"/> Save All Changes</>}
           </Button>
        </div>
      </form>
      {/* Monetization & Plans */}
      <Card className="glass-card border-none mt-6">
        <CardHeader>
          <div className="flex items-center gap-2">
            <Coins className="w-5 h-5 text-yellow-500" />
            <CardTitle>Monetization & Plans</CardTitle>
          </div>
          <CardDescription>Configure subscription pricing strings visible on the mobile app.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-xs font-semibold uppercase opacity-50">Pro Plan Price</label>
              <Input 
                placeholder="e.g. ₹299" 
                value={(formData as any).proPrice || ""} 
                onChange={(e) => setFormData({ ...formData, proPrice: e.target.value } as any)}
                className="bg-background/40"
              />
            </div>
            <div className="space-y-2">
              <label className="text-xs font-semibold uppercase opacity-50">Elite Plan Price</label>
              <Input 
                 placeholder="e.g. ₹799" 
                 value={(formData as any).elitePrice || ""} 
                 onChange={(e) => setFormData({ ...formData, elitePrice: e.target.value } as any)}
                 className="bg-background/40"
              />
            </div>
          </div>
          <p className="text-[10px] text-muted-foreground italic">Note: These values are synced to the 'platform_settings/subscriptions' document.</p>
        </CardContent>
      </Card>

      {/* Admin Profile Section */}
      <Card className="glass-card border-none mt-6 overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary/50 via-primary to-primary/50" />
        <CardHeader>
          <div className="flex items-center gap-2">
            <User className="w-5 h-5 text-primary" />
            <CardTitle>Admin Profile</CardTitle>
          </div>
          <CardDescription>Manage your institutional identity and display credentials.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleAdminSubmit} className="space-y-6">
            <div className="flex flex-col md:flex-row gap-8 items-start">
               {/* Profile Photo Picker */}
               <div className="relative group">
                 <input 
                   type="file" 
                   accept="image/*" 
                   className="hidden" 
                   ref={fileInputRef}
                   onChange={(e) => {
                     const file = e.target.files?.[0];
                     if (file) {
                       setProfileFile(file);
                       setProfilePreview(URL.createObjectURL(file));
                     }
                   }}
                 />
                 <div 
                   className="h-32 w-32 rounded-[2.5rem] bg-gradient-to-br from-primary/20 to-primary/5 p-1 cursor-pointer"
                   onClick={() => fileInputRef.current?.click()}
                 >
                   <div className="h-full w-full rounded-[2.2rem] bg-background flex items-center justify-center border border-white/5 relative overflow-hidden">
                     {profilePreview ? (
                       <img src={profilePreview} alt="Profile" className="h-full w-full object-cover" />
                     ) : (
                       <User className="h-12 w-12 text-primary/40" />
                     )}
                     <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                       <Camera className="w-6 h-6 text-white" />
                     </div>
                   </div>
                 </div>
                 <Badge className="absolute -bottom-2 -right-2 px-2 py-0.5 text-[10px] uppercase font-black bg-primary">ADMIN</Badge>
               </div>

               <div className="flex-1 space-y-4 w-full">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                       <label className="text-xs font-semibold uppercase opacity-50">Display Name</label>
                       <Input 
                         value={adminName} 
                         onChange={(e) => setAdminName(e.target.value)}
                         className="bg-background/40 h-12"
                         placeholder="Institutional Name"
                       />
                    </div>
                    <div className="space-y-2">
                       <label className="text-xs font-semibold uppercase opacity-50">Email Address</label>
                       <div className="h-12 flex items-center px-4 rounded-md bg-white/5 border border-white/5 text-muted-foreground gap-2">
                         <Mail className="w-4 h-4 opacity-50" />
                         <span className="text-sm">{user?.email || "Locked Account"}</span>
                       </div>
                    </div>
                  </div>
                  
                  <div className="flex justify-end pt-2">
                    <Button type="submit" disabled={adminMutation.isPending} className="gap-2 h-11 px-8 rounded-xl font-bold">
                       {adminMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                       Update Profile
                    </Button>
                  </div>
               </div>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

function SettingsCategories() {
  const queryClient = useQueryClient();
  const [newCat, setNewCat] = useState("");
  const { data: categories, isLoading } = useQuery({
    queryKey: ["categories"],
    queryFn: fetchCategories
  });

  const addMutation = useMutation({
    mutationFn: (name: string) => addCategory(name),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["categories"] });
      setNewCat("");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteCategory(id) ,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["categories"] });
    }
  });

  return (
    <Card className="glass-card border-none">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Tag className="w-5 h-5 text-primary" /> Platform Dropdowns
        </CardTitle>
        <CardDescription>Manage job categories and roles across the platform.</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex gap-2">
           <Input 
             placeholder="Add new category (e.g. Plumbing)" 
             value={newCat}
             onChange={(e) => setNewCat(e.target.value)}
             className="bg-background/40"
           />
           <Button type="button" onClick={() => addMutation.mutate(newCat)} disabled={!newCat || addMutation.isPending}>
              {addMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
           </Button>
        </div>

        <div className="flex flex-wrap gap-2">
           {isLoading ? (
             <div className="py-2"><Loader2 className="w-4 h-4 animate-spin" /></div>
           ) : (
             categories?.map(cat => (
               <Badge key={cat.id} variant="secondary" className="pl-3 pr-1 py-1 gap-1 border border-white/5">
                 {cat.name}
                 <Button 
                   variant="ghost" 
                   size="icon" 
                   className="h-4 w-4 rounded-full p-0.5 hover:bg-destructive/20 hover:text-destructive"
                   onClick={() => deleteMutation.mutate(cat.id)}
                 >
                   <Trash2 className="w-3 h-3" />
                 </Button>
               </Badge>
             ))
           )}
           {categories && categories.length === 0 && <p className="text-xs text-muted-foreground italic">No categories defined.</p>}
        </div>
      </CardContent>
    </Card>
  );
}

