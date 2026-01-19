import 'package:flutter/material.dart';

class FacilityManagement extends StatefulWidget {
  const FacilityManagement({super.key});

  @override
  State<FacilityManagement> createState() => _FacilityManagementState();
}

class _FacilityManagementState extends State<FacilityManagement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Facility Dashboard"),),
    );
  }
}