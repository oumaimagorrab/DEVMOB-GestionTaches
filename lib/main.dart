import 'package:flutter/material.dart';
import 'views/auth/welcome_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'views/project/dashboard_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'views/project/project_liste_page.dart';
import 'views/project/create_project_page.dart';
import 'views/profile/team_member_page.dart';
import 'views/profile/user_profile_page.dart';
import 'views/task/task_board_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),
      theme: ThemeData(
        primaryColor: const Color(0xFF6B4EFF),
        fontFamily: 'Inter', // Ou votre police préférée
        useMaterial3: true,
      ),

      // Page qui s'affiche au démarrage
      initialRoute: '/',

      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) =>  DashboardPage(),
        '/projects': (context) =>  ProjectsPage(),
        '/createprojects': (context) => CreateProjectPage(),
        '/team': (context) =>  TeamMembersPage(),
        '/userprofile': (context) =>  ProfilePage(),
        '/kanban' : (context) => KanbanBoardPage(),
      },
    );
  }
}