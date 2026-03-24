import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';

class AdminAnnouncescreen extends StatefulWidget {
  const AdminAnnouncescreen({super.key});

  @override
  State<AdminAnnouncescreen> createState() => _AdminAnnouncescreenState();
}

class _AdminAnnouncescreenState extends State<AdminAnnouncescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Announcements', style: TextStyle(color: Colors.white),),
        leading: null,
        backgroundColor: MyApp.nileBlue,
        centerTitle: true
      ),
      body: const Center(
        child: Text('Admin Announcement Screen'),
      ),
    );
  }
}