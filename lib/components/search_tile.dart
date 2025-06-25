import 'package:flutter/material.dart';
import '../models/note.dart';
import '../pages/edit_note_page.dart';
import 'highlight_text.dart';
import 'noteblock.dart';

class SearchTile extends StatelessWidget {
  final Note note;
  final String query;

  const SearchTile({super.key, required this.note, required this.query});

  @override
  Widget build(BuildContext context) {
    // Highlight text styling
    final highlightStyle = TextStyle(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      color: Theme.of(context).colorScheme.inversePrimary,
      fontWeight: FontWeight.bold,
    );

    final normalStyle = TextStyle(
      color: Theme.of(context).colorScheme.inversePrimary,
    );

    final headerStyle = TextStyle(
      color: Theme.of(context).colorScheme.inversePrimary,
      fontWeight: FontWeight.bold,
    );

    // Extract lines containing the query
    final matchingLines = note.blocks
        .whereType<TextBlock>()
        .expand((block) => block.content.split('\n'))
        .where((line) => line.toLowerCase().contains(query.toLowerCase())) // Filter lines containing the query
        .join('\n'); // Join the matching lines back into a string

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 10, left: 25, right: 25),
      child: ListTile(
        title: HighlightedText(
          text: note.header,
          query: query,
          highlightStyle: highlightStyle,
          textStyle: headerStyle,
        ),
        subtitle: HighlightedText(
          text: matchingLines.isEmpty ? "No relevant content found" : matchingLines,
          query: query,
          highlightStyle: highlightStyle,
          textStyle: normalStyle,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditNotePage(note: note),
            ),
          );
        },
      ),
    );
  }
}

