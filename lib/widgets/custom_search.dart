import 'package:flutter/material.dart';
import '../core/theme.dart';

class CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const CustomSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: AppTheme.softShadow,
      ),

      child: TextField(
        onChanged: onChanged,

        decoration: const InputDecoration(
          hintText: 'Buscar estación...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }
}