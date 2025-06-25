import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calculating_paper/models/note_database.dart';
import '../components/note_tile.dart';
import '../models/note.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {

  // unarchive a note
  void unarchiveNote(int id) {
    context.read<NoteDatabase>().unarchiveNote(id);
  }

  // delete a note
  void deleteNote(int id) {
    context.read<NoteDatabase>().deleteNote(id);
  }

  void _confirmDeleteNote(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Note',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this note?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                deleteNote(id);
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    // note database
    final noteDatabase = context.watch<NoteDatabase>();

    List<Note> archivedNotes = noteDatabase.archivedNotes.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Archived Notes"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView.builder(
            itemCount: archivedNotes.length,
            itemBuilder: (context, index) {
              final note = archivedNotes[index];
              return NoteTile(
                note: note,
                header: note.header,
                blocks: note.blocks,
                isArchived: note.isArchived,
                onDeletePressed: () => _confirmDeleteNote(note.id), // Delete note
                onArchivePressed: () => unarchiveNote(note.id), // Unarchive note
              );
            },
          ),
    );
  }
}
