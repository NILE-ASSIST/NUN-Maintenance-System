import 'package:flutter/material.dart';
import 'package:nileassist/screens/admin.dart';
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
  
  final Color nileBlue = const Color(0xFF1E3DD3);

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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _getHomeForRole(),           
      const Center(child: Text("Complaints Screen")),
      const Center(child: Text("Profile Screen")),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: nileBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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