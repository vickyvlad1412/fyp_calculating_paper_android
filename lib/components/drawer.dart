import 'package:calculating_paper/components/drawer_tile.dart';
import 'package:flutter/material.dart';
import '../pages/settings_page.dart';
import '../pages/view_archive_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // header
          const DrawerHeader(
              child: Icon(Icons.home_outlined),
          ),

          const SizedBox(height: 25),

          // notes tile
          DrawerTile(
            title: "Notes",
            leading: const Icon(Icons.note_alt_outlined),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // archive tile
          DrawerTile(
              title: "Archive",
              leading: const Icon(Icons.archive_outlined),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ArchivePage(),
                  ),
                );
              },
          ),

          // settings tile
          DrawerTile(
            title: "Settings",
            leading: const Icon(Icons.settings_outlined),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}