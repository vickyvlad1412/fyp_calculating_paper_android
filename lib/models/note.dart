import 'dart:convert';
import 'package:isar/isar.dart';
import '../components/noteblock.dart';

// this line is needed to generate file
// then run: dart run build_runner build
part 'note.g.dart';

@Collection()
class Note {
  Id id = Isar.autoIncrement;
  late String header;
  late String serializedBlocks;
  bool isArchived = false;
  late DateTime lastEdited;

  // Helper methods to convert between JSON and block objects
  @ignore
  List<NoteBlock> get blocks {
    final decoded = jsonDecode(serializedBlocks) as List;
    return decoded.map((e) => NoteBlock.fromJson(e)).toList();
  }

  set blocks(List<NoteBlock> blocks) {
    serializedBlocks = jsonEncode(blocks.map((e) => e.toJson()).toList());
  }

}