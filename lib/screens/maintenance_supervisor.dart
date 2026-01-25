import 'package:flutter/material.dart';

class MaintenanceSupervisor extends StatefulWidget {
  const MaintenanceSupervisor({super.key});

  @override
  State<MaintenanceSupervisor> createState() => _MaintenanceSupervisorState();
}

class _MaintenanceSupervisorState extends State<MaintenanceSupervisor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Supervisor'),
      ),
      body: const Center(
        child: Text('Welcome, Maintenance Supervisor!'),
      ),
    );
  }
}