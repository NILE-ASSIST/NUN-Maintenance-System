import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminController {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> countTotalUsers() async {
    int totalUsers = 0;
    final firestore = FirebaseFirestore.instance;

    // list of user group collection names in firestore
    final userGroups = [
      'lecturers',
      'facility_managers',
      'hostel_supervisors',
      'maintenance',
      'admins',
    ];

    for (String collectionName in userGroups) {
      // count() checks firestore for the number of documents in a collection
      AggregateQuerySnapshot snapshot = await firestore
          .collection(collectionName)
          .count()
          .get();

      totalUsers += snapshot.count ?? 0;
    }

    return totalUsers;
  }

  Future<int> countTotalComplaints() async {
    int totalComplaints = 0;
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('complaints').count().get();
    totalComplaints = snapshot.count ?? 0;
    return totalComplaints;
  }

  Future<int> countPendingComplaints() async {
    // int totalComplaints = 0;
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('complaints')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
    // return totalComplaints;
  }

  Future<int> countResolvedComplaints() async {
    // int totalComplaints = 0;
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('complaints')
        .where('status', isEqualTo: 'resolved')
        .count()
        .get();
    return snapshot.count ?? 0;
    // return totalComplaints;
  }
}

class DashboardInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Future<int> futureData;

  const DashboardInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.futureData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Icon(icon, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<int>(
            future: futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Text(
                  '---',
                  style: TextStyle(color: Colors.white, fontSize: 32),
                );
              }

              return Text(
                '${snapshot.data}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MiniStatBox extends StatelessWidget {
  final String label;
  final String? staticValue;
  final Color color;
  final Color textColor;
  final Future<int> futureValue;

  const MiniStatBox({
    super.key,
    required this.label,
    required this.staticValue,
    required this.color,
    this.textColor = Colors.white,
    required this.futureValue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),

            FutureBuilder<int>(
              future: futureValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (snapshot.hasError)
                  return Text(
                    '-',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );

                return Text(
                  '${snapshot.data ?? 0}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            // else
            //   Text(staticValue ?? '0', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
