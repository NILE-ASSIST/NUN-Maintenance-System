import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';
import 'package:nileassist/screens/admin.dart';
import 'package:nileassist/screens/profile_screen.dart';
import 'package:nileassist/screens/staffdashboard.dart';
import 'package:nileassist/screens/facilitymanager.dart';
import 'package:nileassist/screens/maintenance.dart';

class MainLayout extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainLayout({super.key, required this.userData});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController _pageController; //Controller for the swipeable area
  
  final Color nileBlue = const Color(0xFF1E3DD3);

  @override
  void initState() {
    super.initState();
    //Initialize the controller
    _pageController = PageController(initialPage: _currentIndex);
  }

  Widget _getHomeForRole() {
    String role = widget.userData['role'];
    String fullName = widget.userData['fullName'];

    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'lecturer':
      case 'hostel_supervisor':
        return DashboardScreen(fullName: fullName);
      case 'facility_manager':
        return const FMDashboard();
      case 'maintenance':
        return const MaintenanceDashboard();
      default:
        return const Center(child: Text("Unknown Role"));
    }
  }

  //Update the bottom nav when the user swipes
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _getHomeForRole(),           
          const Center(child: Text("Complaints Screen")),
          ProfileScreen(userData: widget.userData),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: nileBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTapped, //Update to use the animation method
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: "Complaints",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}