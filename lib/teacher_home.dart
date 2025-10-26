import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_connect/shared/widgets/app_bar_with_gradient.dart';
import 'package:school_connect/services/auth_navigation_service.dart';
import 'package:school_connect/shared/widgets/logout_button.dart';
import 'screens/teacher/grades_screen.dart';
import 'screens/teacher/teacher_events_tab.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBarWithGradient(
          title: 'Panel Profesor',
          subtitle: 'School Connect',
          leadingIcon: Icons.school,
          actions: [
            LogoutButton(
              onPressed: () => AuthNavigationService.signOut(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: const Color(0xFF9575CD),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 16),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.class_, size: 24), height: 56, text: 'Mis Clases'),
                  Tab(icon: Icon(Icons.event, size: 24), height: 56, text: 'Eventos'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            GradesScreen(teacherId: userId),
            TeacherEventsTab(teacherId: userId),
          ],
        ),
      ),
    );
  }
}