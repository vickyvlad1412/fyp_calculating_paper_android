import 'package:flutter/material.dart';

class NoteSettings extends StatelessWidget {
  final void Function()? onDeleteTap;
  final void Function()? onArchiveTap;
  final bool isArchived;

  const NoteSettings ({
    super.key,
    required this.onDeleteTap,
    required this.onArchiveTap,
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // delete option
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            onDeleteTap!();
          },
          child: Container(
            height: 50,
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // archive/unarchive option
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            onArchiveTap!();
          },
          child: Container(
            height: 30,
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Text(
                isArchived? "Unarchive" : "Archive",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}