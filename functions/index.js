/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotification = onDocumentCreated("notifications/{docId}", async (event) => {
    // In Gen 2, 'event.data' is the document snapshot
    const snapshot = event.data;
    
    // Check if the document actually exists (it should, since this is onCreate)
    if (!snapshot) {
        console.log("No data associated with the event");
        return;
    }

    const newData = snapshot.data();
    const userId = newData.userId;
    const targetRole = newData.targetRole;

    // Prepare the payload
    const payload = {
        notification: {
            title: newData.title,
            body: newData.body,
        },
        data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            ticketId: newData.ticketId || "",
        },
    };

    const tokens = [];

    //Find the tokens
    if (userId) {
        const collections = ["students", "lecturers", "facility_managers", "maintenance_supervisors", "maintenance"];
        
        for (const col of collections) {
            const userDoc = await admin.firestore().collection(col).doc(userId).get();
            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
                console.log(`Found token for user in ${col}`);
                break; 
            }
        }
    } else {
        console.log("No specific userId provided, and group messaging is not enabled yet.");
    }

    if (tokens.length === 0) {
        console.log("No tokens found for user.");
        return null;
    }

    // Send the message (Using the new sendEach API)
    // We create a message object for each token found
    const messages = tokens.map(token => ({
        token: token,
        notification: payload.notification,
        data: payload.data
    }));

    try {
        const response = await admin.messaging().sendEach(messages);
        console.log("Successfully sent message:", response);
    } catch (error) {
        console.log("Error sending message:", error);
    }
    
    return null;
});