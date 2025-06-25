import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/noteblock.dart';
import '../components/search_tile.dart';
import '../models/note_database.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  _SearchResultPageState createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the query from the text controller
    final query = _controller.text;
    final notes = context.watch<NoteDatabase>().currentNotes;

    // Filter notes based on query only if the query is not empty
    final searchResults = query.isEmpty
        ? []
        : notes.where((note) {
      final headerMatch =
      note.header.toLowerCase().contains(query.toLowerCase());
      final contentMatch = note.blocks.whereType<TextBlock>().any(
            (block) => block.content.toLowerCase().contains(query.toLowerCase()),
      );
      return headerMatch || contentMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration.collapsed(
            hintText: "Search",
            hintStyle: TextStyle(
              color:
              Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
            ),
          ),
          autofocus: true,
          onChanged: (_) {
            setState(() {}); // Trigger a rebuild when the query changes
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: query.isEmpty
          ? Center(
            child: Text(
              'Start typing to search',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          )
          : searchResults.isEmpty
              ? Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final note = searchResults[index];
                    return SearchTile(
                      note: note,
                      query: query,
                    );
                  },
                ),
    );
  }
}

