import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import '../models/note.dart';
import '../pages/edit_note_page.dart';
import '../pages/view_note_page.dart';
import 'note_settings.dart';
import 'package:google_fonts/google_fonts.dart';
import 'noteblock.dart';

class NoteTile extends StatefulWidget {
  final Note note;
  final String header;
  final List<NoteBlock> blocks;
  final bool isArchived;
  final void Function()? onDeletePressed;
  final void Function()? onArchivePressed;

  const NoteTile({
    super.key,
    required this.note,
    required this.header,
    required this.blocks,
    required this.isArchived,
    required this.onDeletePressed,
    required this.onArchivePressed,
  });

  @override
  NoteTileState createState() => NoteTileState();
}

class NoteTileState extends State<NoteTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 10, left: 25, right: 25),
      child: ListTile(
        title: Text(
          widget.header,
          style: GoogleFonts.dmSerifText(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        onTap: () {
          if (widget.note.isArchived) {
            // Navigate to ViewNotePage if the note is archived
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewNotePage(note: widget.note),
              ),
            );
          } else {
            // Navigate to EditNotePage if the note is not archived
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditNotePage(note: widget.note),
              ),
            );
          }
        },
        trailing: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showPopover(
              width: 100,
              height: 100,
              backgroundColor: Theme.of(context).colorScheme.surface,
              context: context,
              bodyBuilder: (context) => NoteSettings(
                onDeleteTap: widget.onDeletePressed,
                onArchiveTap: widget.onArchivePressed,
                isArchived: widget.isArchived,
              ),
            ),
          ),
        ),
      ),
    );
  }
}