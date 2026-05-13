import { useState, useEffect, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useSearchParams } from "react-router-dom";
import { 
  Loader2, 
  Send, 
  Search, 
  MoreVertical, 
  Phone, 
  Video, 
  Info,
  Check,
  CheckCheck,
  MessageCircle
} from "lucide-react";
import { format } from "date-fns";
import { motion } from "framer-motion";

import { fetchAllChats, fetchMessages, replyToChat } from "@/lib/api/chats";
import { useAuth } from "@/providers/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function Chats() {
  const queryClient = useQueryClient();
  const [searchParams] = useSearchParams();
  const userIdParam = searchParams.get("userId");
  const { user: adminUser } = useAuth();
  const [selectedChatId, setSelectedChatId] = useState<string | null>(null);
  const [message, setMessage] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);

  const { data: chats = [], isLoading: isChatsLoading } = useQuery({
    queryKey: ["all_chats"],
    queryFn: fetchAllChats,
    refetchInterval: 5000, 
  });

  // Auto-select chat if userId is in params
  useEffect(() => {
    if (userIdParam && chats.length > 0) {
      const targetChat = chats.find((c: any) => 
        c.members.includes(userIdParam) && c.members.includes(adminUser?.uid)
      );
      if (targetChat) {
        setSelectedChatId(targetChat.id);
      }
    }
  }, [userIdParam, chats, adminUser]);

  const { data: messages = [], isLoading: isMessagesLoading } = useQuery({
    queryKey: ["messages", selectedChatId],
    queryFn: () => fetchMessages(selectedChatId!),
    enabled: !!selectedChatId,
    refetchInterval: 3000, // Poll faster for active chat
  });

  const sendMutation = useMutation({
    mutationFn: async () => {
      if (!selectedChatId || !message.trim()) return;
      const chat = (chats as any[]).find(c => c.id === selectedChatId);
      if (!chat) return;
      const targetUid = chat.members.find((m: string) => m !== adminUser?.uid);
      return replyToChat(selectedChatId, message, targetUid);
    },
    onSuccess: () => {
      setMessage("");
      queryClient.invalidateQueries({ queryKey: ["messages", selectedChatId] });
      queryClient.invalidateQueries({ queryKey: ["all_chats"] });
    }
  });

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const filteredChats = chats.filter((chat: any) => {
    const otherMemberId = chat.members.find((m: string) => m !== adminUser?.uid);
    const otherMember = chat.memberData?.[otherMemberId] || {};
    return (otherMember.name || "User").toLowerCase().includes(searchQuery.toLowerCase());
  });

  const selectedChat = (chats as any[]).find((c: any) => c.id === selectedChatId);
  const otherMemberId = selectedChat?.members?.find((m: string) => m !== adminUser?.uid);
  const otherMember = selectedChat?.memberData?.[otherMemberId] || {};

  return (
    <div className="h-[calc(100vh-140px)] flex gap-6 overflow-hidden">
      {/* Sidebar - Chat List */}
      <div className="w-80 flex flex-col gap-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input 
            placeholder="Search conversations..." 
            className="pl-10 bg-white/5 border-white/10"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="flex-1 glass-card rounded-3xl overflow-hidden flex flex-col border border-white/5">
          <div className="p-4 border-b border-white/5 bg-white/5">
            <h3 className="font-bold text-sm uppercase tracking-widest text-primary flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-primary animate-pulse" />
              Active Threads
            </h3>
          </div>
          
          <div className="flex-1 overflow-y-auto custom-scrollbar">
            {isChatsLoading ? (
              <div className="p-10 flex justify-center"><Loader2 className="animate-spin text-primary" /></div>
            ) : filteredChats.length === 0 ? (
              <div className="p-10 text-center text-muted-foreground text-sm italic">No chats found.</div>
            ) : (
              <div className="divide-y divide-white/5">
                {filteredChats.map((chat: any) => {
                  const mId = chat.members.find((m: string) => m !== adminUser?.uid);
                  const m = chat.memberData?.[mId] || {};
                  const isActive = selectedChatId === chat.id;
                  
                  return (
                    <button
                      key={chat.id}
                      onClick={() => setSelectedChatId(chat.id)}
                      className={`w-full text-left p-4 transition-all duration-200 hover:bg-white/5 flex gap-3 group ${isActive ? "bg-primary/10 border-l-4 border-primary" : "border-l-4 border-transparent"}`}
                    >
                      <div className="h-12 w-12 rounded-full border border-white/10 overflow-hidden flex-shrink-0 bg-primary/20 flex items-center justify-center">
                        {m.photoUrl ? (
                          <img src={m.photoUrl} alt={m.name} className="h-full w-full object-cover" />
                        ) : (
                          <span className="text-primary font-bold">{(m.name || "U").substring(0, 1)}</span>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex justify-between items-start mb-1">
                          <h4 className={`font-bold text-sm truncate ${isActive ? "text-primary" : "text-white"}`}>
                            {m.name || "Unknown User"}
                          </h4>
                          {chat.lastMessageTime && (
                            <span className="text-[10px] text-muted-foreground whitespace-nowrap">
                              {format(chat.lastMessageTime.toDate(), "HH:mm")}
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-muted-foreground truncate leading-relaxed">
                          {chat.lastMessage || "Start conversation..."}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 glass-card rounded-3xl overflow-hidden flex flex-col border border-white/5 relative">
        {selectedChatId ? (
          <>
            {/* Chat Header */}
            <header className="p-4 border-b border-white/5 flex items-center justify-between bg-white/5">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-full border border-primary/20 overflow-hidden bg-primary/20 flex items-center justify-center">
                  {otherMember.photoUrl ? (
                    <img src={otherMember.photoUrl} alt={otherMember.name} className="h-full w-full object-cover" />
                  ) : (
                    <span className="text-primary font-bold">{(otherMember.name || "U").substring(0, 1)}</span>
                  )}
                </div>
                <div>
                  <h3 className="font-bold text-white text-sm">{otherMember.name || "Unknown User"}</h3>
                  <div className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]" />
                    <span className="text-[10px] text-muted-foreground font-medium uppercase tracking-wider">User Online</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-1">
                <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white rounded-full">
                  <Phone className="h-4 w-4" />
                </Button>
                <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white rounded-full">
                  <Video className="h-4 w-4" />
                </Button>
                <div className="mx-2 h-4 w-px bg-white/10" />
                <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-white rounded-full">
                  <Info className="h-4 w-4" />
                </Button>
              </div>
            </header>

            {/* Messages */}
            <div 
              ref={scrollRef}
              className="flex-1 overflow-y-auto p-6 space-y-4 custom-scrollbar bg-black/20"
            >
              {isMessagesLoading ? (
                <div className="h-full flex items-center justify-center">
                  <Loader2 className="h-8 w-8 animate-spin text-primary" />
                </div>
              ) : messages.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-center p-10">
                  <div className="h-20 w-20 rounded-full bg-primary/10 flex items-center justify-center mb-4">
                    <MessageCircle className="h-10 w-10 text-primary" />
                  </div>
                  <h4 className="text-white font-bold mb-2">Secure Connection Established</h4>
                  <p className="text-muted-foreground text-xs max-w-[200px]">
                    This conversation is private. Messages are stored securely on KI servers.
                  </p>
                </div>
              ) : (
                (messages as any[]).map((msg: any) => {
                  const isMe = msg.senderId === adminUser?.uid;
                  
                  return (
                    <motion.div
                      initial={{ opacity: 0, y: 10, scale: 0.95 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      key={msg.id}
                      className={`flex gap-3 ${isMe ? "flex-row-reverse" : "flex-row"}`}
                    >
                      <div className={`flex flex-col ${isMe ? "items-end" : "items-start"} max-w-[70%]`}>
                        <span className="text-[10px] text-muted-foreground font-bold mb-1 px-1 uppercase tracking-tighter">
                          {isMe ? "Admin" : (selectedChat?.memberData?.[msg.senderId]?.name || "User")}
                        </span>
                        <div 
                          className={`px-4 py-2.5 rounded-2xl text-sm leading-relaxed shadow-sm ${
                            isMe 
                              ? "bg-primary text-white rounded-tr-none" 
                              : "bg-white/10 text-zinc-100 rounded-tl-none border border-white/5"
                          }`}
                        >
                          {msg.text}
                        </div>
                        <div className="flex items-center gap-1.5 mt-1.5 px-1">
                          <span className="text-[10px] text-muted-foreground font-medium">
                            {msg.timestamp ? format(msg.timestamp.toDate(), "HH:mm") : "Sending..."}
                          </span>
                          {isMe && <CheckCheck className="h-3 w-3 text-primary" />}
                        </div>
                      </div>
                    </motion.div>
                  );
                })
              )}
            </div>

            {/* Input Area */}
            <div className="p-4 bg-white/5 border-t border-white/5">
              <form 
                onSubmit={(e) => {
                  e.preventDefault();
                  sendMutation.mutate();
                }}
                className="relative flex items-center gap-3"
              >
                <div className="flex-1 relative">
                  <Input 
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder="Type your message here..."
                    className="pr-12 bg-black/40 border-white/10 h-12 rounded-2xl focus-visible:ring-primary/50"
                  />
                  <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
                    <Button type="button" variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground rounded-full hover:bg-white/5">
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
                <Button 
                  disabled={!message.trim() || sendMutation.isPending}
                  className="h-12 w-12 rounded-2xl bg-primary hover:bg-primary/90 shadow-[0_0_20px_rgba(var(--primary),0.3)] flex-shrink-0"
                >
                  {sendMutation.isPending ? <Loader2 className="h-5 w-5 animate-spin" /> : <Send className="h-5 w-5" />}
                </Button>
              </form>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-center p-20">
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="relative mb-8"
            >
              <div className="h-32 w-32 rounded-[40px] bg-primary/10 flex items-center justify-center animate-pulse">
                <MessageCircle className="h-16 w-16 text-primary" />
              </div>
              <div className="absolute -bottom-2 -right-2 h-10 w-10 rounded-full bg-green-500 border-4 border-[#0F131A] flex items-center justify-center shadow-lg">
                <Check className="h-6 w-6 text-white" />
              </div>
            </motion.div>
            <h2 className="text-2xl font-black text-white mb-3 uppercase tracking-tight">Admin Support Center</h2>
            <p className="text-muted-foreground text-sm max-w-sm mx-auto leading-relaxed">
              Select a conversation from the sidebar to start responding to users in real-time.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
