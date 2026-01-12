import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/screens/maintenance.dart'; // Import your dashboard

class UploadProfileScreen extends StatefulWidget {
  final String userId;
  const UploadProfileScreen({super.key, required this.userId});

  @override
  State<UploadProfileScreen> createState() => _UploadProfileScreenState();
}

class _UploadProfileScreenState extends State<UploadProfileScreen> {
  static const Color nileBlue = Color(0xFF1E3DD3);
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera); // Force Camera?
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadAndContinue() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${widget.userId}.jpg');

      await ref.putFile(_imageFile!);
      String downloadUrl = await ref.getDownloadURL();

      // 2. Update Firestore Document
      await FirebaseFirestore.instance
          .collection('maintenance') // Assuming maintenance collection
          .doc(widget.userId)
          .update({'profilePicture': downloadUrl});

      if (!mounted) return;

      // 3. Navigate to Dashboard
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MaintenanceDashboard())
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
      appBar: AppBar(title: const Text("Verification Required", style: TextStyle(color: Colors.white),), backgroundColor: nileBlue, centerTitle: true,),
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
              "As a maintenance staff, you must upload a clear photo of yourself before accessing the dashboard.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // Image Preview Area
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

            // Submit Button
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