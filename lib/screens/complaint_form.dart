import 'package:flutter/material.dart';

import 'dart:math';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _buildingController = TextEditingController();
  final _roomController = TextEditingController();
  final _detailsController = TextEditingController();
  String _category = 'Select a category';
  String? _attachmentName;

  @override
  void dispose() {
    _buildingController.dispose();
    _roomController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Complaint submitted. Our team will reach out soon.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final action = await showModalBottomSheet<_AttachmentAction>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: const Text('Upload a file'),
                onTap: () => Navigator.of(context).pop(_AttachmentAction.file),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop(_AttachmentAction.photo),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == _AttachmentAction.file) {
      await _pickFile();
    } else if (action == _AttachmentAction.photo) {
      await _capturePhoto();
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() => _attachmentName = result.files.first.name);
    }
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 2000);
    if (photo != null) {
      setState(() => _attachmentName = photo.name);
    }
  }

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
            Center(
              child: Image.asset(
                'assets/images/logo-removebg-preview.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFormHeader()),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFE74C3C)),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Log the issue so maintenance can respond quickly.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE9E9E9)),
            const SizedBox(height: 18),
            _buildCategoryField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buildingController,
                    decoration: const InputDecoration(
                      labelText: 'Building',
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _roomController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Room number',
                      filled: true,
                      fillColor: Color(0xFFF8F8F8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Describe your complaint',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Color(0xFFF8F8F8),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide some details';
                }
                if (value.trim().length < 20) {
                  return 'Add at least 20 characters so we can assist you better';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachment Upload',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickAttachment,
                  child: Container(
                    height: 116,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE3E3E3)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.black54),
                          const SizedBox(height: 8),
                          Text(
                            _attachmentName ?? 'Drop files, browse, or take a photo',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFCDCDCD)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: const Text('Save as Draft'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return const Color(0xFF0C8E3E);
                      }
                      return const Color(0xFF12B36A);
                    }),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildFormHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Complaint',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F312B),
          ),
        ),
        const SizedBox(height: 8),
        CategoryDropdown(
          categories: const ['HVAC', 'Electrical', 'Civil', 'Plumbing', 'Others'],
          selectedValue: _category,
          onChanged: (value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
          hintText: 'Category',
        ),
      ],
    );
  }
}



class _LegacyCupertinoPickerSheet extends StatelessWidget {
  const _LegacyCupertinoPickerSheet({
    required this.categories,
    required this.selectedValue,
    required this.hintText,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedValue;
  final String hintText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final initialIndex = selectedValue != null ? categories.indexOf(selectedValue!).clamp(0, categories.length - 1) : 0;
    return SafeArea(
      child: CupertinoActionSheet(
        title: Text(
          hintText,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        message: SizedBox(
          height: min(240.0, MediaQuery.of(context).size.height * 0.35),
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: initialIndex),
            magnification: 1.05,
            itemExtent: 42,
            onSelectedItemChanged: (index) => onSelected(categories[index]),
            children: categories
                .map(
                  (item) => Center(
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: item == selectedValue ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}




enum _AttachmentAction { file, photo }

Color _opacity(Color color, double opacity) =>
    color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));

// void main() {
//   runApp(const MainApp());
// }

class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.onChanged,
    this.selectedValue,
    this.hintText = 'Select category',
  });

  final List<String> categories;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String hintText;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> with SingleTickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _entry;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Size _fieldSize = const Size(double.infinity, 56);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_entry != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    if (Platform.isIOS) {
      _openCupertino();
      return;
    }

    _removeEntry();

    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _fieldSize = box.size;

    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, _fieldSize.height + 6),
            child: _DropdownPanel(
              width: _fieldSize.width,
              categories: widget.categories,
              selectedValue: widget.selectedValue,
              fade: _fade,
              slide: _slide,
              onSelect: (value) {
                widget.onChanged(value);
                _close();
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);
    _controller.forward(from: 0);
  }

  void _close() {
    _controller.reverse();
    _removeEntry();
  }

  Future<void> _openCupertino() async {
    final useModern = _isModernIOS();
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      barrierColor: _opacity(CupertinoColors.black, 0.15),
      builder: (context) {
        if (useModern) {
          return _ModernCupertinoPickerSheet(
            categories: widget.categories,
            selectedValue: widget.selectedValue,
            hintText: widget.hintText,
            onSelected: (value) => Navigator.of(context, rootNavigator: true).pop(value),
          );
        }
        return _LegacyCupertinoPickerSheet(
          categories: widget.categories,
          selectedValue: widget.selectedValue,
          hintText: widget.hintText,
          onSelected: (value) => Navigator.of(context, rootNavigator: true).pop(value),
        );
      },
    );

    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.selectedValue ?? widget.hintText;
    final isHint = widget.selectedValue == null;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        key: _fieldKey,
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHint ? const Color(0xFFE3E3E3) : _opacity(const Color(0xFF0F9B4C), 0.55),
              width: 1.05,
            ),
            boxShadow: [
              BoxShadow(
                color: _opacity(Colors.black, 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isHint ? _opacity(const Color(0xFF1F312B), 0.55) : const Color(0xFF1F312B),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F9B4C)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  const _DropdownPanel({
    required this.width,
    required this.categories,
    required this.selectedValue,
    required this.fade,
    required this.slide,
    required this.onSelect,
  });

  final double width;
  final List<String> categories;
  final String? selectedValue;
  final Animation<double> fade;
  final Animation<Offset> slide;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxHeight = min(MediaQuery.of(context).size.height * 0.4, 280.0);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: width,
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _opacity(Colors.white, 0.22),
                        _opacity(Colors.white, 0.14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _opacity(Colors.white, 0.45), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: _opacity(Colors.black, 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (context, _) => Divider(
                      height: 1,
                      thickness: 0.75,
                      color: _opacity(Colors.black, 0.06),
                    ),
                    itemBuilder: (context, index) {
                      final item = categories[index];
                      final isSelected = item == selectedValue;
                      return InkWell(
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        onTap: () => onSelect(item),
                        child: Container(
                          color: isSelected ? _opacity(Colors.white, 0.14) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF1F312B),
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isModernIOS() {
  try {
    final version = Platform.operatingSystemVersion;
    final digits = RegExp(r'\d+').allMatches(version).map((m) => int.tryParse(m.group(0) ?? '0') ?? 0).toList();
    if (digits.isEmpty) return false;
    final major = digits.first;
    return major >= 26;
  } catch (_) {
    return false;
  }
}

class _ModernCupertinoPickerSheet extends StatelessWidget {
  const _ModernCupertinoPickerSheet({
    required this.categories,
    required this.selectedValue,
    required this.hintText,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedValue;
  final String hintText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: MediaQuery.of(context).viewInsets + const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _opacity(CupertinoColors.systemGrey6, 0.35),
                        _opacity(CupertinoColors.white, 0.20),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _opacity(CupertinoColors.white, 0.55), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _opacity(CupertinoColors.black, 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: CupertinoScrollbar(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final item = categories[index];
                              final isSelected = item == selectedValue;
                              return CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                onPressed: () => onSelected(item),
                                alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: CupertinoColors.label,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.6, color: CupertinoColors.separator),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}