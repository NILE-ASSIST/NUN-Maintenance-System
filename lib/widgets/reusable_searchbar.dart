import 'package:flutter/material.dart';

class ReusableSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const ReusableSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<ReusableSearchBar> createState() => _ReusableSearchBarState();
}

class _ReusableSearchBarState extends State<ReusableSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Listen to changes so we can show or hide the 'X' clear button
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _hasText = _controller.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // YOUR EXACT DESIGN
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(color: Colors.black, fontSize: 16), // Ensures text is visible as you type
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          
          // The 'X' button that only shows up when you type
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                  onPressed: () {
                    _controller.clear(); // Clears the UI
                    widget.onChanged(''); // Resets the filter list
                    FocusScope.of(context).unfocus(); // Hides keyboard
                  },
                )
              : null,
              
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}