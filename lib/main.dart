import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/auth/welcome_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/project/dashboard_page.dart';
import 'views/project/project_liste_page.dart';
import 'views/project/create_project_page.dart';
import 'views/profile/team_member_page.dart';
import 'views/profile/user_profile_page.dart';
import 'views/task/task_board_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/project_provider.dart'; // <- ajouté
import 'providers/task_provider.dart'; // <- ajouté

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()), // <- ajouté
      ],
      child: MaterialApp(
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
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomePage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/projects': (context) => const ProjectsPage(),
          '/createprojects': (context) => const CreateProjectPage(),
          '/team': (context) => const TeamMembersPage(),
          '/userprofile': (context) => const ProfilePage(),
          //'/kanban' : (context) => const KanbanBoardPage(),
        },
      ),
    );
  }
}