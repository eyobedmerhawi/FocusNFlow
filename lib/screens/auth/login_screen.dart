
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        await _authService.signUpWithEmail(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _authService.friendlyError(error);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
    } on GoogleSignInException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage =
              error.code == GoogleSignInExceptionCode.canceled
                  ? 'Google Sign-In was canceled.'
                  : 'Google Sign-In failed. Please try again.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _authService.friendlyError(error);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to sign in with Google. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FocusNFlow')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 72,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin
                        ? 'Welcome Back!'
                        : 'Create Your Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your campus study organizer',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty ||
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                        return 'Enter a valid email address.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    autofillHints: [
                      _isLogin
                          ? AutofillHints.password
                          : AutofillHints.newPassword,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password.';
                      }

                      if (!_isLogin && value.length < 6) {
                        return 'Use at least 6 characters.';
                      }

                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _isLoading
                            ? 'Please wait...'
                            : _isLogin
                                ? 'Log In'
                                : 'Create Account',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                              _passwordController.clear();
                            });
                          },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : 'Already have an account? Log In',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
