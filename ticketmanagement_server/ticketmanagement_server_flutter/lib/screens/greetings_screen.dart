import 'package:flutter/material.dart';

import '../main.dart';

const _primaryColor = Color(0xFF6366F1);
const _successColor = Color(0xFF10B981);
const _errorColor = Color(0xFFF87171);
const _backgroundColor = Color(0xFFFCFCFC);
const _surfaceColor = Color(0xFFFFFFFF);

class GreetingsScreen extends StatefulWidget {
  final Future<void> Function()? onSignOut;
  const GreetingsScreen({super.key, this.onSignOut});

  @override
  State<GreetingsScreen> createState() => _GreetingsScreenState();
}

class _GreetingsScreenState extends State<GreetingsScreen> {
  final _textEditingController = TextEditingController();

  void _callHello() async {
    try {
      await client.greeting.hello(_textEditingController.text);
      setState(() {
        // result received
      });
    } catch (e) {
      setState(() {
        // error occurred
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Greeting App', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_emotions,
                    size: 80,
                    color: _primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hello, World!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your name to get a personalized greeting',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textEditingController,
                      decoration: const InputDecoration(
                        hintText: 'Your name',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.person, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _callHello,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Greeting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (widget.onSignOut != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: widget.onSignOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0E0E0),
                          foregroundColor: const Color(0xFF333333),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class ResultDisplay extends StatelessWidget {
  final String? resultMessage;
  final String? errorMessage;

  const ResultDisplay({super.key, this.resultMessage, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    String text;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (errorMessage != null) {
      backgroundColor = _errorColor.withValues(alpha: 0.1);
      textColor = _errorColor;
      icon = Icons.error;
      text = 'Error: $errorMessage';
    } else if (resultMessage != null) {
      backgroundColor = _successColor.withValues(alpha: 0.1);
      textColor = _successColor;
      icon = Icons.check_circle;
      text = resultMessage!;
    } else {
      backgroundColor = const Color(0xFFEEEEEE);
      textColor = const Color(0xFF666666);
      icon = Icons.hourglass_empty;
      text = 'Waiting for response...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: errorMessage != null ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
