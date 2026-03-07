import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Readonly priority badge
class PriorityBadge extends StatelessWidget {
  final String? priorityLevel;

  const PriorityBadge({super.key, this.priorityLevel});

  @override
  Widget build(BuildContext context) {
    final String priority = priorityLevel ?? 'Medium';
    
    Color priorityColor;
    IconData priorityIcon;

    switch (priority) {
      case 'High':
        priorityColor = Colors.red;
        priorityIcon = Icons.warning_amber_rounded;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.error_outline_rounded;
        break;
      case 'Low':
      default:
        priorityColor = Colors.grey;
        priorityIcon = Icons.low_priority_rounded; 
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priorityIcon, color: priorityColor, size: 16),
          const SizedBox(width: 6),
          Text(
            'Priority: $priority',
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Editable priority dropdown for Facility Managers
class FacilityManagerPriorityEditor extends StatefulWidget {
  final String ticketId;
  final String initialPriority;

  const FacilityManagerPriorityEditor({
    super.key,
    required this.ticketId,
    required this.initialPriority,
  });

  @override
  State<FacilityManagerPriorityEditor> createState() => _FacilityManagerPriorityEditorState();
}

class _FacilityManagerPriorityEditorState extends State<FacilityManagerPriorityEditor> {
  late String _currentPriority;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentPriority = widget.initialPriority;
  }

  Future<void> _updatePriority(String newPriority) async {
    if (newPriority == _currentPriority) return;
    
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(widget.ticketId).update({
        'priority': newPriority,
      });
      setState(() {
        _currentPriority = newPriority;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority updated to $newPriority'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update priority'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Priority: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _isUpdating 
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentPriority,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  items: ['Low', 'Medium', 'High'].map((String priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: priority == 'High' 
                              ? Colors.red 
                              : (priority == 'Medium' ? Colors.orange : Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => val != null ? _updatePriority(val) : null,
                ),
              ),
        ),
      ],
    );
  }
}