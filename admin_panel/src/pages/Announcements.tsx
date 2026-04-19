import { useState, useRef, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Megaphone, Send, Loader2, History, Sparkles, Globe, ShieldCheck, Heart, MessageSquare, Image as ImageIcon, UploadCloud, MonitorPlay } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

import { broadcastAnnouncement, fetchRecentAnnouncements, createAdminFeedPost, fetchAdminFeedPosts, fetchActiveBanner, updateActiveBanner, type AnnouncementData } from "@/lib/api/announcements";
import { uploadMediaFile } from "@/lib/api/upload";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

export default function Announcements() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<"broadcast" | "feed" | "banners">("broadcast");
  const [logTab, setLogTab] = useState<"announcements" | "posts">("announcements");
  
  // Broadcast State
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [target, setTarget] = useState<"all" | "workers" | "employers">("all");

  // Feed Post State
  const [feedPost, setFeedPost] = useState("");
  const [feedFile, setFeedFile] = useState<File | null>(null);
  const feedFileInputRef = useRef<HTMLInputElement>(null);

  // Banner State
  const [bannerHeadline, setBannerHeadline] = useState("");
  const [bannerSubhead, setBannerSubhead] = useState("");
  const [bannerFile, setBannerFile] = useState<File | null>(null);
  const bannerFileInputRef = useRef<HTMLInputElement>(null);

  const { data: recent, isLoading } = useQuery({
    queryKey: ["announcements"],
    queryFn: fetchRecentAnnouncements
  });

  const { data: adminPosts, isLoading: isLoadingPosts } = useQuery({
    queryKey: ["admin_posts"],
    queryFn: fetchAdminFeedPosts
  });

  const { data: activeBanner } = useQuery({
    queryKey: ["active_banner"],
    queryFn: fetchActiveBanner
  });

  useEffect(() => {
    if (activeBanner) {
      setBannerHeadline(activeBanner.headline || "");
      setBannerSubhead(activeBanner.subhead || "");
    }
  }, [activeBanner]);

  const mutation = useMutation({
    mutationFn: (data: AnnouncementData) => broadcastAnnouncement(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
      setTitle("");
      setMessage("");
    }
  });

  const feedMutation = useMutation({
    mutationFn: async () => {
      let mediaData;
      if (feedFile) {
        mediaData = await uploadMediaFile(feedFile, "admin_posts");
      }
      return createAdminFeedPost(feedPost, mediaData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin_posts"] });
      setFeedPost("");
      setFeedFile(null);
    }
  });

  const bannerMutation = useMutation({
    mutationFn: async () => {
      let imageUrl = activeBanner?.imageUrl || "";
      if (bannerFile) {
        const mediaData = await uploadMediaFile(bannerFile, "banners");
        if (mediaData.type !== 'image') throw new Error("Banners must be images");
        imageUrl = mediaData.url;
      }
      if (!imageUrl) throw new Error("Banner image is required");

      return updateActiveBanner({
        headline: bannerHeadline,
        subhead: bannerSubhead,
        imageUrl,
        isActive: true
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["active_banner"] });
      setBannerFile(null);
      alert("Banner updated successfully!");
    }
  });

  const handleBroadcast = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !message) return;
    mutation.mutate({ title, message, target });
  };

  const handleFeedPost = (e: React.FormEvent) => {
    e.preventDefault();
    if (!feedPost && !feedFile) return;
    feedMutation.mutate();
  };

  const handleBannerSave = (e: React.FormEvent) => {
    e.preventDefault();
    bannerMutation.mutate();
  };

  return (
    <div className="space-y-8 max-w-[1400px] mx-auto pb-12">
      {/* Header Section */}
      <motion.div 
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6"
      >
        <div className="space-y-1">
          <h2 className="text-4xl font-bold tracking-tight text-zinc-900 dark:text-white font-serif">
            Executive <span className="text-primary italic">Dispatch</span>
          </h2>
          <p className="text-zinc-500 dark:text-zinc-400 text-lg">
            Manage institutional broadcasts, official posts, and platform marketing banners.
          </p>
        </div>
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
        {/* Creator Section */}
        <div className="lg:col-span-7 space-y-6">
          <div className="relative bg-zinc-100 dark:bg-zinc-900/50 p-1.5 rounded-2xl flex gap-1 w-full sm:w-fit mb-8 shadow-inner overflow-hidden border border-white/5 overflow-x-auto">
             <button 
               onClick={() => setActiveTab("broadcast")}
               className={cn(
                 "relative px-4 sm:px-6 py-2.5 text-sm font-semibold transition-colors rounded-xl flex items-center gap-2 z-10 shrink-0",
                 activeTab === "broadcast" ? "bg-white dark:bg-zinc-800 shadow-sm text-primary dark:text-white" : "text-zinc-500 hover:text-zinc-700"
               )}
             >
               <Megaphone className="w-4 h-4" /> System Alerts
             </button>
             <button 
               onClick={() => setActiveTab("feed")}
               className={cn(
                 "relative px-4 sm:px-6 py-2.5 text-sm font-semibold transition-colors rounded-xl flex items-center gap-2 z-10 shrink-0",
                 activeTab === "feed" ? "bg-white dark:bg-zinc-800 shadow-sm text-primary dark:text-white" : "text-zinc-500 hover:text-zinc-700"
               )}
             >
               <Globe className="w-4 h-4" /> Official Feed
             </button>
             <button 
               onClick={() => setActiveTab("banners")}
               className={cn(
                 "relative px-4 sm:px-6 py-2.5 text-sm font-semibold transition-colors rounded-xl flex items-center gap-2 z-10 shrink-0",
                 activeTab === "banners" ? "bg-white dark:bg-zinc-800 shadow-sm text-primary dark:text-white" : "text-zinc-500 hover:text-zinc-700"
               )}
             >
               <MonitorPlay className="w-4 h-4" /> App Ad Banners
             </button>
          </div>

          <AnimatePresence mode="wait">
            {activeTab === "broadcast" && (
              <motion.div
                key="broadcast"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.3 }}
              >
                <Card className="no-line-card p-1">
                  <CardHeader className="pb-4">
                    <CardTitle className="text-2xl font-serif">Compose Alert</CardTitle>
                    <CardDescription className="text-base">Push high-priority notifications to specific user clusters.</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <form onSubmit={handleBroadcast} className="space-y-6">
                      <div className="space-y-2.5">
                        <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Subject Line</label>
                        <Input 
                          placeholder="e.g. Critical Update: Payment Infrastructure" 
                          value={title}
                          onChange={(e) => setTitle(e.target.value)}
                          className="bg-zinc-50 dark:bg-zinc-950/50 h-14 border-none shadow-inner text-lg focus-visible:ring-primary/30"
                          required
                        />
                      </div>
                      <div className="space-y-2.5">
                        <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Message Architecture</label>
                        <textarea 
                          className="w-full min-h-[160px] rounded-xl border-none bg-zinc-50 dark:bg-zinc-950/50 px-5 py-4 text-lg focus:outline-none focus:ring-2 focus:ring-primary/20 shadow-inner resize-none overflow-hidden" 
                          placeholder="Draft your detailed system communication here..."
                          value={message}
                          onChange={(e) => setMessage(e.target.value)}
                          required
                        />
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2.5">
                          <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Distribution Target</label>
                          <select 
                             className="w-full h-14 rounded-xl border-none bg-zinc-50 dark:bg-zinc-950/50 px-4 text-lg shadow-inner appearance-none cursor-pointer"
                             value={target}
                             onChange={(e: any) => setTarget(e.target.value)}
                          >
                            <option value="all">Global (Everyone)</option>
                            <option value="workers">Verified Workers</option>
                            <option value="employers">Registered Employers</option>
                          </select>
                        </div>
                        <div className="flex items-end">
                          <Button 
                            type="submit" 
                            className="w-full gap-3 h-14 text-lg font-bold shadow-2xl hover:scale-[1.02] active:scale-[0.98] transition-all" 
                            disabled={mutation.isPending}
                          >
                            {mutation.isPending ? <Loader2 className="w-6 h-6 animate-spin" /> : <><Send className="w-5 h-5"/> Dispatch Now</>}
                          </Button>
                        </div>
                      </div>
                    </form>
                  </CardContent>
                </Card>
              </motion.div>
            )}

            {activeTab === "feed" && (
              <motion.div
                key="feed"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.3 }}
              >
                <Card className="no-line-card p-1">
                  <CardHeader className="pb-4">
                    <div className="flex justify-between items-center">
                      <CardTitle className="text-2xl font-serif">Draft Feed Post</CardTitle>
                      <Badge className="gold-gradient border-none text-zinc-900 font-bold px-3 py-1 flex gap-1.5 shadow-lg">
                        <ShieldCheck className="w-3.5 h-3.5" /> OFFICIAL
                      </Badge>
                    </div>
                    <CardDescription className="text-base">Publish verified content with optional media directly to the institutional feed.</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <form onSubmit={handleFeedPost} className="space-y-6">
                      <div className="space-y-2.5">
                        <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Content Body</label>
                        <textarea 
                          className="w-full min-h-[160px] rounded-xl border-none bg-zinc-50 dark:bg-zinc-950/50 px-5 py-4 text-xl leading-relaxed focus:outline-none focus:ring-2 focus:ring-emerald-500/20 shadow-inner resize-none overflow-hidden" 
                          placeholder="What would you like to share with the community?"
                          value={feedPost}
                          onChange={(e) => setFeedPost(e.target.value)}
                        />
                      </div>
                      
                      <div className="space-y-2.5">
                        <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Attach Media (Optional)</label>
                        <input 
                           type="file" 
                           accept="image/*,video/*"
                           className="hidden" 
                           ref={feedFileInputRef}
                           onChange={(e) => { if (e.target.files?.length) setFeedFile(e.target.files[0]) }} 
                         />
                        <div 
                          onClick={() => feedFileInputRef.current?.click()}
                          className="w-full h-16 rounded-xl border-2 border-dashed border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-950/50 flex items-center justify-center cursor-pointer hover:bg-zinc-100 dark:hover:bg-zinc-900 transition-colors"
                        >
                          {feedFile ? (
                            <span className="text-emerald-500 font-medium flex items-center gap-2"><ImageIcon className="w-5 h-5"/> {feedFile.name} (Ready to upload)</span>
                          ) : (
                            <span className="text-zinc-500 flex items-center gap-2"><UploadCloud className="w-5 h-5"/> Click to upload Image/Video</span>
                          )}
                        </div>
                      </div>

                      <Button 
                        type="submit" 
                        className="w-full gap-3 h-16 emerald-gradient hover:opacity-90 text-white text-xl font-black shadow-2xl transition-all hover:scale-[1.01]" 
                        disabled={feedMutation.isPending || (!feedPost && !feedFile)}
                      >
                        {feedMutation.isPending ? <Loader2 className="w-6 h-6 animate-spin" /> : <><Sparkles className="w-6 h-6"/> Publish to Social Index</>}
                      </Button>
                    </form>
                  </CardContent>
                </Card>
              </motion.div>
            )}

            {activeTab === "banners" && (
              <motion.div
                key="banners"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.3 }}
              >
                <Card className="no-line-card p-1">
                  <CardHeader className="pb-4">
                    <div className="flex justify-between items-center">
                      <CardTitle className="text-2xl font-serif">Global Ad Banners</CardTitle>
                    </div>
                    <CardDescription className="text-base">Configure the primary promotional banner displayed across mobile app dashboards.</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <form onSubmit={handleBannerSave} className="space-y-6">
                      
                      <div className="grid grid-cols-1 gap-6">
                        <div className="space-y-2.5">
                          <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Banner Headline (Optional)</label>
                          <Input 
                            placeholder="e.g. Unlock Premium Lead Packs" 
                            value={bannerHeadline}
                            onChange={(e) => setBannerHeadline(e.target.value)}
                            className="bg-zinc-50 dark:bg-zinc-950/50 h-14 border-none shadow-inner text-lg"
                          />
                        </div>
                        <div className="space-y-2.5">
                          <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Banner Subtext (Optional)</label>
                          <Input 
                            placeholder="e.g. Get 20% off your first credit purchase." 
                            value={bannerSubhead}
                            onChange={(e) => setBannerSubhead(e.target.value)}
                            className="bg-zinc-50 dark:bg-zinc-950/50 h-14 border-none shadow-inner text-lg"
                          />
                        </div>
                      </div>

                      <div className="space-y-2.5">
                        <label className="text-sm font-semibold uppercase tracking-wider text-zinc-500">Creative Asset (Required Image)</label>
                        <input 
                           type="file" 
                           accept="image/*"
                           className="hidden" 
                           ref={bannerFileInputRef}
                           onChange={(e) => { if (e.target.files?.length) setBannerFile(e.target.files[0]) }} 
                         />
                        <div 
                          onClick={() => bannerFileInputRef.current?.click()}
                          className="w-full h-32 rounded-xl border-2 border-dashed border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-950/50 flex flex-col items-center justify-center cursor-pointer hover:bg-zinc-100 dark:hover:bg-zinc-900 transition-colors"
                        >
                          {bannerFile ? (
                            <span className="text-emerald-500 font-medium flex items-center gap-2"><ImageIcon className="w-5 h-5"/> {bannerFile.name}</span>
                          ) : activeBanner?.imageUrl ? (
                             <div className="flex flex-col items-center gap-2">
                                <img src={activeBanner.imageUrl} alt="Current banner" className="h-16 rounded-md object-contain" />
                                <span className="text-xs text-zinc-500 font-medium flex items-center gap-2"><UploadCloud className="w-4 h-4"/> Click to replace image</span>
                             </div>
                          ) : (
                            <span className="text-zinc-500 flex flex-col items-center gap-2"><UploadCloud className="w-8 h-8"/> <span>Click to upload Banner Art</span></span>
                          )}
                        </div>
                      </div>

                      <Button 
                        type="submit" 
                        className="w-full gap-3 h-16 bg-gradient-to-r from-blue-600 to-indigo-600 hover:opacity-90 text-white text-xl font-black shadow-2xl transition-all hover:scale-[1.01]" 
                        disabled={bannerMutation.isPending || (!bannerFile && !activeBanner?.imageUrl)}
                      >
                        {bannerMutation.isPending ? <Loader2 className="w-6 h-6 animate-spin" /> : "Deploy Global Banner"}
                      </Button>
                    </form>
                  </CardContent>
                </Card>
              </motion.div>
            )}

          </AnimatePresence>
        </div>

        {/* Delivery Logs / Sidebar */}
        <div className="lg:col-span-5 space-y-6">
           <Card className="no-line-card p-1 h-full max-h-[850px] flex flex-col"> 
             <CardHeader className="shrink-0 space-y-4">
               <div className="flex items-center justify-between">
                 <CardTitle className="flex items-center gap-3 text-2xl font-serif">
                   <History className="w-6 h-6 text-primary" /> Delivery Logs
                 </CardTitle>
                 <Badge variant="outline" className="border-primary/20 text-primary font-mono text-xs">
                   {logTab === "announcements" ? (recent?.length || 0) : (adminPosts?.length || 0)} RECORDS
                 </Badge>
               </div>
               
               {/* Internal Logs Switcher */}
               <div className="grid grid-cols-2 p-1 bg-zinc-100 dark:bg-zinc-900 rounded-lg text-xs font-bold">
                  <button 
                    onClick={() => setLogTab("announcements")}
                    className={cn(
                      "py-2 rounded-md transition-all",
                      logTab === "announcements" ? "bg-white dark:bg-zinc-800 shadow-sm text-primary" : "text-zinc-500"
                    )}
                  >
                    System Alerts
                  </button>
                  <button 
                    onClick={() => setLogTab("posts")}
                    className={cn(
                      "py-2 rounded-md transition-all",
                      logTab === "posts" ? "bg-white dark:bg-zinc-800 shadow-sm text-primary" : "text-zinc-500"
                    )}
                  >
                    Admin Posts
                  </button>
               </div>
             </CardHeader>
             
             <CardContent className="flex-1 overflow-y-auto custom-scrollbar">
               <AnimatePresence mode="wait">
                 {isLoading || isLoadingPosts ? (
                   <div key="loading" className="py-20 flex flex-col items-center gap-4">
                     <Loader2 className="animate-spin text-primary w-12 h-12"/>
                     <p className="text-zinc-500 font-medium animate-pulse">Syncing institutional records...</p>
                   </div>
                 ) : (
                   <motion.div 
                    key={logTab}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="space-y-4"
                   >
                     {logTab === "announcements" ? (
                       recent?.length === 0 ? (
                         <div className="text-center py-20 px-8">
                           <History className="w-12 h-12 text-zinc-300 mx-auto mb-4" />
                           <p className="text-zinc-500 font-serif italic">No alerts found.</p>
                         </div>
                       ) : (
                         recent?.map((item: any, idx: number) => (
                           <motion.div 
                             initial={{ opacity: 0, x: 20 }}
                             animate={{ opacity: 1, x: 0 }}
                             transition={{ delay: idx * 0.05 }}
                             key={item.id} 
                             className="p-5 rounded-2xl bg-zinc-50/50 dark:bg-zinc-900/40 border border-white/5"
                           >
                             <div className="flex justify-between items-start mb-2">
                                <h4 className="font-bold text-base leading-tight">{item.title}</h4>
                                <Badge className="text-[9px] uppercase font-black px-1.5 py-0.5 bg-zinc-200 text-zinc-700">
                                  {item.target}
                                </Badge>
                             </div>
                             <p className="text-xs text-zinc-500 line-clamp-2 italic">{item.message}</p>
                           </motion.div>
                         ))
                       )
                     ) : (
                        adminPosts?.length === 0 ? (
                          <div className="text-center py-20 px-8">
                            <Globe className="w-12 h-12 text-zinc-300 mx-auto mb-4" />
                            <p className="text-zinc-500 font-serif italic">No feed posts found.</p>
                          </div>
                        ) : (
                          adminPosts?.map((post: any, idx: number) => (
                            <motion.div 
                              initial={{ opacity: 0, x: 20 }}
                              animate={{ opacity: 1, x: 0 }}
                              transition={{ delay: idx * 0.05 }}
                              key={post.id} 
                              className="p-5 rounded-2xl bg-primary/5 dark:bg-primary/10 border border-primary/10 hover:border-primary/30 transition-all cursor-default"
                            >
                              <div className="flex items-center gap-2 mb-3">
                                <ShieldCheck className="w-4 h-4 text-primary" />
                                <span className="text-[10px] font-black uppercase tracking-wider text-primary">OFFICIAL FEED POST</span>
                              </div>
                              <p className="text-sm font-medium line-clamp-3 leading-relaxed mb-4">{post.text}</p>
                              {post.imageUrl && (
                                <img src={post.imageUrl} alt="attached" className="w-full h-32 object-cover rounded-md mb-2 opacity-80" />
                              )}
                              <div className="flex items-center justify-between">
                                <div className="flex gap-4 text-zinc-400">
                                  <div className="flex items-center gap-1.5"><Heart className="w-3.5 h-3.5"/> <span className="text-xs font-bold">{post.likes}</span></div>
                                  <div className="flex items-center gap-1.5"><MessageSquare className="w-3.5 h-3.5"/> <span className="text-xs font-bold">{post.comments}</span></div>
                                </div>
                                <span className="text-[10px] text-zinc-400 font-bold">
                                  {post.createdAt?.toDate ? post.createdAt.toDate().toLocaleDateString() : "RECENT"}
                                </span>
                              </div>
                            </motion.div>
                          ))
                        )
                     )}
                   </motion.div>
                 )}
               </AnimatePresence>
             </CardContent>
           </Card>
        </div>
      </div>
    </div>
  );
}
