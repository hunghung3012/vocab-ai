import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home/home_screen.dart';
import 'screens/docks/dashboard_screen.dart';
import 'screens/docks/create_deck_screen.dart';
import 'screens/docks/study_screen.dart';
import 'screens/docks/edit_deck_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/docks/import_anki_screen.dart';
import 'models/deck.dart';
import 'firebase_options.dart';
import 'screens/docks/decks_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with auto-generated config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInAnonymously();

  runApp(const VocabAIApp());
}

class VocabAIApp extends StatelessWidget {
  const VocabAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocabAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            );
          case '/decks':
            return MaterialPageRoute(
              builder: (_) => const DecksScreen(),
            );
          case '/create-deck':
            return MaterialPageRoute(
              builder: (_) => const CreateDeckScreen(),
            );
          case '/study':
            final deck = settings.arguments as Deck;
            return MaterialPageRoute(
              builder: (_) => StudyScreen(deck: deck),
            );
          case '/edit-deck':
            final deck = settings.arguments as Deck;
            return MaterialPageRoute(
              builder: (_) => EditDeckScreen(deck: deck),
            );
          case '/chat':
            return MaterialPageRoute(
              builder: (_) => const ChatScreen(),
            );
          case '/quiz':
            final deck = settings.arguments as Deck?;
            return MaterialPageRoute(
              builder: (_) => QuizScreen(deck: deck),
            );
          case '/import-anki':
            return MaterialPageRoute(
              builder: (_) => const ImportAnkiScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
        }
      },
    );
  }
}

// Auth Wrapper để check authentication
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement authentication check
    // For now, directly show home screen
    return const HomeScreen();
  }
}