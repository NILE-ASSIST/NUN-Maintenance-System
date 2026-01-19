import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Complaint',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ), 
                  const Text(
                    'Track all your submitted complaints',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ), 
                    SizedBox(
                      width: 340,
                      child: SearchBar(
                        hintText: 'Search by id, title, or category',
                        backgroundColor: WidgetStateProperty.all(Colors.grey[200]),
                        elevation: WidgetStateProperty.all(0),
                        leading: const Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('No complaints to show'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
