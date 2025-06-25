import 'package:calculating_paper/theme/theme_provider.dart';
import 'package:calculating_paper/components/decimal_precision_provider.dart';
import 'package:flutter/material.dart';
import 'package:calculating_paper/models/note_database.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/edit_note_page.dart';
import 'models/note.dart';

void main() async {
  // initialize note isar database
  WidgetsFlutterBinding.ensureInitialized();
  await NoteDatabase.initialize();
  runApp(
    MultiProvider(
      providers: [
        // Note Provider
        ChangeNotifierProvider(create: (context) => NoteDatabase()),
        // Theme Provider
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Decimal Precision Provider
        ChangeNotifierProvider(create: (context) => DecimalPrecisionProvider())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _homePage = const Scaffold(); //default placeholder

  @override
  void initState() {
    super.initState();
    _determineStartupPage();
  }

  Future<void> _determineStartupPage() async {
    final isar = NoteDatabase.isar;
    final notes = await isar.notes.filter().isArchivedEqualTo(false).sortByLastEditedDesc().findAll();

    setState(() {
      if(notes.isNotEmpty) {
        _homePage = EditNotePage(note: notes.first);
      } else {
        _homePage = const HomePage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _homePage,
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}

