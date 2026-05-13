import { collection, addDoc, query, where, getDocs, Timestamp, updateDoc, doc } from "firebase/firestore";
import { db, auth } from "../firebase";

export const sendMessageToUser = async (targetUid: string, targetName: string, targetPhoto: string, message: string) => {
  try {
    const adminUser = auth.currentUser;
    if (!adminUser) throw new Error("Admin not authenticated");

    // 1. Get or Create Chat Head
    let chatId = "";
    const chatsRef = collection(db, "chats");
    const q = query(chatsRef, where("members", "array-contains", adminUser.uid));
    const querySnapshot = await getDocs(q);
    
    for (const docSnap of querySnapshot.docs) {
      const members = docSnap.data().members;
      if (members.includes(targetUid)) {
        chatId = docSnap.id;
        break;
      }
    }

    if (!chatId) {
      // Create new chat head
      const newChatRef = await addDoc(chatsRef, {
        members: [adminUser.uid, targetUid],
        lastMessage: message,
        lastMessageTime: Timestamp.now(),
        isUnlocked: true, // Admin chats are always unlocked
        memberData: {
          [adminUser.uid]: {
            name: "KI GLOBAL ADMIN",
            photoUrl: ""
          },
          [targetUid]: {
            name: targetName,
            photoUrl: targetPhoto || ""
          }
        }
      });
      chatId = newChatRef.id;
    } else {
      // Update existing chat head
      await updateDoc(doc(db, "chats", chatId), {
        lastMessage: message,
        lastMessageTime: Timestamp.now()
      });
    }

    // 2. Add Message
    await addDoc(collection(db, "chats", chatId, "messages"), {
      senderId: adminUser.uid,
      text: message,
      timestamp: Timestamp.now(),
      type: "text"
    });

    // 3. Trigger a notification for the user
    await addDoc(collection(db, "users", targetUid, "notifications"), {
      title: "New Message from Admin",
      body: message.length > 50 ? message.substring(0, 50) + "..." : message,
      type: "chat",
      chatId: chatId,
      isRead: false,
      createdAt: Timestamp.now()
    });

    return true;
  } catch (error) {
    console.error("Error sending message to user:", error);
    throw error;
  }
};

export const fetchAllChats = async () => {
  try {
    const q = query(collection(db, "chats"), where("isUnlocked", "==", true));
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error("Error fetching all chats:", error);
    throw error;
  }
};

export const fetchMessages = async (chatId: string) => {
  try {
    const q = query(
      collection(db, "chats", chatId, "messages"),
      where("timestamp", "!=", null) // Avoid empty results if using order by on server timestamp
    );
    const querySnapshot = await getDocs(q);
    return (querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    })) as any[]).sort((a, b) => (a.timestamp?.seconds || 0) - (b.timestamp?.seconds || 0));
  } catch (error) {
    console.error("Error fetching messages:", error);
    throw error;
  }
};

export const replyToChat = async (chatId: string, message: string, targetUid: string) => {
  try {
    const adminUser = auth.currentUser;
    if (!adminUser) throw new Error("Admin not authenticated");

    // 1. Update Chat Head
    await updateDoc(doc(db, "chats", chatId), {
      lastMessage: message,
      lastMessageTime: Timestamp.now()
    });

    // 2. Add Message
    await addDoc(collection(db, "chats", chatId, "messages"), {
      senderId: adminUser.uid,
      text: message,
      timestamp: Timestamp.now(),
      type: "text"
    });

    // 3. Trigger a notification for the user
    await addDoc(collection(db, "users", targetUid, "notifications"), {
      title: "New Message from Admin",
      body: message.length > 50 ? message.substring(0, 50) + "..." : message,
      type: "chat",
      chatId: chatId,
      isRead: false,
      createdAt: Timestamp.now()
    });

    return true;
  } catch (error) {
    console.error("Error replying to chat:", error);
    throw error;
  }
};
