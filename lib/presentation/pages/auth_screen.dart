import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_event.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:rentapp/presentation/pages/car_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Login controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Signup controllers
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();
  final TextEditingController _signupConfirmPasswordController =
      TextEditingController();

  // Theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  // Form keys for validation
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Check for existing user on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForExistingUser();
    });
  }

  // Check if the user is already logged in
  void _checkForExistingUser() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // User is already logged in, dispatch event to AuthBloc
      context.read<AuthBloc>().add(CheckAuthStatus());
    }
  }

  // Handle login with email/password
  void _loginWithEmailPassword() {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Dispatch login event
    context.read<AuthBloc>().add(
          LoginWithEmailPassword(
            email: _loginEmailController.text.trim(),
            password: _loginPasswordController.text.trim(),
          ),
        );
  }

  // Handle signup with email/password
  void _signupWithEmailPassword() {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_signupFormKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Dispatch signup event
    context.read<AuthBloc>().add(
          SignupWithEmailPassword(
            email: _signupEmailController.text.trim(),
            password: _signupPasswordController.text.trim(),
            name: _signupNameController.text.trim(),
          ),
        );
  }

  // Continue as guest
  void _continueAsGuest() {
    setState(() {
      _isLoading = true;
    });

    context.read<AuthBloc>().add(LoginAsGuest());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        } else {
          setState(() {
            _isLoading = false;
          });

          if (state is Authenticated || state is GuestMode) {
            // Navigate to car list screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const CarListScreen(),
              ),
            );
          } else if (state is AuthError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Logo and header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    child: Column(
                      children: [
                        // App title instead of logo
                        const Text(
                          'Rent App',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Premium Car Rentals',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign in to access exclusive deals and manage your bookings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: primaryGold,
                    unselectedLabelColor: mediumGrey,
                    indicatorColor: primaryGold,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginTab(),
                        _buildSignupTab(),
                      ],
                    ),
                  ),

                  // Guest mode button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 15),
                        const Text(
                          'Don\'t want to create an account?',
                          style: TextStyle(
                            color: mediumGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    context
                                        .read<AuthBloc>()
                                        .add(LoginAsGuest());
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: primaryGold),
                            ),
                            child: const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryGold),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Authenticating...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Email field
              const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.email, color: primaryGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGold, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password field
              const Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _loginPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.lock, color: primaryGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGold, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement password reset
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset coming soon'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryGold,
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),

              const SizedBox(height: 30),

              // Login button
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(top: 30),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_loginFormKey.currentState!.validate()) {
                            // Form is valid, proceed with login
                            context.read<AuthBloc>().add(
                                  LoginWithEmailPassword(
                                    email: _loginEmailController.text.trim(),
                                    password: _loginPasswordController.text,
                                  ),
                                );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlack,
                    foregroundColor: primaryGold,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Name field
              const Text(
                'Full Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _signupNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.person, color: primaryGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGold, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Email field
              const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.email, color: primaryGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGold, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password field
              const Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _signupPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.lock, color: primaryGold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGold, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Signup button
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(top: 30),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_signupFormKey.currentState!.validate()) {
                            // Form is valid, proceed with signup
                            context.read<AuthBloc>().add(
                                  SignupWithEmailPassword(
                                    email: _signupEmailController.text.trim(),
                                    password: _signupPasswordController.text,
                                    name: _signupNameController.text.trim(),
                                  ),
                                );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlack,
                    foregroundColor: primaryGold,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
