import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';
import 'package:nileassist/screens/gstarted.dart';
import 'package:nileassist/screens/mainLayout.dart';
import 'package:nileassist/screens/verify_email_screen.dart';
import 'package:nileassist/screens/uploadProfilePicture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nileassist/screens/chat_detail.dart';

//navigation key for notifications to navigate to specific screens
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// Add this global key so we can navigate from background notifications
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color nileBlue = Color.fromARGB(255, 2, 64, 177);
  static const Color nileGreen = Color(0xFF84C26A);
  // static const Color nileBlue = Color(0xFF1E3DD3);
  // static const Color nileGreen = Color(0xFF8BC34A);

  Future<void> setupNotificationRouting() async {
    //Handle the app being opened from a completely closed (terminated) state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    //Handle the app being opened from the background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Check if this notification is specifically a chat message
    if (message.data['type'] == 'chat_message') {
      final ticketId = message.data['ticketId'];
      final targetId = message.data['targetId'];
      final targetName = message.data['targetName'];

      //Grab the specific chat folder from the notification payload
      final chatCollection = message.data['chatCollection'] ?? 'messages';

      //Use Global Key to push to the chatDetail screen
      globalNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatDetail(
            ticketId: ticketId ?? '',
            targetName: targetName ?? 'Chat',
            targetId: targetId ?? '',
            currentUserData:
                const {}, // We can pass empty here since ChatDetail uses _auth.currentUser
            chatCollection:
                chatCollection, //passes the folder name so it opens the right chat
          ),
        ),
      );
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NileAssist',
      // navigatorKey: navigatorKey,
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          strokeWidth: 2.0,
          color: nileBlue,
        ),
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: nileBlue),
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData) {
            return const WelcomeScreen();
          }

          final user = snapshot.data!;

          if (!user.emailVerified) {
            return const VerifyEmailScreen();
          }

          // check profile picture for maintenance staff and supervisors at the same time
          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance
                  .collection('maintenance')
                  .doc(user.uid)
                  .get(),
              FirebaseFirestore.instance
                  .collection('maintenance_supervisors')
                  .doc(user.uid)
                  .get(),
            ]),
            builder: (context, maintenanceSnapshot) {
              if (maintenanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // determine if they need to upload a photo
              if (maintenanceSnapshot.hasData) {
                final results = maintenanceSnapshot.data!;
                final staffDoc = results[0];
                final supervisorDoc = results[1];

                DocumentSnapshot? targetDoc;

                // find out which collection the user is in
                if (staffDoc.exists) {
                  targetDoc = staffDoc;
                } else if (supervisorDoc.exists) {
                  targetDoc = supervisorDoc;
                }

                //if found in either maintenance collection, check for the picture
                if (targetDoc != null) {
                  final data = targetDoc.data() as Map<String, dynamic>?;

                  // If 'profilePicture' is missing or empty, block access
                  if (data != null &&
                      (data['profilePicture'] == null ||
                          data['profilePicture'] == '')) {
                    return UploadProfileScreen(userId: user.uid);
                  }
                }
              }

              //if all validation is correct, load full user data and show dashboard
              return FutureBuilder<Map<String, dynamic>?>(
                future: AuthService().getCurrentUserData(),
                builder: (context, dataSnapshot) {
                  if (dataSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // if fetching data failed (e.g. deleted user), go back to verification or login
                  if (!dataSnapshot.hasData || dataSnapshot.data == null) {
                    // Fallback, some issue occurred
                    return const VerifyEmailScreen();
                  }

                  return MainLayout(userData: dataSnapshot.data!);
                },
              );
            },
          );
        },
      ),
    );
  }
}
