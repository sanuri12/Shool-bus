import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _feedbackMessage = '';
  bool _isSuccess = false;
  String _debugInfo = '';
  bool _showDebugInfo = false;

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    setState(() {
      _feedbackMessage = '';
      _isSuccess = false;
      _debugInfo = '';
    });

    // Validate email input
    if (email.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please enter your email address';
      });
      return;
    }

    final bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(email);
    if (!emailValid) {
      setState(() {
        _feedbackMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _debugInfo += '📧 Attempting to send password reset to: $email\n';
      _debugInfo += '🔧 Firebase project ID: ${_auth.app.options.projectId}\n';
    });

    try {
      // Check if email exists
      List<String> signInMethods = [];
      try {
        signInMethods = await _auth.fetchSignInMethodsForEmail(email);
        setState(() {
          _debugInfo += '🔍 Sign-in methods found: ${signInMethods.isEmpty ? "None" : signInMethods.join(", ")}\n';
        });
        if (signInMethods.isEmpty) {
          setState(() {
            _feedbackMessage = 'No account found with this email address.';
            _isLoading = false;
            return;
          });
        }
      } catch (e) {
        setState(() {
          _debugInfo += '❌ Error checking sign-in methods: $e\n';
        });
      }

      // Attempt to send the password reset email with retry logic
      int retries = 0;
      const maxRetries = 2;
      bool success = false;
      while (retries < maxRetries && !success) {
        try {
          await _auth.sendPasswordResetEmail(email: email);
          success = true;
          setState(() {
            _debugInfo += '✅ Firebase reported success sending password reset email (Attempt ${retries + 1})\n';
            _debugInfo += '📬 Sender: noreply@${_auth.app.options.projectId}.firebaseapp.com\n';
          });
        } catch (e) {
          retries++;
          setState(() {
            _debugInfo += '⚠️ Failed attempt $retries: $e\n';
          });
          if (retries == maxRetries) {
            throw e;
          }
          await Future.delayed(const Duration(seconds: 1)); // Delay between retries
        }
      }

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _feedbackMessage = 'Reset link sent successfully! Check your inbox and spam folder.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo += '❌ FirebaseAuthException: [${e.code}] ${e.message}\n';
        switch (e.code) {
          case 'invalid-email':
            _feedbackMessage = 'The email address format is not valid.';
            break;
          case 'user-not-found':
            _feedbackMessage = 'No account found with this email address.';
            break;
          case 'too-many-requests':
            _feedbackMessage = 'Too many attempts. Please try again later.';
            break;
          default:
            _feedbackMessage = 'Error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _feedbackMessage = 'An unexpected error occurred. Please try again.';
        _debugInfo += '❌ General exception: $e\n';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo and header
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 80,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Forgot Your Password?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email address below and we\'ll send you a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your registered email',
                prefixIcon: const Icon(Icons.email, color: Colors.yellow),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.yellow, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Feedback message
            if (_feedbackMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Debug information (toggle with long press on button)
            if (_showDebugInfo && _debugInfo.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Info:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _debugInfo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Send reset link button
            GestureDetector(
              onTap: _isLoading ? null : _sendPasswordResetEmail,
              onLongPress: () {
                setState(() {
                  _showDebugInfo = !_showDebugInfo;
                });
              },
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 245, 227, 31),
                      Color.fromARGB(255, 241, 204, 70),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'SEND RESET LINK',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Return to login
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Login'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}