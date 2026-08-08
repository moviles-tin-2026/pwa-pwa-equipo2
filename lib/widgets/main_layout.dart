import 'package:flutter/material.dart';
import 'sidebar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: isMobile ? const SimpleSidebar(isMobile: true) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xff362419),
              foregroundColor: Colors.white,
              title: const Text('Coffee Cat'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) const SimpleSidebar(isMobile: false),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
