/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK (check to prevent double initialization)
if (!admin.apps.length) {
    admin.initializeApp();
}

exports.sendPushNotification = onDocumentCreated("notifications/{docId}", async (event) => {
    // In Gen 2, 'event.data' is the document snapshot
    const snapshot = event.data;
    
    // Check if the document actually exists
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }

    const newData = snapshot.data();
    const userId = newData.userId;
    const targetRole = newData.targetRole; 

    // Prepare the notification payload
    const payload = {
        notification: {
            title: newData.title || "New Notification",
            body: newData.body || "You have a new alert.",
        },
        android: {
            priority: "high", 
            notification: {
                sound: "default", 
            }
        },
        // NEW: Force iOS to play the default chime
        apns: {
            payload: {
                aps: {
                    sound: "default",
                }
            }
        },
        data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            ticketId: newData.ticketId || "",
            type: newData.type || "general_notification", 
        },
    };

    const tokens = [];

    // --- LOGIC BRANCH 1: Send to a specific User ---
    if (userId) {
        // Notice: 'students' has been removed from this list
        const collections = ["lecturers", "facility_managers", "maintenance_supervisors", "maintenance", "admins", "hostel_supervisors"];
        
        for (const col of collections) {
            const userDoc = await admin.firestore().collection(col).doc(userId).get();
            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
                console.log(`Found token for specific user in ${col}`);
                break; 
            }
        }
    } 
    // --- LOGIC BRANCH 2: Send to a Group (Role-Based) ---
    else if (targetRole) {
        console.log(`Processing Group Notification for Role: ${targetRole}`);
        let targetCollection = "";
        
        // Map the targetRole to your exact Firestore collection names
        if (targetRole === "facility_manager") targetCollection = "facility_managers";
        else if (targetRole === "admin") targetCollection = "admins";
        else if (targetRole === "maintenance_supervisor") targetCollection = "maintenance_supervisors";
        else if (targetRole === "maintenance_staff" || targetRole === "maintenance") targetCollection = "maintenance";
        else if (targetRole === "lecturer") targetCollection = "lecturers";
        else if (targetRole === "hostel_supervisor") targetCollection = "hostel_supervisors";

        if (targetCollection !== "") {
            try {
                // Fetch EVERY user in that collection
                const roleSnapshot = await admin.firestore().collection(targetCollection).get();
                
                if (!roleSnapshot.empty) {
                    roleSnapshot.forEach(doc => {
                        const data = doc.data();
                        // Grab the token from the exact field name in your database
                        if (data.fcmToken) {
                            tokens.push(data.fcmToken);
                        }
                    });
                    console.log(`Found ${tokens.length} tokens for role ${targetRole}`);
                } else {
                    console.log(`No users found in collection: ${targetCollection}`);
                }
            } catch (error) {
                console.error(`Error fetching tokens for role ${targetRole}:`, error);
            }
        } else {
            console.log(`Unknown targetRole provided: ${targetRole}`);
        }
    } else {
        console.log("No specific userId or targetRole provided. Cannot determine recipient.");
    }

    // Stop and exit if no tokens were found
    if (tokens.length === 0) {
        console.log("No valid tokens found. Notification will not be sent.");
        return null;
    }

    // Prepare the messages using the new sendEach API
    const messages = tokens.map(token => ({
        token: token,
        notification: payload.notification,
        data: payload.data,
        apns: payload.apns,       // pass iOS settings
        data: payload.data,
    }));

    // Send the messages
    try {
        const response = await admin.messaging().sendEach(messages);
        console.log(`Successfully sent ${response.successCount} messages.`);
        if (response.failureCount > 0) {
            console.log(`Failed to send ${response.failureCount} messages.`);
        }
    } catch (error) {
        console.log("Error sending multicast message:", error);
    }
    
    return null;
});

//Specific Reminder function for Supervisors
exports.remindSupervisorsUnassigned = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "Africa/Lagos",
  },
  async () => {
    
    const threeDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
    );

    
    const ticketsSnapshot = await admin.firestore()
      .collection("tickets")
      .where("dateCreated", "<=", threeDaysAgo) // 3 days old or older
      .get();

    if (ticketsSnapshot.empty) {
      console.log("No 3-day unassigned tickets found.");
      return null;
    }

  
    for (const doc of ticketsSnapshot.docs) {
      const data = doc.data();
      
      // If no supervisor has claimed or been given this ticket yet, skip it
      if (data.status === "Resolved" || data.status === "Completed") continue;

      if (!data.assignedTo) continue;

      if (data.assignedStaffid) continue;

     
      const supervisorDoc = await admin.firestore()
        .collection("maintenance_supervisors")
        .doc(data.assignedTo)
        .get();

      if (!supervisorDoc.exists) continue;

      const token = supervisorDoc.data().fcmToken;
      if (!token) continue;

      // sends the targeted notification to just that one supervisor
      await admin.messaging().send({
        token: token,
        notification: {
          title: "Unassigned Ticket Reminder",
          body: "A complaint you are managing has not been assigned to a maintenance staff for 3 days. Kindly assign the ticket",
        },
        android: {
          priority: "high",
          notification: { sound: "default" },
        },
        apns: {
          payload: {
            aps: { sound: "default" },
          },
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          ticketId: doc.id, // Allows them to tap and open the exact ticket
          type: "unassigned_reminder",
        }
      });
    }

    console.log("3-day specific supervisor reminder job completed.");
    return null;
  }
);
