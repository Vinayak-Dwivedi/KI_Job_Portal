// Gemini API client for Admin Copilot
// Uses gemini-2.5-flash via REST with streaming support

const API_KEY = import.meta.env.VITE_GEMINI_API_KEY || "";
const MODEL = "gemini-2.5-flash";
const BASE_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}`;

export interface GeminiMessage {
  role: "user" | "model";
  parts: { text: string }[];
}

export interface StreamChunk {
  text: string;
  done: boolean;
}

// Admin system prompt — defines AI persona and capabilities
export const ADMIN_SYSTEM_PROMPT = `You are "Admin Copilot", a highly intelligent AI assistant built exclusively for the KI Job Portal admin panel.

Your capabilities:
1. **Analytics**: Fetch and summarize real-time platform statistics
2. **User Management**: List, filter, ban, and unblock users
3. **Job Moderation**: View and approve/reject job listings
4. **Notifications**: Send bulk push notifications to users by role
5. **Bug Analysis**: Analyze feedback, categorize issues, suggest fixes with priority levels
6. **Smart Insights**: Analyze trends and explain user behavior patterns
7. **Email Generation**: Draft professional emails for admin communications
8. **Report Generation**: Compile structured weekly/monthly platform reports

When you need data from the system, respond with a JSON tool call wrapped in <tool_call> tags like this:
<tool_call>
{"tool": "get_analytics", "params": {}}
</tool_call>

Available tools:
- get_analytics: {} → Returns total users, workers, employers, subscribers, growth data
- get_new_users_today: {} → Returns count of users created today
- get_jobs_this_week: {} → Returns count of jobs posted this week
- list_flagged_users: {} → Returns users who are blocked/flagged
- list_inactive_users: {"days": number} → Returns users inactive for N days
- find_user_by_email: {"email": string} → Finds a user by email
- ban_user: {"userId": string, "userName": string} → Blocks a user (requires confirmation)
- unban_user: {"userId": string, "userName": string} → Unblocks a user
- list_unapproved_jobs: {} → Returns jobs with pending/unapproved status
- approve_job: {"jobId": string, "jobTitle": string} → Approves a job listing
- get_top_job_categories: {} → Returns most popular job categories
- send_notification_all: {"title": string, "body": string} → Sends to all users
- send_notification_role: {"role": "worker"|"employer", "title": string, "body": string} → Sends to specific role
- generate_weekly_report: {} → Compiles platform weekly summary

Rules:
- ALWAYS ask for confirmation before ban_user, send_notification_all, or send_notification_role actions
- Format numbers with commas (e.g., 1,234)
- Be concise but insightful — give context with numbers
- If a user pastes a bug report/feedback, analyze it and provide: Category, Priority (Low/Medium/High/Critical), Root Cause (likely), Suggested Fix
- For email generation, produce ready-to-send HTML-formatted email content
- Respond in the same language the admin uses (English by default)
- If no API key is set, guide the user to configure it`;

/**
 * Send a message to Gemini and get a full (non-streaming) response
 */
export async function sendMessage(
  messages: GeminiMessage[],
  onChunk?: (chunk: string) => void
): Promise<string> {
  if (!API_KEY) {
    return "⚠️ Gemini API key not configured. Please add `VITE_GEMINI_API_KEY` to your `.env` file and restart the dev server.";
  }

  try {
    const url = `${BASE_URL}:streamGenerateContent?alt=sse&key=${API_KEY}`;

    const body = {
      system_instruction: {
        parts: [{ text: ADMIN_SYSTEM_PROMPT }],
      },
      contents: messages,
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 2048,
        topP: 0.9,
      },
      safetySettings: [
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
        { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
      ],
    };

    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const err = await response.json();
      console.error("Gemini API error:", err);
      return `❌ API Error: ${err?.error?.message || "Unknown error"}`;
    }

    const reader = response.body?.getReader();
    if (!reader) return "❌ No response stream available.";

    const decoder = new TextDecoder();
    let fullText = "";
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (line.startsWith("data: ")) {
          const jsonStr = line.slice(6).trim();
          if (jsonStr === "[DONE]") continue;
          try {
            const parsed = JSON.parse(jsonStr);
            const chunk =
              parsed?.candidates?.[0]?.content?.parts?.[0]?.text || "";
            if (chunk) {
              fullText += chunk;
              onChunk?.(chunk);
            }
          } catch {
            // Skip malformed JSON
          }
        }
      }
    }

    return fullText || "I didn't get a response. Please try again.";
  } catch (error) {
    console.error("Gemini error:", error);
    return `❌ Connection error: ${error instanceof Error ? error.message : "Unknown error"}`;
  }
}

/**
 * Extract tool calls from AI response
 */
export function extractToolCall(
  text: string
): { tool: string; params: Record<string, unknown> } | null {
  const match = text.match(/<tool_call>\s*([\s\S]*?)\s*<\/tool_call>/);
  if (!match) return null;
  try {
    return JSON.parse(match[1]);
  } catch {
    return null;
  }
}

/**
 * Remove tool_call tags from visible text
 */
export function stripToolCall(text: string): string {
  return text.replace(/<tool_call>[\s\S]*?<\/tool_call>/g, "").trim();
}
