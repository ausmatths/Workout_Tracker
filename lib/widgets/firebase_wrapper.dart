import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class FirebaseWrapper extends StatefulWidget {
  final Widget child;

  const FirebaseWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _FirebaseWrapperState createState() => _FirebaseWrapperState();
}

class _FirebaseWrapperState extends State<FirebaseWrapper> {
  bool _hasCheckedAuth = false;
  AuthService? _authService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store the auth service reference when it's safe to do so
    _authService = Provider.of<AuthService>(context, listen: false);
    // Only run check auth state once
    if (!_hasCheckedAuth) {
      _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    if (_authService == null) return;

    // Check if user is already authenticated
    final isAuthenticated = _authService!.isAuthenticated();
    print('Firebase authentication check: user is authenticated: $isAuthenticated');

    // If not authenticated, sign in anonymously
    if (!isAuthenticated) {
      try {
        final credential = await _authService!.signInAnonymously();
        print('User signed in anonymously with ID: ${credential.user?.uid}');
      } catch (e) {
        print('Error signing in anonymously: $e');
      }
    } else {
      final userId = _authService!.getUserId();
      print('Authenticated user ID: $userId');
    }

    if (mounted) {
      setState(() {
        _hasCheckedAuth = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedAuth) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}