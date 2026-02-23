import 'dart:io'; //for Platform check
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaintDetail.dart';

//handles messages when the app is completely killed
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // calls this immediately after Login to force-save the token
  Future<void> uploadUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ Cannot save token: No user logged in.");
      return;
    }

    try {
      String? token;
      
      //Get the token (Platform safe)
      if (Platform.isIOS) {
         String? apns = await _firebaseMessaging.getAPNSToken();
         if (apns != null) {
           token = await _firebaseMessaging.getToken();
         }
      } else {
         token = await _firebaseMessaging.getToken();
      }

      //Save it if found
      if (token != null) {
        print("🔄 Force-updating FCM Token for ${user.email}...");
        await _saveTokenToDatabase(token);
        print("✅ Token updated successfully!");
      } else {
        print("⚠️ Could not fetch a valid token to save.");
      }
    } catch (e) {
      print("❌ Error uploading token: $e");
    }
  }

  // Setup local notifications for Foreground display
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    //Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Get Token (SAFE VERSION FOR IOS SIMULATOR)
      try {
        String? token;

        // Check if we are on iOS using the safe 'dart:io' method
        if (Platform.isIOS) {
          // On iOS, wait for APNS token first
          String? apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            token = await _firebaseMessaging.getToken();
          } else {
            // If APNS is null, app runs on a Simulator.
            // Skip getting the FCM token so the app doesn't crash.
            print(
              "⚠️ Skipping FCM token: APNS token not available (Simulator detected)",
            );
          }
        } else {
          // On android, get the token directly
          token = await _firebaseMessaging.getToken();
        }

        // got a token (Real Device / Android), save it.
        if (token != null) {
          print("✅ FCM Token: $token");
          await _saveTokenToDatabase(token);
          _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
        }
      } catch (e) {
        print("Error getting token: $e");
      }

      // Handle Foreground Messages (App is Open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      });

      // Handle Notification Taps
      _setupInteractedMessage();
    }
  }

  // handle what happens when user taps the notification
  Future<void> _setupInteractedMessage() async {
    // App was Terminated (Killed) = User Tapped Notification = App Opens
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // App was in Background = User Tapped Notification = App Resumed
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final String? ticketId = message.data['ticketId'];

    if (ticketId != null && ticketId.isNotEmpty) {
      print("User tapped notification for ticket: $ticketId");

      try {
        //get the ticket data from Firestore using the ID
        final docSnapshot = await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;

          //uses the global navigatorKey to push the screen directly
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(
                ticketId: ticketId,
                data: data,
              ),
            ),
          );
        } else {
          print("Ticket $ticketId no longer exists in the database.");
        }
      } catch (e) {
        print("Error fetching ticket for deep link: $e");
      }
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collections = [
      'students',
      'lecturers',
      'facility_managers',
      'maintenance_supervisors',
      'maintenance',
    ];

    for (var collection in collections) {
      final docRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        break;
      }
    }
  }

//deletes tokekn from database and on logout
  Future<void> deleteToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // List of all user collections
    final collections = [
      'students', 
      'lecturers', 
      'facility_managers', 
      'maintenance_supervisors', 
      'maintenance'
    ];

    // Try to remove token from Firestore profile
    for (var collection in collections) {
      final docRef = FirebaseFirestore.instance.collection(collection).doc(user.uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        // Remove the fcmToken field from the document
        await docRef.update({
          'fcmToken': FieldValue.delete(),
        });
        print("🗑️ Token removed from $collection collection.");
        break; 
      }
    }

    // Delete locally so the app generates a new one next time
    await _firebaseMessaging.deleteToken();
  }
}
