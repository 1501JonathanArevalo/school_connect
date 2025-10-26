// student_home.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_connect/screens/student/screens/assignments_tab.dart';
import 'package:school_connect/screens/student/screens/dashboard_tab.dart';
import 'package:school_connect/screens/student/screens/schedule_tab.dart';
import 'package:school_connect/shared/widgets/app_bar_with_gradient.dart';
import 'package:school_connect/services/notification_service.dart';
import 'package:school_connect/services/auth_navigation_service.dart';
import 'package:school_connect/screens/student/widgets/search_bar_widget.dart';
import 'package:school_connect/screens/student/widgets/user_menu_widget.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.requestPermission();
    await NotificationService.checkEventNotifications(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBarWithGradient(
          title: 'School Connect',
          subtitle: 'Portal Estudiante',
          leadingIcon: Icons.school,
          actions: [
            SearchBarWidget(controller: _searchController, userId: userId),
            const Spacer(),
            UserMenuWidget(
              userId: userId,
              onLogout: () => AuthNavigationService.signOut(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Inicio'),
              Tab(icon: Icon(Icons.assignment), text: 'Tareas'),
              Tab(icon: Icon(Icons.schedule), text: 'Horario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DashboardTab(userId: userId),
            AssignmentsTab(userId: userId),
            ScheduleTab(userId: userId),
          ],
        ),
      ),
    );
  }
}