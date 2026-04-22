import 'package:flutter/material.dart';

import '../../inspection/presentation/inspection_hub_page.dart';
import '../../messages/presentation/messages_page.dart';
import '../../project/presentation/project_dashboard_page.dart';
import '../../profile/presentation/profile_page.dart';
import 'workbench_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      WorkbenchPage(
        onOpenInspection: () => setState(() => _currentIndex = 1),
        onOpenProject: () => setState(() => _currentIndex = 2),
      ),
      const InspectionHubPage(),
      const ProjectDashboardPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: '巡检',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: '项目',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: '消息',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
