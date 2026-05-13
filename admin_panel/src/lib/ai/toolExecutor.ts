// Tool executor — maps AI tool calls to real Firestore/API operations
// This is what makes the AI actually DO things in your database

import {
  collection,
  query,
  where,
  getDocs,
  orderBy,
  limit,
  Timestamp,
  getCountFromServer,
} from "firebase/firestore";
import { db } from "../firebase";
import { updateUserStatus } from "../api/users";
import { fetchJobs, updateJobStatus } from "../api/jobs";
import { sendBulkNotifications } from "../api/notifications";

export interface ToolResult {
  success: boolean;
  data?: unknown;
  summary: string; // Human-readable summary for AI context
  action?: {
    type: "ban_user" | "unban_user" | "approve_job" | "send_notification";
    payload: Record<string, unknown>;
    label: string;
  };
}

// ─── Analytics Tools ───────────────────────────────────────────────────────

export async function tool_get_analytics(): Promise<ToolResult> {
  try {
    const usersSnap = await getCountFromServer(collection(db, "users"));
    const workersSnap = await getCountFromServer(
      query(collection(db, "users"), where("role", "==", "worker"))
    );
    const employersSnap = await getCountFromServer(
      query(collection(db, "users"), where("role", "==", "employer"))
    );
    const jobsSnap = await getCountFromServer(
      query(collection(db, "posts"), where("isJobPost", "==", true))
    );
    const subsSnap = await getCountFromServer(collection(db, "subscriptions"));

    const data = {
      totalUsers: usersSnap.data().count,
      totalWorkers: workersSnap.data().count,
      totalEmployers: employersSnap.data().count,
      totalJobs: jobsSnap.data().count,
      totalSubscriptions: subsSnap.data().count,
    };

    return {
      success: true,
      data,
      summary: `Platform stats: ${data.totalUsers} total users (${data.totalWorkers} workers, ${data.totalEmployers} employers), ${data.totalJobs} job posts, ${data.totalSubscriptions} subscriptions.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed to fetch analytics: ${e}` };
  }
}

export async function tool_get_new_users_today(): Promise<ToolResult> {
  try {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const snap = await getCountFromServer(
      query(
        collection(db, "users"),
        where("createdAt", ">=", Timestamp.fromDate(startOfDay))
      )
    );
    const count = snap.data().count;
    return {
      success: true,
      data: { count },
      summary: `${count} new user${count !== 1 ? "s" : ""} joined today.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

export async function tool_get_jobs_this_week(): Promise<ToolResult> {
  try {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const snap = await getCountFromServer(
      query(
        collection(db, "posts"),
        where("isJobPost", "==", true),
        where("createdAt", ">=", Timestamp.fromDate(weekAgo))
      )
    );
    const count = snap.data().count;
    return {
      success: true,
      data: { count },
      summary: `${count} job post${count !== 1 ? "s" : ""} created in the last 7 days.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

export async function tool_get_top_job_categories(): Promise<ToolResult> {
  try {
    const snap = await getDocs(
      query(
        collection(db, "posts"),
        where("isJobPost", "==", true),
        orderBy("createdAt", "desc"),
        limit(100)
      )
    );
    const counts: Record<string, number> = {};
    snap.forEach((d) => {
      const cat = d.data().category || d.data().jobCategory || "Uncategorized";
      counts[cat] = (counts[cat] || 0) + 1;
    });
    const sorted = Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5);
    return {
      success: true,
      data: sorted,
      summary: `Top job categories: ${sorted.map(([k, v]) => `${k} (${v})`).join(", ")}.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

// ─── User Management Tools ─────────────────────────────────────────────────

export async function tool_list_flagged_users(): Promise<ToolResult> {
  try {
    const snap = await getDocs(
      query(
        collection(db, "users"),
        where("isBlocked", "==", true),
        limit(20)
      )
    );
    const users = snap.docs.map((d) => ({
      id: d.id,
      name: d.data().name || d.data().fullName || "Unknown",
      email: d.data().email || "No email",
      role: d.data().role || "user",
    }));
    return {
      success: true,
      data: users,
      summary:
        users.length > 0
          ? `Found ${users.length} blocked user(s): ${users.map((u) => u.name).join(", ")}.`
          : "No blocked/flagged users found.",
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

export async function tool_list_inactive_users(params: {
  days: number;
}): Promise<ToolResult> {
  try {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - (params.days || 30));
    // Users with no recent activity (joined before cutoff, basic heuristic)
    const snap = await getDocs(
      query(
        collection(db, "users"),
        where("createdAt", "<=", Timestamp.fromDate(cutoff)),
        orderBy("createdAt", "desc"),
        limit(20)
      )
    );
    const users = snap.docs
      .map((d) => ({
        id: d.id,
        name: d.data().name || d.data().fullName || "Unknown",
        email: d.data().email || "No email",
        joinedAt:
          d.data().createdAt?.toDate?.()?.toLocaleDateString?.() || "N/A",
      }))
      .slice(0, 10);
    return {
      success: true,
      data: users,
      summary: `Found ${users.length} users who joined more than ${params.days || 30} days ago (potential inactives): ${users.map((u) => u.name).join(", ")}.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

export async function tool_find_user_by_email(params: {
  email: string;
}): Promise<ToolResult> {
  try {
    const snap = await getDocs(
      query(
        collection(db, "users"),
        where("email", "==", params.email),
        limit(1)
      )
    );
    if (snap.empty) {
      return {
        success: false,
        summary: `No user found with email: ${params.email}`,
      };
    }
    const d = snap.docs[0];
    const user = {
      id: d.id,
      name: d.data().name || d.data().fullName || "Unknown",
      email: d.data().email,
      role: d.data().role || "user",
      isBlocked: d.data().isBlocked || false,
      isVerified: d.data().isVerified || false,
      credits: d.data().credits || 0,
    };
    return {
      success: true,
      data: user,
      summary: `Found user: ${user.name} (${user.email}), role: ${user.role}, blocked: ${user.isBlocked}, verified: ${user.isVerified}, credits: ${user.credits}.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

export async function tool_ban_user(params: {
  userId: string;
  userName: string;
}): Promise<ToolResult> {
  // Returns an action — actual execution happens after admin confirms
  return {
    success: true,
    summary: `Ready to ban user: ${params.userName} (ID: ${params.userId}). Awaiting admin confirmation.`,
    action: {
      type: "ban_user",
      payload: { userId: params.userId, userName: params.userName },
      label: `🚫 Ban ${params.userName}`,
    },
  };
}

export async function tool_unban_user(params: {
  userId: string;
  userName: string;
}): Promise<ToolResult> {
  return {
    success: true,
    summary: `Ready to unban user: ${params.userName}. Awaiting admin confirmation.`,
    action: {
      type: "unban_user",
      payload: { userId: params.userId, userName: params.userName },
      label: `✅ Unban ${params.userName}`,
    },
  };
}

// ─── Job Moderation Tools ──────────────────────────────────────────────────

export async function tool_list_unapproved_jobs(): Promise<ToolResult> {
  try {
    const result = await fetchJobs(null, "open");
    const pending = result.jobs.filter(
      (j) => !j.isFeatured && j.status === "open"
    );
    return {
      success: true,
      data: pending,
      summary:
        pending.length > 0
          ? `Found ${pending.length} open job post(s): ${pending
              .slice(0, 5)
              .map((j) => `"${j.title}" by ${j.employerName}`)
              .join(", ")}${pending.length > 5 ? ` and ${pending.length - 5} more` : ""}.`
          : "No unapproved jobs found. All jobs are either approved or there are none.",
    };
  } catch (e) {
    return { success: false, summary: `Failed: ${e}` };
  }
}

export async function tool_approve_job(params: {
  jobId: string;
  jobTitle: string;
}): Promise<ToolResult> {
  return {
    success: true,
    summary: `Ready to approve job: "${params.jobTitle}". Awaiting confirmation.`,
    action: {
      type: "approve_job",
      payload: { jobId: params.jobId, jobTitle: params.jobTitle },
      label: `✅ Approve "${params.jobTitle}"`,
    },
  };
}

// ─── Notification Tools ────────────────────────────────────────────────────

export async function tool_send_notification_all(params: {
  title: string;
  body: string;
}): Promise<ToolResult> {
  return {
    success: true,
    summary: `Ready to send notification to ALL users: "${params.title}". Awaiting confirmation.`,
    action: {
      type: "send_notification",
      payload: { ...params, role: "all" },
      label: `📢 Send to All Users`,
    },
  };
}

export async function tool_send_notification_role(params: {
  role: "worker" | "employer";
  title: string;
  body: string;
}): Promise<ToolResult> {
  return {
    success: true,
    summary: `Ready to send notification to all ${params.role}s: "${params.title}". Awaiting confirmation.`,
    action: {
      type: "send_notification",
      payload: params,
      label: `📢 Send to ${params.role === "worker" ? "Workers" : "Employers"}`,
    },
  };
}

// ─── Report Tool ───────────────────────────────────────────────────────────

export async function tool_generate_weekly_report(): Promise<ToolResult> {
  try {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const weekStart = Timestamp.fromDate(weekAgo);

    const [newUsersSnap, newJobsSnap, totalUsersSnap, totalJobsSnap] =
      await Promise.all([
        getCountFromServer(
          query(collection(db, "users"), where("createdAt", ">=", weekStart))
        ),
        getCountFromServer(
          query(
            collection(db, "posts"),
            where("isJobPost", "==", true),
            where("createdAt", ">=", weekStart)
          )
        ),
        getCountFromServer(collection(db, "users")),
        getCountFromServer(
          query(collection(db, "posts"), where("isJobPost", "==", true))
        ),
      ]);

    const data = {
      period: `${weekAgo.toLocaleDateString()} – ${new Date().toLocaleDateString()}`,
      newUsers: newUsersSnap.data().count,
      newJobs: newJobsSnap.data().count,
      totalUsers: totalUsersSnap.data().count,
      totalJobs: totalJobsSnap.data().count,
    };

    return {
      success: true,
      data,
      summary: `Weekly report data: Period ${data.period}. New users: ${data.newUsers}. New job posts: ${data.newJobs}. Platform totals: ${data.totalUsers} users, ${data.totalJobs} jobs.`,
    };
  } catch (e) {
    return { success: false, summary: `Failed to generate report: ${e}` };
  }
}

// ─── Action Executor (after admin confirmation) ────────────────────────────

export async function executeConfirmedAction(
  actionType: string,
  payload: Record<string, unknown>
): Promise<{ success: boolean; message: string }> {
  try {
    switch (actionType) {
      case "ban_user":
        await updateUserStatus(payload.userId as string, { isBlocked: true });
        return {
          success: true,
          message: `✅ User "${payload.userName}" has been banned successfully.`,
        };

      case "unban_user":
        await updateUserStatus(payload.userId as string, { isBlocked: false });
        return {
          success: true,
          message: `✅ User "${payload.userName}" has been unbanned.`,
        };

      case "approve_job":
        await updateJobStatus(payload.jobId as string, {
          isFeatured: true,
          status: "open",
        });
        return {
          success: true,
          message: `✅ Job "${payload.jobTitle}" has been approved.`,
        };

      case "send_notification": {
        const { role, title, body } = payload as {
          role: string;
          title: string;
          body: string;
        };
        const usersSnap = await getDocs(
          role === "all"
            ? collection(db, "users")
            : query(collection(db, "users"), where("role", "==", role))
        );
        const userIds = usersSnap.docs.map((d) => d.id);
        await sendBulkNotifications(
          userIds,
          title,
          body,
          "general"
        );
        return {
          success: true,
          message: `✅ Notification sent to ${userIds.length} ${role === "all" ? "user" : role}${userIds.length !== 1 ? "s" : ""}.`,
        };
      }

      default:
        return { success: false, message: `Unknown action type: ${actionType}` };
    }
  } catch (e) {
    return { success: false, message: `❌ Action failed: ${e}` };
  }
}

// ─── Tool Dispatcher ───────────────────────────────────────────────────────

export async function dispatchTool(
  tool: string,
  params: Record<string, unknown>
): Promise<ToolResult> {
  switch (tool) {
    case "get_analytics":
      return tool_get_analytics();
    case "get_new_users_today":
      return tool_get_new_users_today();
    case "get_jobs_this_week":
      return tool_get_jobs_this_week();
    case "get_top_job_categories":
      return tool_get_top_job_categories();
    case "list_flagged_users":
      return tool_list_flagged_users();
    case "list_inactive_users":
      return tool_list_inactive_users(params as { days: number });
    case "find_user_by_email":
      return tool_find_user_by_email(params as { email: string });
    case "ban_user":
      return tool_ban_user(
        params as { userId: string; userName: string }
      );
    case "unban_user":
      return tool_unban_user(
        params as { userId: string; userName: string }
      );
    case "list_unapproved_jobs":
      return tool_list_unapproved_jobs();
    case "approve_job":
      return tool_approve_job(
        params as { jobId: string; jobTitle: string }
      );
    case "send_notification_all":
      return tool_send_notification_all(
        params as { title: string; body: string }
      );
    case "send_notification_role":
      return tool_send_notification_role(
        params as {
          role: "worker" | "employer";
          title: string;
          body: string;
        }
      );
    case "generate_weekly_report":
      return tool_generate_weekly_report();
    default:
      return {
        success: false,
        summary: `Unknown tool: ${tool}`,
      };
  }
}
