import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/Admin_AnnounceScreen.dart';
import 'package:nileassist/screens/Admin_CodeScreen.dart';
import 'package:nileassist/screens/Newfacility.dart';
import 'package:nileassist/screens/admin.dart';
import 'package:nileassist/screens/chat.dart';
import 'package:nileassist/screens/complaint_screen.dart';
import 'package:nileassist/screens/maintenance_supervisor.dart';
import 'package:nileassist/screens/profile_screen.dart';
import 'package:nileassist/screens/staffdashboard.dart';
// import 'package:nileassist/screens/facilitymanager.dart';
import 'package:nileassist/screens/maintenance.dart';

class MainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainLayout({super.key, required this.userData});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController _pageController; // Controller for the swipeable area
  
  final Color nileBlue = const Color(0xFF1E3DD3);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  Widget _getHomeForRole() {
    String role = widget.userData['role'];

    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'lecturer':
      case 'hostel_supervisor':
        return DashboardScreen(
          userData: widget.userData,
          onNavigateToComplaints: () {
            _onBottomNavTapped(1); // navigate to the complaints tab
          },
        );
      case 'facility_manager':
        return const NewFMDashboard();
      case 'maintenance':
      case 'maintenance_staff':
        return MaintenanceDashboard(userData: widget.userData, onNavigateToComplaints: () {
            _onBottomNavTapped(1); // navigate to the complaints tab
          },);
      case 'maintenance_supervisor':
        return const MaintenanceSupervisor();
      default:
        return const Center(child: Text("Unknown Role"));
    }
  }

  // Update the bottom nav when the user swipes
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

Widget _buildChatIcon() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Icon(Icons.chat_outlined);

  final ticketsRef = FirebaseFirestore.instance.collection('tickets');

  return StreamBuilder<QuerySnapshot>(
    stream: ticketsRef.snapshots(),
    builder: (context, snapshot) {
      bool hasUnread = false;

      if (snapshot.hasData) {
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['unreadBy'] == user.uid ||
              data['unreadBy_internal'] == user.uid) {
            hasUnread = true;
            break;
          }
        }
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_outlined),
          if (hasUnread)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MyApp.nileGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 0.5),
                ),
              ),
            ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    bool isFacilityManager = widget.userData['role'] == 'facility_manager';
    bool isAdmin = widget.userData['role'] == 'admin';

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _getHomeForRole(),
          if (!isAdmin) ComplaintScreen(userData: widget.userData),
          // ComplaintScreen(userData: widget.userData),
          if (!isFacilityManager && !isAdmin) ChatScreen(userData: widget.userData),
          if (isAdmin) AdminCodescreen(),
          if (isAdmin) AdminAnnouncescreen(),
          ProfileScreen(userData: widget.userData),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: nileBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTapped, 
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          if (!isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              label: "Complaints",
            ),
          // const BottomNavigationBarItem(
          //   icon: Icon(Icons.confirmation_number_outlined),
          //   label: "Complaints",
          // ),
          if (!isFacilityManager && !isAdmin)
            BottomNavigationBarItem(
              icon: _buildChatIcon(),
              label: "Chats",
            ),
          if (isAdmin)
            BottomNavigationBarItem(
             icon: Icon(Icons.lock),
            label: "Code",
            ),
          if (isAdmin)
            BottomNavigationBarItem(
             icon: Icon(Icons.campaign_rounded),
            label: "Notices",
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}