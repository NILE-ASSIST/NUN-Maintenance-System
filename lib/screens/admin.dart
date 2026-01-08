import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  final  Color primaryBlue = Color(0xFF1E3DD3);
  final Color greenButton = Color(0xFF8BC34A);

Future<int> _countTotalUsers() async {
  int totalUsers = 0;
    final firestore = FirebaseFirestore.instance;

    // List of user group collection names
    final userGroups= [
      'lecturers', 
      'facility_managers', 
      'hostel_supervisors', 
      'maintenance',
      'admins'
    ];

    for (String collectionName in userGroups) {
      // count() checks firestore for the number of documents in a collection
      AggregateQuerySnapshot snapshot = await firestore.collection(collectionName).count().get();
      
      totalUsers += snapshot.count ?? 0;
    }
    
    return totalUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 24, vertical: 16),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/logo-removebg-preview.png', width: 150, height: 60,),
                    Container(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications_none_outlined, color: primaryBlue,),
                            onPressed: () {},
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[500],
                            child: IconButton(
                            icon: Icon(Icons.person_outline_rounded, color: Colors.white,),
                            onPressed: () {},
                          ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 25,),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  alignment: Alignment.topCenter,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Users', style: TextStyle(color: Colors.white, fontSize: 18),),
                          Icon(Icons.check_circle_outline_outlined, color: Colors.white,),
                        ],
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: FutureBuilder<int>(
                            future: _countTotalUsers(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 30, 
                                  width: 30, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text('---', style: TextStyle(color: Colors.white, fontSize: 32));
                              }
                              
                              // The actual count
                              return Text(
                                '${snapshot.data}', 
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                      ),                    ],
                  ),
                ),
                SizedBox(height: 20,),
                Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text('Complaints Overview', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),)),
                              SizedBox(height: 10,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Complaints', style: TextStyle(color: Colors.black, fontSize: 16),),
                                Text('0', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
                                    ],
                                  ),
                                )
                              ],
                            ),

                          ],
                        ),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}