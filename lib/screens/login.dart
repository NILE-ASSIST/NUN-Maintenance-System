import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';
import 'package:nileassist/screens/admin.dart';
import 'package:nileassist/screens/facilitymanager.dart';
import 'package:nileassist/screens/hostelSupervisor.dart';
import 'package:nileassist/screens/lecturer.dart';
import 'package:nileassist/screens/maintenance.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryBlue = const Color(0xFF1E3DD3);
  final Color greenButton = const Color(0xFF8BC34A);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isLogin = true; 
  bool isLoading = false; 
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateBasedOnRole(String role) {
    // Navigate to the correct dashboard based on the role string
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
      print("Navigating to Admin Dashboard");
    } 
    else if (role == 'lecturer') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LecturerDashboard()));
      print("Navigating to Lecturer Dashboard");
    } 
    else if (role == 'facility_manager') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FMDashboard()));
      print("Navigating to Facility Manager Dashboard");
    } 
    else if (role == 'hostel_supervisor') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HSDashboard()));
      print("Navigating to Hostel Supervisor Dashboard");
    } 
    else if (role == 'maintenance') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaintenanceDashboard()));
      print("Navigating to Maintenance Dashboard");
    } 
    else {
      // Fallback for unknown roles (or students if they don't have a specific regex)
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
      print("Navigating to Student/Default Dashboard");
    }
  }

  // --- MAIN AUTH LOGIC ---
  Future<void> _handleSubmit() async {
    //Input Validation
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!isLogin) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Full name is required')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        final userData = await _authService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        _navigateBasedOnRole(userData['role']);

      } else {
        
        //Create the user in Firebase
        await _authService.registerUser(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Detect the role locally so we know where to send them immediately
        String role = _authService.detectUserRole(_emailController.text.trim());

        if (!mounted) return;
        
        //Navigate directly to dashboard instead of asking to login
        _navigateBasedOnRole(role);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  //hekko

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
                  height: 90,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.school, size: 90, color: Colors.blue),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                isLogin ? 'Log in to your Account' : 'Create an Account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue),
              ),

              const SizedBox(height: 30),

              const Text('Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 20),

              // Full Name field only for Signup
              if (!isLogin) ...[
                const Text('Full Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Password only for Signup
              if (!isLogin) ...[
                const Text('Re-enter password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenButton,
                    disabledBackgroundColor: greenButton.withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isLoading ? null : _handleSubmit,
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isLogin ? 'Log in' : 'Sign up',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLogin ? "Don't have an account?" : "Already have an account?"),
                  TextButton(
                    onPressed: isLoading ? null : () {
                      setState(() {
                        isLogin = !isLogin;
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text(
                      isLogin ? 'Create one' : 'Log in',
                      style: TextStyle(color: primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}