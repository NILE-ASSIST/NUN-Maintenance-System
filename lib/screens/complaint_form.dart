import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/widgets/custom_dropdown.dart';

class ComplaintFormPage extends StatefulWidget {
  final String? draftId;
  final Map<String, dynamic>? draftData;

  const ComplaintFormPage({
    super.key,
    this.draftId,
    this.draftData,
  });

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String _category = 'Select a category';
  String _priority = 'Medium'; 
  String? _attachmentName;
  String? _attachmentPath; 
  String? _attachmentUrl;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _buildingController.dispose();
    _roomController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // --- SUBMIT LOGIC ---
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_category == 'Select a category') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final locationString = '${_buildingController.text.trim()}, Room ${_roomController.text.trim()}';

      // Duplicate complaint logic
      final similarTicketsSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('category', isEqualTo: _category)
          .where('location', isEqualTo: locationString)
          .where('status', whereIn: ['Pending', 'In Progress', 'Being Validated', 'Needs Recheck']) 
          .get();

      final int similarCount = similarTicketsSnapshot.docs.length;

      if (similarCount == 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission prevented: This issue has already been reported 5 times.'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
        return; 
      }

      String? downloadUrl;

      // Upload Image
      if (_attachmentPath != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('tickets/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_attachmentName');

        final file = File(_attachmentPath!);
        await storageRef.putFile(file);
        downloadUrl = await storageRef.getDownloadURL();
      }

      String userName = 'Unknown User';
      String userRole = 'Unknown Role';
      
      // Fetch User Data
      final collections = ['lecturers', 'hostel_supervisors'];
      for (final col in collections) {
        final userDoc = await FirebaseFirestore.instance.collection(col).doc(user.uid).get();
        if (userDoc.exists) {
          final dbData = userDoc.data()!;
          userName = dbData['name'] ?? dbData['fullName'] ?? "${dbData['firstName'] ?? ''} ${dbData['lastName'] ?? ''}".trim();
          if (userName.isEmpty) userName = 'Unknown User';
          userRole = dbData['role'] ?? 'Unknown Role';
          break; 
        }
      }

      // Prepare Data
      final ticketData = {
        'description': _detailsController.text.trim(),
        'category': _category,
        'priority': _priority, 
        'location': locationString,
        'status': 'Pending',
        'dateCreated': FieldValue.serverTimestamp(),
        'issuerID': user.uid,
        'issuerEmail': user.email ?? 'Unknown User', 
        'issuerName': userName,
        'issuerRole': userRole,
        'attachmentName': _attachmentName,
        'imageUrl': downloadUrl, 
      };

      // Save to Firestore
      DocumentReference ticketRef = await FirebaseFirestore.instance.collection('tickets').add(ticketData);

      // Trigger Push Notification
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New $_priority Priority Request',
          'body': 'A new $_category issue has been reported at ${ticketData['location']}.',
          'userId': null, 
          'targetRole': 'facility_manager', 
          'ticketId': ticketRef.id,         
          'type': 'new_ticket',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      } catch (e) {
        print("Failed to trigger Facility Manager notification: $e");
      }

      if (!mounted) return;

      if (similarCount >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted successfully: a similar complaint has been submitted previously.'), backgroundColor: Colors.orange),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Complaint submitted successfully!'), backgroundColor: MyApp.nileGreen),
        );
      }
      
      // Auto-delete the draft if the ticket came from a saved draft
      if (widget.draftId != null) {
        try {
          await FirebaseFirestore.instance.collection('drafts').doc(widget.draftId).delete();
        } catch (e) {
          print("Failed to delete draft after submission: $e");
        }
      }
      
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- SAVE AS DRAFT LOGIC ---
  Future<void> _saveAsDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final locationString = '${_buildingController.text.trim()}, Room ${_roomController.text.trim()}';

      // We explicitly don't upload attachments immediately on "Save As Draft" to save quota, 
      // but we maintain their references if they exist.
      
      final draftData = {
        'description': _detailsController.text.trim(),
        'category': _category == 'Select a category' ? '' : _category,
        'priority': _priority,
        'location': locationString == ', Room ' ? '' : locationString,
        'issuerID': user.uid,
        'attachmentName': _attachmentName,
        'imageUrl': _attachmentUrl, 
        'lastEdited': FieldValue.serverTimestamp(),
      };

      if (widget.draftId != null) {
        // Update existing draft
        await FirebaseFirestore.instance.collection('drafts').doc(widget.draftId).update(draftData);
      } else {
        // Create new draft
        await FirebaseFirestore.instance.collection('drafts').add(draftData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully!'), backgroundColor: Colors.orange),
      );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving draft: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- ATTACHMENT LOGIC ---
  // enum _AttachmentAction { file, photo }

  Future<void> _pickAttachment() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.insert_drive_file_outlined), title: const Text('Upload a file'), onTap: () => Navigator.of(context).pop(_AttachmentAction.file)),
              ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.of(context).pop(_AttachmentAction.photo)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == _AttachmentAction.file) await _pickFile();
    else if (action == _AttachmentAction.photo) await _capturePhoto();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() { _attachmentName = result.files.first.name; _attachmentPath = result.files.first.path; });
    }
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 2000);
    if (photo != null) {
      setState(() { _attachmentName = photo.name; _attachmentPath = photo.path; });
    }
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: _buildFormCard()),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard() {
    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('New Complaint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87))),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: Color(0xFFE74C3C)), tooltip: 'Close'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Log the issue so maintenance can respond quickly.', style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE9E9E9)),
            const SizedBox(height: 18),
            
            // --- DROPDOWNS ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F312B))),
                      const SizedBox(height: 8),
                      CategoryDropdown(
                        categories: const ['HVAC', 'Electrical', 'Civil', 'Plumbing'],
                        selectedValue: _category,
                        onChanged: (value) { if (value != null) setState(() => _category = value); },
                        hintText: 'Category',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Priority', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F312B))),
                      const SizedBox(height: 8),
                      CategoryDropdown(
                        categories: const ['Low', 'Medium', 'High'],
                        selectedValue: _priority,
                        onChanged: (value) { if (value != null) setState(() => _priority = value); },
                        hintText: 'Priority',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            // --- LOCATION TEXT FIELDS ---
            Row(
              children: [
                Expanded(child: TextFormField(controller: _buildingController, decoration: const InputDecoration(labelText: 'Building', hintText: 'E.g. Congo House', filled: true, fillColor: Color(0xFFF8F8F8), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)))))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _roomController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Room number', hintText: 'E.g. 320', filled: true, fillColor: Color(0xFFF8F8F8), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)))))),
              ],
            ),
            const SizedBox(height: 12),
            
            // --- DETAILS ---
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Describe your complaint', alignLabelWithHint: true, filled: true, fillColor: Color(0xFFF8F8F8), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please provide some details';
                if (value.trim().length < 20) return 'Add at least 20 characters so we can assist you better';
                return null;
              },
            ),
            const SizedBox(height: 14),
            
            // --- ATTACHMENT WIDGET ---
            Text('Attachment Upload', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickAttachment,
              child: Container(
                height: 130, width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE3E3E3))),
                child: _attachmentPath == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.black54), SizedBox(height: 8), Text('Drop files, browse, or take a photo', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))])
                    : Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_attachmentPath!), width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black.withOpacity(0.15))),
                          Positioned(left: 12, right: 12, bottom: 12, child: Text(_attachmentName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                          Positioned(top: 10, right: 10, child: GestureDetector(onTap: () => setState(() { _attachmentName = null; _attachmentPath = null; }), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)))),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            
            // --- ACTION BUTTONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _saveAsDraft, 
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87, 
                    side: const BorderSide(color: Color(0xFFCDCDCD)), 
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ), 
                  child: const Text('Save as Draft'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) return const Color(0xFF0C8E3E);
                      if (_isSubmitting) return Colors.grey;
                      return const Color(0xFF12B36A);
                    }),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      );
  }
}
enum _AttachmentAction { file, photo }