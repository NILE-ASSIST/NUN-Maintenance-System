import 'package:flutter/material.dart';

class FMDashboard extends StatefulWidget {
  const FMDashboard({super.key});

  @override
  State<FMDashboard> createState() => _FMDashboardState();
}

class _FMDashboardState extends State<FMDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Manager Dashboard'),
      ),
      body: const Center(
        child: Text('Welcome to the Facility Manager Dashboard!'),
      ),
    );
  }
}