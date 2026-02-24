import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/forgot_password.dart';
import 'package:nileassist/screens/mainLayout.dart';
import 'package:nileassist/screens/uploadprofilePicture.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  // Dropdown Selections
  String _selectedRole = 'lecturer';
  String? _selectedDepartment;

  bool _roleRequiresAccessCode(String role) {
    return role == 'admin' ||
        role == 'facility_manager' ||
        role == 'maintenance_supervisor';
  }

  bool _roleRequiresDepartment(String role) {
    return role == 'maintenance_supervisor' || role == 'maintenance_staff';
  }

  void _navigateBasedOnRole(Map<String, dynamic> userData) {
    String role = userData['role'];
    String uid = userData['uid'];

    // checks if maintenance staff needs profile picture
    if ((role == 'maintenance_staff' || role == 'maintenance_supervisor') &&
        (userData['profilePicture'] == null ||
            userData['profilePicture'].isEmpty)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UploadProfileScreen(userId: uid),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainLayout(userData: userData)),
    );
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Registration checks
    if (!isLogin) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Full name is required')));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
      // Department Check
      if (_roleRequiresDepartment(_selectedRole) &&
          _selectedDepartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your Department/Unit')),
        );
        return;
      }
      // Access Code Check
      if (_roleRequiresAccessCode(_selectedRole) &&
          _accessCodeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Code is required for this role'),
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        final userData = await _authService.loginUser(
          identifier: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        _navigateBasedOnRole(userData);
      } else {
        // Register user
        await _authService.registerUser(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          department: _selectedDepartment,
          accessCode: _accessCodeController.text.trim(),
        );

        if (!mounted) return;
        // User is now logged in, pop back to let StreamBuilder handle navigation
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // change firebase technical error to clear error message
      String errorMessage = 'Authentication failed. Please try again.';

      switch (e.code) {
        case 'invalid-email':
        case 'invalid-credential':
          errorMessage = 'Invalid Email, Staff ID, or Password.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled. Contact support.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          // Fallback if it's an error we didn't explicitly catch
          errorMessage = e.message ?? 'An unknown error occurred.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      // This catches your custom errors (like "Staff ID not found")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/logo-removebg-preview.png',
                  height: 150,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.school, size: 90, color: MyApp.nileBlue),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                isLogin ? 'Log in to your Account' : 'Create an Account',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MyApp.nileBlue,
                ),
              ),
              const SizedBox(height: 30),

              Text(isLogin ? 'Email' : 'Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: isLogin
                      ? 'Enter your email or staff ID'
                      : 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Registration Only Fields
              if (!isLogin) ...[
                const Text('Full Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Select Role'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'lecturer',
                      child: Text('Lecturer'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('System Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'facility_manager',
                      child: Text('Facility Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'hostel_supervisor',
                      child: Text('Hostel Supervisor'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance_supervisor',
                      child: Text('Maintenance Supervisor'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance_staff',
                      child: Text('Maintenance Staff'),
                    ),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedRole = val!;
                    _selectedDepartment = null;
                  }),
                ),
                const SizedBox(height: 20),

                // Department Dropdown
                if (_roleRequiresDepartment(_selectedRole)) ...[
                  const Text('Select Department / Unit'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.build_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'HVAC',
                        child: Text('HVAC (AC / Cooling)'),
                      ),
                      DropdownMenuItem(
                        value: 'Electrical',
                        child: Text('Electrical Unit'),
                      ),
                      DropdownMenuItem(
                        value: 'Plumbing',
                        child: Text('Plumbing Unit'),
                      ),
                      DropdownMenuItem(
                        value: 'Civil',
                        child: Text('Civil / Carpentry'),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedDepartment = val),
                  ),
                  const SizedBox(height: 20),
                ],

                // Access Code Field
                if (_roleRequiresAccessCode(_selectedRole)) ...[
                  const Text('Access Code (Required)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accessCodeController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter Authorized Code',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              // Password
              const Text('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (!isLogin) ...[
                const Text('Re-enter password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 10),

              //sign up / login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.nileGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : _handleSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLogin ? 'Log in' : 'Sign up',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin
                        ? "Don't have an account?"
                        : "Already have an account?",
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() {
                            isLogin = !isLogin;
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          }),
                    child: Text(
                      isLogin ? 'Create one' : 'Log in',
                      style: const TextStyle(color: MyApp.nileBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (isLogin) ...[
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text(
                    'Forgot your password?',
                    style: TextStyle(color: MyApp.nileBlue),
                  ),
                ),
              ),]
            ],
          ),
        ),
      ),
    );
  }
}
