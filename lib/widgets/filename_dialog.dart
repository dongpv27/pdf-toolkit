import 'package:flutter/material.dart';

/// Asks the user for an output file name before saving.
///
/// Returns the entered name (without forcing a `.pdf` suffix — the services add
/// it), or `null` if the user cancels. An empty field resolves to [defaultName]
/// so the user can just tap Save to accept the suggestion.
Future<String?> promptFileName(
  BuildContext context, {
  required String defaultName,
  Color? accent,
  String saveLabel = 'Save',
}) {
  final controller = TextEditingController(text: defaultName);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: defaultName.length,
  );

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('File name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: 'Enter a name',
          suffixText: '.pdf',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, _clean(v, defaultName)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, _clean(controller.text, defaultName)),
          style: accent == null
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
          child: Text(saveLabel),
        ),
      ],
    ),
  );
}

/// Sanitises a file name: strips path separators / illegal characters and
/// falls back to [fallback] when empty.
String _clean(String input, String fallback) {
  var name = input.trim();
  if (name.toLowerCase().endsWith('.pdf')) {
    name = name.substring(0, name.length - 4);
  }
  name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
  return name.isEmpty ? fallback : name;
}
