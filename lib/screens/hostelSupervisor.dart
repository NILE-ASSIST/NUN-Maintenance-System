import 'package:flutter/material.dart';

class HSDashboard extends StatefulWidget {
  const HSDashboard({super.key});

  @override
  State<HSDashboard> createState() => _HSDashboardState();
}

class _HSDashboardState extends State<HSDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Supervisor Dashboard'),
      ),
      body: const Center(
        child: Text('Welcome to the Hostel Supervisor Dashboard!'),
      ),
    );
  }
}