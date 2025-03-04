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

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Log authentication status
    final isAuthenticated = authService.isAuthenticated();
    print('Firebase authentication check: user is authenticated: $isAuthenticated');

    if (isAuthenticated) {
      final userId = authService.getUserId();
      print('Authenticated user ID: $userId');
    }

    setState(() {
      _hasCheckedAuth = true;
    });
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