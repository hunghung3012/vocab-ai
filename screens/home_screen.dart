import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book, color: Colors.white),
          ),
        ),
        title: const Text(
          'VocabAI',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨ '),
                        Text(
                          'AI-Powered Learning',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Master English\nwith '),
                        TextSpan(
                          text: 'AI\nIntelligence',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Learn vocabulary the smart way. Import Anki decks, take interactive quizzes, chat with AI, and unlock your potential with personalized English learning.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/dashboard');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Get Started Free',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Learn More',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.style,
                      color: Colors.purple,
                      title: 'Flashcard Learning',
                      subtitle: 'Spaced repetition algorithm',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.lightbulb_outline,
                      color: Colors.blue,
                      title: 'Smart Quizzes',
                      subtitle: 'Adaptive difficulty levels',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.chat_bubble_outline,
                      color: Colors.amber,
                      title: 'AI Conversations',
                      subtitle: 'Real-time practice',
                    ),
                  ],
                ),
              ),
            ),

            // Learning Features Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Powerful Learning Features',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything you need to master English vocabulary efficiently and enjoyably',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureCard(
                    icon: Icons.style_outlined,
                    color: Colors.purple,
                    title: 'Anki-style Learning',
                    description: 'Flashcard-based vocabulary learning with spaced repetition algorithm for optimal retention',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.quiz_outlined,
                    color: Colors.blue,
                    title: 'Smart Quiz',
                    description: 'Multiple choice, fill-in-the-blank, and contextual quizzes powered by intelligent algorithms',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.cyan,
                    title: 'AI Chat',
                    description: 'Interactive conversations with AI to practice real-world English communication',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.camera_alt_outlined,
                    color: Colors.orange,
                    title: 'Image Recognition',
                    description: 'Take photos and instantly learn the vocabulary words for objects you capture',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.auto_awesome,
                    color: Colors.red,
                    title: 'Smart Examples',
                    description: 'AI generates contextual example sentences tailored to your difficulty level',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.trending_up,
                    color: Colors.pink,
                    title: 'Personalized Learning',
                    description: 'Adaptive suggestions based on your preferences and learning patterns',
                  ),
                ],
              ),
            ),

            // How It Works Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start learning in just a few simple steps',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildHowItWorksStep(
                    number: '1',
                    title: 'Import Your Decks',
                    description: 'Upload Anki decks or create custom vocabulary sets',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  _buildHowItWorksStep(
                    number: '2',
                    title: 'Learn Actively',
                    description: 'Study with flashcards, quizzes, and AI-generated examples',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  _buildHowItWorksStep(
                    number: '3',
                    title: 'Practice Speaking',
                    description: 'Chat with AI and learn pronunciation naturally',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  _buildHowItWorksStep(
                    number: '4',
                    title: 'Track Progress',
                    description: 'Monitor your learning journey with detailed analytics',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
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
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 2:
              Navigator.pushNamed(context, '/quiz');
              break;
            case 3:
              Navigator.pushNamed(context, '/chat');
              break;
          }
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep({
    required String number,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}