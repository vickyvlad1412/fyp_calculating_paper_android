import 'package:flutter/cupertino.dart';

abstract class NoteBlock {
  Map<String, dynamic> toJson();

  static NoteBlock fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'text':
        return TextBlock.fromJson(json);
      case 'graph':
        return GraphBlock.fromJson(json);
      default:
        throw Exception('Unknown block type');
    }
  }
}

class TextBlock extends NoteBlock {
  String content;
  final TextEditingController controller;
  final GlobalKey key;

  TextBlock({String? initialContent})
      : content = initialContent ?? '',
        controller = TextEditingController(text: initialContent ?? ''),
        key = GlobalKey();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'content': controller.text,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(initialContent: json['content'] ?? '');
  }
}


class GraphBlock extends NoteBlock {
  List<String> equations;
  final TextEditingController controller;
  final GlobalKey key;

  // NEW: allow customizing domain (default –10…10):
  int minX, maxX, minY, maxY;

  GraphBlock({
    List<String>? initialEquations,
    this.minX = -10,
    this.maxX = 10,
    this.minY = -10,
    this.maxY = 10,
  })  : equations = initialEquations ?? [],
        controller = TextEditingController(
          text: (initialEquations != null && initialEquations.isNotEmpty)
              ? initialEquations.last
              : '',
        ),
        key = GlobalKey();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'graph',
    'equations': [controller.text],
    'minX': minX,
    'maxX': maxX,
    'minY': minY,
    'maxY': maxY,
  };

  factory GraphBlock.fromJson(Map<String, dynamic> json) {
    final rawEq = json['equations'] as List<dynamic>? ?? [];
    final eqList = rawEq.cast<String>();
    final latestEquation = eqList.isNotEmpty ? eqList.last : '';

    final int loadedMinX = json['minX'] is int ? json['minX'] : -10;
    final int loadedMaxX = json['maxX'] is int ? json['maxX'] : 10;
    final int loadedMinY = json['minY'] is int ? json['minY'] : -10;
    final int loadedMaxY = json['maxY'] is int ? json['maxY'] : 10;

    final block = GraphBlock(
      initialEquations: eqList,
      minX: loadedMinX,
      maxX: loadedMaxX,
      minY: loadedMinY,
      maxY: loadedMaxY,
    );

    block.controller.text = latestEquation;

    return block;
  }

}



