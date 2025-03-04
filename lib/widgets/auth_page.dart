import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isAnonymousUpgrade = false;
  String _email = '';
  String _password = '';
  String _displayName = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      setState(() {
        _isAnonymousUpgrade = true;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (_isAnonymousUpgrade) {
        // Convert anonymous account to permanent account
        if (currentUser != null && currentUser.isAnonymous) {
          // Create email credential
          final credential = EmailAuthProvider.credential(
            email: _email,
            password: _password,
          );

          // Link anonymous account with email credential
          await currentUser.linkWithCredential(credential);

          // Update display name if provided
          if (_displayName.isNotEmpty) {
            await currentUser.updateDisplayName(_displayName);
          }

          // Refresh user
          await currentUser.reload();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account successfully created!')),
          );

          Navigator.pop(context); // Return to previous screen
        }
      } else if (_isLogin) {
        // Login
        await authService.signInWithEmailAndPassword(_email, _password);
      } else {
        // Register
        await authService.createUserWithEmailAndPassword(_email, _password, _displayName);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getReadableErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getReadableErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Email address is invalid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'credential-already-in-use':
        return 'This email is already linked to another account.';
      case 'provider-already-linked':
        return 'This authentication method is already linked to your account.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before upgrading your account.';
      default:
        return 'An error occurred: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAnonymousUpgrade ? 'Create Account' : (_isLogin ? 'Login' : 'Register')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isAnonymousUpgrade)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 28),
                            SizedBox(height: 8),
                            Text(
                              'You\'re currently using the app as a guest. Create an account to save your data permanently.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _email = value!.trim();
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value!;
                  },
                ),
                if (!_isLogin || _isAnonymousUpgrade) ...[
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Display Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _displayName = value!.trim();
                    },
                  ),
                ],
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text(_isAnonymousUpgrade
                      ? 'Create Account'
                      : (_isLogin ? 'Login' : 'Register')),
                ),
                SizedBox(height: 12),
                if (!_isAnonymousUpgrade)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = '';
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Don\'t have an account? Register'
                          : 'Already have an account? Login',
                    ),
                  ),
                SizedBox(height: 12),
                if (_isAnonymousUpgrade)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Continue as Guest'),
                  )
                else if (_isLogin)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                      // Anonymous sign-in for testing
                      try {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = '';
                        });
                        final authService = Provider.of<AuthService>(context, listen: false);
                        await authService.signInAnonymously();
                      } catch (e) {
                        setState(() {
                          _errorMessage = e.toString();
                          _isLoading = false;
                        });
                      }
                    },
                    child: Text('Continue as Guest'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}