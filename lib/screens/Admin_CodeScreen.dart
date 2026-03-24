import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';

class AdminCodescreen extends StatefulWidget {
  const AdminCodescreen({super.key});

  @override
  State<AdminCodescreen> createState() => _AdminCodescreenState();
}

class _AdminCodescreenState extends State<AdminCodescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Codes', style: TextStyle(color: Colors.white),),
        leading: null,
        backgroundColor: MyApp.nileBlue,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Admin Code Screen'),
      ),
    );
  }
}