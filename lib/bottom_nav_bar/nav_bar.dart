import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/data/local/local_store.dart';
import '../core/data/local/pending_events_local_data_source.dart';
import '../core/theme/app_colors.dart';
import '../features/attendance/presentation/view/attendance_screen.dart';
import '../features/dashboard/presentation/view/dashboard_screen.dart';
import '../features/leave/presentation/view/leave_screen.dart';
import '../features/sync/presentation/view/sync_queue_screen.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    AttendanceScreen(),
    LeaveScreen(),
    SyncQueueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Leave',
          ),
          NavigationDestination(
            icon: ValueListenableBuilder<Box<dynamic>>(
              valueListenable: LocalStore.pendingEventsBox.listenable(),
              builder: (context, _, child) {
                final pending = PendingEventsLocalDataSource().pendingCount;
                return Badge(
                  label: Text('$pending'),
                  backgroundColor: AppColors.pending,
                  isLabelVisible: pending > 0,
                  child: child,
                );
              },
              child: const Icon(Icons.sync_outlined),
            ),
            selectedIcon: Icon(
              Icons.sync,
              color: AppColors.primary,
            ),
            label: 'Sync',
          ),
        ],
      ),
    );
  }
}
