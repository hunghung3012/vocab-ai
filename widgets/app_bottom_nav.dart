import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.style),
          label: 'Decks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: 'Quiz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
      ],
      onTap: (index) {
        // Tránh navigate lại chính trang hiện tại
        if (index == currentIndex) return;

        switch (index) {
          case 0: // Home
            Navigator.pushReplacementNamed(context, '/');
            break;
          case 1: // Dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case 2: // Decks
            Navigator.pushReplacementNamed(context, '/decks');
            break;
          case 3: // Quiz
            Navigator.pushReplacementNamed(context, '/quiz');
            break;
          case 4: // Chat
            Navigator.pushReplacementNamed(context, '/chat');
            break;
        }
      },
    );
  }
}