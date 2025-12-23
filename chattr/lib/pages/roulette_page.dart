import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/models.dart';
import 'chat_room_page.dart';
import 'dart:convert';

class RoulettePage extends StatefulWidget {
  const RoulettePage({super.key});

  @override
  State<RoulettePage> createState() => _RoulettePageState();
}

class _RoulettePageState extends State<RoulettePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isMatching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startMatching() async {
    setState(() => _isMatching = true);
    
    // Artificial delay for "searching" effect
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await ApiService.get('/roulette/match');
      if (response.statusCode == 200) {
        final chatJson = jsonDecode(response.body);
        final chat = Chat.fromJson(chatJson);
        
        if (mounted) {
          // Find the "other" user in the chat
          // In roulette, it's either user1 or user2 that isn't the current user
          // For simplicity, we get it from the chat object directly if backend returns it
          final otherUser = chat.user1?.id == 0 ? chat.user2 : chat.user1; // Simplistic check

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(
                chat: chat,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No users found for matching. Try again later!')),
          );
        }
      }
    } catch (e) {
      print("Roulette error: $e");
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[400]!, Colors.blue[600]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chattr Roulette',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Meet someone new, right now.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 60),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 200 * _animationController.value + 100,
                        height: 200 * _animationController.value + 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.shuffle,
                      size: 60,
                      color: Colors.purple[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              if (_isMatching)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text('Searching for a match...', style: TextStyle(color: Colors.white)),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _startMatching,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[800],
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Start Matching'),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
