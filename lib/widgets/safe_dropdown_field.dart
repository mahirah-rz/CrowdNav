import 'package:flutter/material.dart';

class SafeDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;

  const SafeDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, color: const Color(0xFF123D35)),
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
        ),
      ),
      selectedItemBuilder: (_) => items
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
          .toList(),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
