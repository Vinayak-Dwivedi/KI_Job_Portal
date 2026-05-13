import { useState, useRef, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Send,
  Loader2,
  Sparkles,
  ChevronDown,
  Mic,
  RotateCcw,
  CheckCircle,
  XCircle,
  Copy,
  Check,
  AlertTriangle,
  Zap,
} from "lucide-react";
import { sendMessage, extractToolCall, stripToolCall } from "@/lib/ai/gemini";
import { dispatchTool, executeConfirmedAction } from "@/lib/ai/toolExecutor";
import { useAuth } from "@/providers/AuthContext";
import { toast } from "sonner";
import type { GeminiMessage } from "@/lib/ai/gemini";

// ─── Types ──────────────────────────────────────────────────────────────────

interface PendingAction {
  type: string;
  payload: Record<string, unknown>;
  label: string;
}

interface ChatMessage {
  id: string;
  role: "user" | "model" | "system";
  content: string;
  timestamp: Date;
  isStreaming?: boolean;
  pendingAction?: PendingAction;
  toolStatus?: string;
}

// ─── Quick Action Chips ──────────────────────────────────────────────────────

const QUICK_ACTIONS = [
  { label: "📊 Users today", prompt: "How many new users joined today?" },
  { label: "📋 Jobs this week", prompt: "How many jobs were posted this week?" },
  { label: "🚩 Flagged users", prompt: "Show me all flagged/blocked users" },
  { label: "📄 Unapproved jobs", prompt: "List all unapproved job posts" },
  { label: "📈 Weekly report", prompt: "Generate a weekly platform report" },
  { label: "📢 Notify all", prompt: "Send a notification to all users" },
];

// ─── Simple Markdown Renderer ────────────────────────────────────────────────

function renderMarkdown(text: string): string {
  return text
    .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
    .replace(/\*(.*?)\*/g, "<em>$1</em>")
    .replace(/`(.*?)`/g, '<code class="ai-code">$1</code>')
    .replace(/^### (.*$)/gm, '<h4 class="ai-h4">$1</h4>')
    .replace(/^## (.*$)/gm, '<h3 class="ai-h3">$1</h3>')
    .replace(/^# (.*$)/gm, '<h2 class="ai-h2">$1</h2>')
    .replace(/^- (.*$)/gm, '<li class="ai-li">$1</li>')
    .replace(/(<li class="ai-li">.*<\/li>\n?)+/g, '<ul class="ai-ul">$&</ul>')
    .replace(/\n\n/g, '<br/><br/>')
    .replace(/\n/g, "<br/>");
}

// ─── Copy Button ──────────────────────────────────────────────────────────────

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  const copy = () => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  return (
    <button
      onClick={copy}
      className="p-1 rounded-md text-zinc-500 hover:text-zinc-300 transition-colors"
      title="Copy"
    >
      {copied ? <Check size={12} /> : <Copy size={12} />}
    </button>
  );
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

function MessageBubble({
  msg,
  adminName,
  onConfirmAction,
}: {
  msg: ChatMessage;
  adminName: string;
  onConfirmAction: (action: PendingAction) => void;
}) {
  const isUser = msg.role === "user";
  const isSystem = msg.role === "system";

  if (isSystem) {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex justify-center"
      >
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-white/10 text-xs text-zinc-500 font-medium">
          {msg.content.includes("✅") ? (
            <CheckCircle size={12} className="text-emerald-400" />
          ) : msg.content.includes("❌") ? (
            <XCircle size={12} className="text-red-400" />
          ) : (
            <Zap size={12} className="text-primary" />
          )}
          {msg.content}
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2 }}
      className={`flex items-end gap-2.5 ${isUser ? "flex-row-reverse" : "flex-row"}`}
    >
      {/* Avatar */}
      {!isUser ? (
        <div className="flex-shrink-0 h-8 w-8 rounded-xl overflow-hidden border border-white/10 shadow-[0_0_10px_rgba(0,180,255,0.25)]">
          <img src="/copilot-bot.jpg" alt="Copilot" className="w-full h-full object-cover" />
        </div>
      ) : (
        <div className="flex-shrink-0 h-7 w-7 rounded-xl bg-zinc-700 border border-white/10 flex items-center justify-center">
          <span className="text-[10px] font-black text-zinc-300 uppercase">
            {(adminName || "AD").substring(0, 2)}
          </span>
        </div>
      )}

      {/* Bubble */}
      <div className={`flex flex-col gap-1.5 max-w-[82%] ${isUser ? "items-end" : "items-start"}`}>
        {/* Tool status */}
        {msg.toolStatus && (
          <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-primary/10 border border-primary/20 text-[10px] font-bold text-primary uppercase tracking-wide">
            <Loader2 size={10} className="animate-spin" />
            {msg.toolStatus}
          </div>
        )}

        {/* Content bubble */}
        {msg.content && (
          <div
            className={`relative group px-4 py-3 rounded-2xl text-sm leading-relaxed ${
              isUser
                ? "bg-primary/15 border border-primary/25 text-zinc-100 rounded-br-sm"
                : "bg-[#161B22] border border-white/8 text-zinc-200 rounded-bl-sm"
            }`}
          >
            {isUser ? (
              <span>{msg.content}</span>
            ) : (
              <>
                <div
                  className="ai-content"
                  dangerouslySetInnerHTML={{ __html: renderMarkdown(msg.content) }}
                />
                {msg.isStreaming && (
                  <span className="inline-block w-1.5 h-4 bg-primary/70 rounded-sm ml-1 animate-pulse" />
                )}
                {!msg.isStreaming && (
                  <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <CopyButton text={msg.content} />
                  </div>
                )}
              </>
            )}
          </div>
        )}

        {/* Pending action confirmation */}
        {msg.pendingAction && !msg.isStreaming && (
          <motion.div
            initial={{ opacity: 0, y: 5 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center gap-2"
          >
            <div className="flex items-center gap-1.5 px-2 py-1 rounded-lg bg-amber-500/10 border border-amber-500/20 text-[10px] font-bold text-amber-400 uppercase tracking-wide">
              <AlertTriangle size={10} />
              Confirmation Required
            </div>
            <button
              onClick={() => onConfirmAction(msg.pendingAction!)}
              className="px-3 py-1.5 rounded-xl bg-primary/90 hover:bg-primary text-white text-xs font-bold transition-all hover:scale-105 shadow-[0_0_15px_rgba(var(--primary),0.3)]"
            >
              {msg.pendingAction.label}
            </button>
          </motion.div>
        )}

        {/* Timestamp */}
        <span className="text-[10px] text-zinc-600 font-medium px-1">
          {msg.timestamp.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
        </span>
      </div>
    </motion.div>
  );
}

// ─── Main Admin Copilot Component ─────────────────────────────────────────────

export default function AdminCopilot() {
  const { user } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: "welcome",
      role: "model",
      content:
        "👋 Hey! I'm your **Admin Copilot**. I can fetch real-time analytics, manage users, moderate jobs, send notifications, and much more.\n\nTry asking me something or use the quick actions below!",
      timestamp: new Date(),
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const [showQuickActions, setShowQuickActions] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const streamingMsgIdRef = useRef<string | null>(null);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // Focus input when opened
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 300);
    }
  }, [isOpen]);

  // Build Gemini conversation history (exclude system messages)
  const buildHistory = useCallback((): GeminiMessage[] => {
    return messages
      .filter((m) => m.role !== "system" && m.content)
      .map((m) => ({
        role: m.role as "user" | "model",
        parts: [{ text: m.content }],
      }));
  }, [messages]);

  const addMessage = (msg: Partial<ChatMessage> & { role: ChatMessage["role"]; content: string }) => {
    const id = `msg_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    const fullMsg: ChatMessage = {
      id,
      timestamp: new Date(),
      ...msg,
    };
    setMessages((prev) => [...prev, fullMsg]);
    return id;
  };

  const updateMessage = (id: string, updates: Partial<ChatMessage>) => {
    setMessages((prev) =>
      prev.map((m) => (m.id === id ? { ...m, ...updates } : m))
    );
  };

  // Handle confirmed action (ban, notify, etc.)
  const handleConfirmAction = async (action: PendingAction) => {
    setIsLoading(true);
    const result = await executeConfirmedAction(action.type, action.payload);
    setIsLoading(false);

    addMessage({
      role: "system",
      content: result.message,
    });

    if (result.success) {
      toast.success("Action Executed", { description: result.message });
    } else {
      toast.error("Action Failed", { description: result.message });
    }
  };

  // Main send handler
  const handleSend = async (userText?: string) => {
    const text = (userText || input).trim();
    if (!text || isLoading) return;
    setInput("");
    setShowQuickActions(false);
    setIsLoading(true);

    // Add user message
    addMessage({ role: "user", content: text });

    // Build conversation history BEFORE adding assistant placeholder
    const history = buildHistory();

    // Add placeholder streaming message
    const assistantMsgId = addMessage({
      role: "model",
      content: "",
      isStreaming: true,
      toolStatus: "Thinking...",
    });
    streamingMsgIdRef.current = assistantMsgId;

    try {
      // Build messages for Gemini API
      const geminiMessages: GeminiMessage[] = [
        ...history,
        { role: "user", parts: [{ text }] },
      ];

      let accumulated = "";

      const rawResponse = await sendMessage(geminiMessages, (chunk) => {
        accumulated += chunk;
        const visible = stripToolCall(accumulated);
        updateMessage(assistantMsgId, {
          content: visible,
          toolStatus: undefined,
        });
      });

      // Check if AI requested a tool call
      const toolCall = extractToolCall(rawResponse);

      if (toolCall) {
        updateMessage(assistantMsgId, {
          content: stripToolCall(rawResponse),
          toolStatus: `Fetching: ${toolCall.tool.replace(/_/g, " ")}...`,
          isStreaming: false,
        });

        // Execute the tool
        const toolResult = await dispatchTool(
          toolCall.tool,
          toolCall.params as Record<string, unknown>
        );

        // Remove tool status
        updateMessage(assistantMsgId, { toolStatus: undefined });

        // Send tool result back to Gemini for final response
        const followUpMessages: GeminiMessage[] = [
          ...geminiMessages,
          { role: "model", parts: [{ text: rawResponse }] },
          {
            role: "user",
            parts: [
              {
                text: `[TOOL RESULT for ${toolCall.tool}]: ${toolResult.summary}\n\nData: ${JSON.stringify(toolResult.data || {}, null, 2)}\n\nNow provide a clear, helpful response to the admin based on this data. If there's an action available, present it clearly.`,
              },
            ],
          },
        ];

        let finalAccumulated = "";
        await sendMessage(followUpMessages, (chunk) => {
          finalAccumulated += chunk;
          updateMessage(assistantMsgId, {
            content: finalAccumulated,
            isStreaming: true,
          });
        });

        updateMessage(assistantMsgId, {
          content: finalAccumulated,
          isStreaming: false,
          pendingAction: toolResult.action,
        });
      } else {
        updateMessage(assistantMsgId, {
          content: stripToolCall(rawResponse),
          isStreaming: false,
        });
      }
    } catch (err) {
      updateMessage(assistantMsgId, {
        content: `❌ Error: ${err instanceof Error ? err.message : "Something went wrong"}`,
        isStreaming: false,
      });
    } finally {
      setIsLoading(false);
      streamingMsgIdRef.current = null;
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const clearChat = () => {
    setMessages([
      {
        id: "welcome-reset",
        role: "model",
        content: "Chat cleared. How can I help you?",
        timestamp: new Date(),
      },
    ]);
    setShowQuickActions(true);
  };

  return (
    <>
      {/* ── Floating Trigger Button ── */}
      <motion.div
        className="fixed bottom-6 right-6 z-[9999]"
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ type: "spring", stiffness: 300, delay: 1 }}
      >
        <AnimatePresence>
          {!isOpen && (
            <motion.button
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0, opacity: 0 }}
              onClick={() => setIsOpen(true)}
              className="relative flex items-center justify-center h-14 w-14 rounded-2xl bg-primary shadow-[0_0_30px_rgba(var(--primary),0.5)] hover:shadow-[0_0_40px_rgba(var(--primary),0.7)] hover:scale-110 transition-all duration-200 group"
            >
              <img src="/copilot-bot.jpg" alt="Copilot" className="w-10 h-10 object-cover rounded-xl" />
              {/* Pulse ring */}
              <span className="absolute inset-0 rounded-2xl animate-ping bg-primary/20" />
              {/* Tooltip */}
              <div className="absolute right-full mr-3 px-3 py-1.5 rounded-xl bg-[#161B22] border border-white/10 text-xs font-bold text-white whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity shadow-xl">
                Admin Copilot
                <Sparkles size={10} className="inline ml-1 text-primary" />
              </div>
            </motion.button>
          )}
        </AnimatePresence>
      </motion.div>

      {/* ── Chat Panel ── */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20, x: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0, x: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20, x: 20 }}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
            className="fixed bottom-6 right-6 z-[9999] w-[420px] h-[640px] flex flex-col rounded-[28px] overflow-hidden shadow-[0_25px_80px_rgba(0,0,0,0.8),0_0_0_1px_rgba(255,255,255,0.06)] bg-[#0D1117]"
            style={{ backdropFilter: "blur(40px)" }}
          >
            {/* ─ Header ─ */}
            <div className="flex-shrink-0 flex items-center justify-between px-5 py-4 bg-gradient-to-r from-[#0F131A] to-[#0D1117] border-b border-white/5">
              <div className="flex items-center gap-3">
                <div className="relative h-9 w-9 rounded-xl overflow-hidden border border-white/10 shadow-[0_0_15px_rgba(0,180,255,0.3)]">
                  <img src="/copilot-bot.jpg" alt="Copilot" className="w-full h-full object-cover" />
                  <div className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full bg-emerald-400 border-2 border-[#0D1117]" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-black text-sm text-white tracking-tight">
                      Admin Copilot
                    </h3>
                    <span className="px-1.5 py-0.5 rounded-md bg-primary/15 border border-primary/25 text-[9px] font-black text-primary uppercase tracking-widest">
                      AI
                    </span>
                  </div>
                  <p className="text-[10px] text-zinc-500 font-medium">
                    Powered by Gemini 2.0 Flash
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1">
                <button
                  onClick={clearChat}
                  className="p-2 rounded-xl text-zinc-500 hover:text-zinc-300 hover:bg-white/5 transition-all"
                  title="Clear chat"
                >
                  <RotateCcw size={15} />
                </button>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-2 rounded-xl text-zinc-500 hover:text-zinc-300 hover:bg-white/5 transition-all"
                >
                  <ChevronDown size={15} />
                </button>
              </div>
            </div>

            {/* ─ Messages ─ */}
            <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 custom-scrollbar">
              {messages.map((msg) => (
                <MessageBubble
                  key={msg.id}
                  msg={msg}
                  adminName={user?.name || "Admin"}
                  onConfirmAction={handleConfirmAction}
                />
              ))}

              {/* Quick Actions (shown initially) */}
              {showQuickActions && messages.length <= 1 && (
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                  className="grid grid-cols-2 gap-2 pt-2"
                >
                  {QUICK_ACTIONS.map((action) => (
                    <button
                      key={action.label}
                      onClick={() => handleSend(action.prompt)}
                      disabled={isLoading}
                      className="text-left px-3 py-2.5 rounded-2xl bg-white/4 border border-white/8 text-xs font-semibold text-zinc-400 hover:text-zinc-200 hover:bg-white/8 hover:border-white/15 transition-all duration-150 disabled:opacity-50"
                    >
                      {action.label}
                    </button>
                  ))}
                </motion.div>
              )}

              <div ref={messagesEndRef} />
            </div>

            {/* ─ Input ─ */}
            <div className="flex-shrink-0 p-4 border-t border-white/5 bg-[#0F131A]/80">
              <div className="flex items-end gap-2.5 rounded-2xl bg-white/5 border border-white/10 focus-within:border-primary/40 focus-within:bg-primary/5 transition-all px-4 py-2.5">
                <textarea
                  ref={inputRef}
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Ask anything or give a command..."
                  rows={1}
                  disabled={isLoading}
                  className="flex-1 bg-transparent text-sm text-zinc-200 placeholder-zinc-600 resize-none outline-none leading-relaxed disabled:opacity-50 max-h-24"
                  style={{ scrollbarWidth: "none" }}
                />
                <div className="flex items-center gap-1.5 flex-shrink-0 pb-0.5">
                  <button
                    className="p-1.5 rounded-lg text-zinc-600 hover:text-zinc-400 transition-colors"
                    title="Voice input (coming soon)"
                  >
                    <Mic size={14} />
                  </button>
                  <button
                    onClick={() => handleSend()}
                    disabled={!input.trim() || isLoading}
                    className="p-2 rounded-xl bg-primary/90 hover:bg-primary text-white transition-all hover:scale-105 disabled:opacity-40 disabled:hover:scale-100 shadow-[0_0_10px_rgba(var(--primary),0.3)]"
                  >
                    {isLoading ? (
                      <Loader2 size={14} className="animate-spin" />
                    ) : (
                      <Send size={14} />
                    )}
                  </button>
                </div>
              </div>
              <p className="text-[10px] text-zinc-700 text-center mt-2 font-medium">
                Press Enter to send · Shift+Enter for new line
              </p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ─ Global AI Content Styles ─ */}
      <style>{`
        .ai-content { line-height: 1.65; }
        .ai-content .ai-h2 { font-size: 0.95rem; font-weight: 800; color: white; margin: 10px 0 6px; }
        .ai-content .ai-h3 { font-size: 0.875rem; font-weight: 700; color: #e4e4e7; margin: 8px 0 4px; }
        .ai-content .ai-h4 { font-size: 0.8rem; font-weight: 700; color: #a1a1aa; margin: 6px 0 3px; }
        .ai-content .ai-code { 
          font-family: 'Geist Mono', monospace; 
          font-size: 0.78rem; 
          background: rgba(255,255,255,0.08); 
          border: 1px solid rgba(255,255,255,0.1); 
          border-radius: 5px; 
          padding: 1px 5px;
          color: hsl(var(--primary));
        }
        .ai-content .ai-ul { padding-left: 1.2rem; margin: 4px 0; }
        .ai-content .ai-li { margin: 3px 0; list-style-type: disc; color: #d4d4d8; }
        .ai-content strong { color: #f4f4f5; font-weight: 700; }
        .ai-content em { color: #a1a1aa; font-style: italic; }
      `}</style>
    </>
  );
}
