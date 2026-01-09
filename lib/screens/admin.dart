import 'package:flutter/material.dart';
import 'package:nileassist/models/admin.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminController _controller = AdminController();

  // Colors
  final Color nileBlue = const Color(0xFF1E3DD3);
  final Color secondaryGrey = Colors.grey[350]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildHeader(),

              const SizedBox(height: 25),

              DashboardInfoCard(
                title: 'Active Users',
                icon: Icons.check_circle_outline,
                backgroundColor: nileBlue,
                futureData: _controller.countTotalUsers(),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: secondaryGrey.withOpacity(0.3), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Complaint Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MiniStatBox(
                          label: 'Total', 
                          staticValue: null,
                          futureValue: _controller.countTotalComplaints(),
                          color: nileBlue
                        ),
                        MiniStatBox(
                          label: 'Pending', 
                          staticValue: '0',
                          futureValue: _controller.countPendingComplaints(),
                          color: Colors.orange
                        ),
                        MiniStatBox(
                          label: 'Resolved', 
                          staticValue: '0',
                          futureValue: _controller.countResolvedComplaints(),
                          color: Colors.green
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/images/logo-removebg-preview.png', width: 130),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_outlined, color: nileBlue, size: 28),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ],
        )
      ],
    );
  }
}