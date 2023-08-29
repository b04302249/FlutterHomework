import 'package:flutter/material.dart';
import 'package:homework/history_page.dart';
import 'package:homework/home_page.dart';


class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'My Sidebar',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Implement navigation to the Home screen here
              // Navigator.popUntil(context, ModalRoute.withName("/"));
              // ModalRoute<dynamic>? top = ModalRoute.of(context);
              // if (top != null &&
              //     !(top is MaterialPageRoute && top.settings.name == "/")) {
              //   Navigator.pushNamed(context, "/");
              //
              //   // Navigator.pushReplacementNamed(context, "/");
              // }
              Navigator.restorablePopAndPushNamed(context, "/");
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Implement navigation to the Settings screen here
              // Navigator.popUntil(context, ModalRoute.withName("/history"));
              // ModalRoute<dynamic>? top = ModalRoute.of(context);
              // if (top != null &&
              //     !(top is MaterialPageRoute &&
              //         top.settings.name == "/history")) {
              //   Navigator.pushNamed(context, "/history");
              //   // Navigator.pushReplacementNamed(context, "/history");
              // }
              // Navigator.pop(context);
              Navigator.restorablePopAndPushNamed(context, "/history");
            },
          ),
          // Add more ListTiles for other sidebar options
        ],
      ),
    );
  }
}
