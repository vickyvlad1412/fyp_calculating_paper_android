import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:calculating_paper/models/note.dart';
import 'package:path_provider/path_provider.dart';

class NoteDatabase extends ChangeNotifier {
  static late Isar isar;

  // Initialize database
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [NoteSchema],
      directory: dir.path,
    );
  }

  // list of notes
  final List<Note> currentNotes = [];
  final List<Note> archivedNotes = [];

  // Create
  Future<void> addNote(String headerFromUser, String serialized) async {
    // create a new note object
    final newNote = Note()
      ..header = headerFromUser
      ..serializedBlocks = serialized
      ..lastEdited = DateTime.now();

    // save to db
    await isar.writeTxn(() => isar.notes.put(newNote));

    fetchNotes(); // Refresh active notes
    fetchArchivedNotes(); // Refresh archived notes
  }

  // Archive a note
  Future<void> archiveNote(int id) async {
    final note = await isar.notes.get(id);
    if(note != null) {
      note.isArchived = true; // Mark as archived
      await isar.writeTxn(() => isar.notes.put(note));
      await fetchNotes(); // Update active notes
      await fetchArchivedNotes(); // Update archived notes
      notifyListeners();
    }
  }

  // Unarchive a note
  Future<void> unarchiveNote(int id) async {
    final note = await isar.notes.get(id);
    if(note != null) {
      note.isArchived = false;
      await isar.writeTxn(() => isar.notes.put(note));
      await fetchArchivedNotes(); // Update archived notes
      await fetchNotes(); // Update active notes
      notifyListeners();
    }
  }

  // Fetch only archived notes
  Future<void> fetchArchivedNotes () async {
    List<Note> fetchedArchivedNotes = await isar.notes.filter().isArchivedEqualTo(true).findAll();
    archivedNotes.clear();
    archivedNotes.addAll(fetchedArchivedNotes);
    notifyListeners();
  }

  // Fetch only active notes
  Future<void> fetchNotes() async {
    List<Note> fetchedNotes = await isar.notes.filter().isArchivedEqualTo(false).findAll();
    currentNotes.clear();
    currentNotes.addAll(fetchedNotes);
    notifyListeners();
  }


  // Update
  Future<void> updateNote(int id, String newHeader, String serialized) async {
    final existingNote = await isar.notes.get(id);
    if(existingNote != null) {
      existingNote.header = newHeader;
      existingNote.serializedBlocks = serialized;
      existingNote.lastEdited = DateTime.now();
      await isar.writeTxn(() => isar.notes.put(existingNote));
      await fetchNotes();
      await fetchArchivedNotes();
    }
  }

  // Delete
  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() => isar.notes.delete(id));
    await fetchNotes();
    await fetchArchivedNotes();
  }
}