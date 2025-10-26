import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final String userId;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _isSearching = widget.controller.text.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: widget.controller,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'Buscar tareas, eventos, materiales...',
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                  onPressed: () => widget.controller.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
            vertical: 10,
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
