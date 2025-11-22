// lib/widgets/search_bar.dart

/// DEPRECATED: This custom `SearchBar` widget is no longer used in the app.
/// Modern screens use an inline `TextField` with custom padding and styling
/// directly in their build methods for simpler control and fewer files.
/// You can safely delete this file once all legacy references are removed.
///
/// A reusable search input field with:
///   • `hintText` – placeholder text (defaults to "Search stocks").
///   • `controller` – drives the input’s content and selection.
///   • `onClear` – optional callback invoked when the clear ("×") icon is tapped.
///
/// Appearance:
///   • Light/dark‐aware text styling via the current theme’s `bodyLarge`.
///   • Prefix search icon (magnifying glass).
///   • Suffix clear icon appears only when the text is non-empty.
///   • Rounded 12px radius and filled background using `AppColors.cardBackground`.
///
/// Legacy usage example:
/// ```dart
/// final ctrl = TextEditingController();
/// SearchBar(
///   hintText: 'Search companies…',
///   controller: ctrl,
///   onClear: () {
///     ctrl.clear();
///     // trigger parent setState if needed
///   },
/// )
/// ```


import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart'; // for AppColors, if you want to style text with it

class SearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final VoidCallback? onClear;

  const SearchBar({
    Key? key,
    this.hintText = 'Search stocks',
    required this.controller,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconColor = Theme.of(context).unselectedWidgetColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textHigh),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: iconColor),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
            icon: Icon(Icons.clear, color: iconColor),
            onPressed: onClear,
          ),
          hintText: hintText,
          hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) {
          // If you want live‐update of the clear button, you can call setState from parent via onClear
        },
      ),
    );
  }
}
