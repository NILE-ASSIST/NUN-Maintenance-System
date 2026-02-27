import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/mainLayout.dart';

class UploadProfileScreen extends StatefulWidget {
  final String userId;
  const UploadProfileScreen({super.key, required this.userId});

  @override
  State<UploadProfileScreen> createState() => _UploadProfileScreenState();
}

class _UploadProfileScreenState extends State<UploadProfileScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera); // force camera
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${widget.userId}.jpg');

      await ref.putFile(_imageFile!);
      String downloadUrl = await ref.getDownloadURL();

      // Try both collections (maintenance_staff and maintenance_supervisors)
      DocumentSnapshot? userDoc;
      String? collection;

      // Check maintenancefirst
      var staffDoc = await FirebaseFirestore.instance
          .collection('maintenance')
          .doc(widget.userId)
          .get();
      
      if (staffDoc.exists) {
        userDoc = staffDoc;
        collection = 'maintenance';
      } else {
        // Check maintenance_supervisors
        var supervisorDoc = await FirebaseFirestore.instance
            .collection('maintenance_supervisors')
            .doc(widget.userId)
            .get();
        
        if (supervisorDoc.exists) {
          userDoc = supervisorDoc;
          collection = 'maintenance_supervisors';
        }
      }

      if (userDoc == null || collection == null) {
        throw Exception('User not found in maintenance collections');
      }

      // Update Firestore Document
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.userId)
          .update({'profilePicture': downloadUrl});

      if (!mounted) return;

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => MainLayout(
            userData: {
              'uid': widget.userId,
              'email': userDoc!['email'],
              'role': userDoc['role'],
              'fullName': userDoc['fullName'],
              'profilePicture': downloadUrl,
            },
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification Required", style: TextStyle(color: Colors.white),), backgroundColor: MyApp.nileBlue, centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Identity Verification", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "As a maintenance staff or supervisor, you must upload a clear photo of yourself before accessing the dashboard.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // image preview
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null 
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _pickImage,
              child: const Text("Tap to take photo"),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_imageFile == null || _isUploading) ? null : _uploadAndContinue,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3)),
                child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Upload & Continue", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}