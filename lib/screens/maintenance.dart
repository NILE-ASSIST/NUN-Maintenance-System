import 'package:flutter/material.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Dashboard'),
      ),
      body: const Center(
        child: Text('Welcome to the Maintenance Dashboard!'),
      ),
    );
  }
}