import 'package:flutter/material.dart';


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
              // Navigator.restorablePopAndPushNamed(context, "/");
              Navigator.popUntil(context, ModalRoute.withName("/"));
              ModalRoute<dynamic>? top = ModalRoute.of(context);
              if (top != null &&
                  !(top is MaterialPageRoute && top.settings.name == "/")) {
                Navigator.pushNamed(context, "/");
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Navigator.restorablePopAndPushNamed(context, "/history");
              Navigator.popUntil(context, ModalRoute.withName("/history"));
              ModalRoute<dynamic>? top = ModalRoute.of(context);
              if (top != null &&
                  !(top is MaterialPageRoute &&
                      top.settings.name == "/history")) {
                Navigator.pushNamed(context, "/history");
              }
            },
          ),
        ],
      ),
    );
  }
}
