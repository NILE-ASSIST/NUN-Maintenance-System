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

// Initialize only once
if (!admin.apps.length) {
  admin.initializeApp();
}

/* ===========================
   PUSH NOTIFICATION FUNCTION
=========================== */

exports.sendPushNotification = onDocumentCreated(
  "notifications/{docId}",
  async (event) => {

    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with event");
      return;
    }

    const newData = snapshot.data();
    const userId = newData.userId;
    const targetRole = newData.targetRole;

    const payload = {
      notification: {
        title: newData.title || "New Notification",
        body: newData.body || "You have a new alert.",
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
        ticketId: newData.ticketId || "",
        type: newData.type || "general_notification",
      },
    };

    const tokens = [];

    if (userId) {
      const collections = [
        "lecturers",
        "facility_managers",
        "maintenance_supervisors",
        "maintenance",
        "admins",
        "hostel_supervisors",
      ];

      for (const col of collections) {
        const userDoc = await admin.firestore().collection(col).doc(userId).get();
        if (userDoc.exists && userDoc.data().fcmToken) {
          tokens.push(userDoc.data().fcmToken);
          break;
        }
      }
    } else if (targetRole) {

      let targetCollection = "";

      if (targetRole === "facility_manager") targetCollection = "facility_managers";
      else if (targetRole === "admin") targetCollection = "admins";
      else if (targetRole === "maintenance_supervisor") targetCollection = "maintenance_supervisors";
      else if (targetRole === "maintenance_staff" || targetRole === "maintenance") targetCollection = "maintenance";
      else if (targetRole === "lecturer") targetCollection = "lecturers";
      else if (targetRole === "hostel_supervisor") targetCollection = "hostel_supervisors";

      if (targetCollection) {
        const roleSnapshot = await admin.firestore().collection(targetCollection).get();
        roleSnapshot.forEach(doc => {
          if (doc.data().fcmToken) {
            tokens.push(doc.data().fcmToken);
          }
        });
      }
    }

    if (tokens.length === 0) {
      console.log("No tokens found.");
      return null;
    }

    const messages = tokens.map(token => ({
      token,
      notification: payload.notification,
      data: payload.data,
      apns: payload.apns,
      android: payload.android,
    }));

    await admin.messaging().sendEach(messages);

    console.log("Push notification sent.");
    return null;
  }
);

/* 2-DAY REMINDER FUNCTION */

exports.remindSupervisorsUnassigned = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "Africa/Lagos",
  },
  async () => {

    const twoDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
    );

    const complaintsSnapshot = await admin.firestore()
      .collection("complaints")
      .where("status", "==", "pending")
      .where("assignedTo", "==", null)
      .where("createdAt", "<=", twoDaysAgo)
      .get();

    for (const doc of complaintsSnapshot.docs) {
      const data = doc.data();
      if (!data.supervisorId) continue;

      const supervisorDoc = await admin.firestore()
        .collection("users")
        .doc(data.supervisorId)
        .get();

      if (!supervisorDoc.exists) continue;

      const token = supervisorDoc.data().fcmToken;
      if (!token) continue;

      await admin.messaging().send({
        token,
        notification: {
          title: "Assignment Reminder",
          body: "A complaint has not been assigned for 2 days.",
        },
      });
    }

    console.log("Reminder job completed.");
    return null;
  }
);