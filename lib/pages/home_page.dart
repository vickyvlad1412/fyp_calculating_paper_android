import 'package:calculating_paper/pages/search_result_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/drawer.dart';
import '../components/note_tile.dart';
import '../models/note_database.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/note.dart';
import 'edit_note_page.dart';
import 'new_note_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    // on app startup, fetch existing notes
    // on app startup, fetch archived notes
    readNotes();

  }

  // create a note
  void createNote() {
    final newNote = Note()
      ..header = ''
      ..serializedBlocks = '[]'
      ..isArchived = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewNotePage(note: newNote),
      ),
    );
  }

  // read a note
  void readNotes() {
    context.read<NoteDatabase>().fetchNotes();
    context. read<NoteDatabase>().fetchArchivedNotes();
  }

  // update a note
  void updateNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNotePage(note: note),
      ),
    );
  }

  // archive a note
  void archiveNote(int id) {
    context.read<NoteDatabase>().archiveNote(id);
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

    // current notes
    List<Note> currentNotes = List.from(noteDatabase.currentNotes)
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 25),
            child: IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SearchResultPage()),
                );
              },
              icon: Icon(
                Icons.search_outlined,
                color: Theme.of(context).colorScheme.inversePrimary,
              )
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: createNote,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.inversePrimary,),
      ),
      drawer: const MyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: Text(
                'Numora',
                style: GoogleFonts.dmSerifText(
                  fontSize: 38,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
            ),
          ),

          // List of Notes
          Expanded(
            child: ListView.builder(
              itemCount: currentNotes.length,
              itemBuilder: (context, index) {
                // get individual notes
                final note = currentNotes[index];

                // List tile UI
                return NoteTile(
                  note: note,
                  header: note.header,
                  blocks: note.blocks,
                  isArchived: note.isArchived,
                  onDeletePressed: () => _confirmDeleteNote(note.id),
                  onArchivePressed: () => archiveNote(note.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}