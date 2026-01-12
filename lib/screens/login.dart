import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';
// import 'package:nileassist/screens/admin.dart';
import 'package:nileassist/screens/mainLayout.dart';
// import 'package:nileassist/screens/staffDashboard.dart';
// import 'package:nileassist/screens/facilitymanager.dart';
// import 'package:nileassist/screens/lecturer.dart';
// import 'package:nileassist/screens/maintenance.dart';
import 'package:nileassist/screens/uploadprofilePicture.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color nileBlue = Color(0xFF1E3DD3);
  static const Color nileGreen = Color(0xFF8BC34A);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isLogin = true; 
  bool isLoading = false; 
  final AuthService _authService = AuthService();
  

  // inside login.dart

void _navigateBasedOnRole(Map<String, dynamic> userData) {
  String role = userData['role'];
  String uid = userData['uid'];
  String? profilePic = userData['profilePicture'];

  if (role == 'maintenance' && (profilePic == null || profilePic.isEmpty)) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UploadProfileScreen(userId: uid)),
    );
    return;
  }

  //other users navigate to mainlayout
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MainLayout(userData: userData),
    ),
  );
}

  // void _navigateBasedOnRole(Map<String, dynamic> userData) {
  //   String role = userData['role'];
  //   String uid = userData['uid'];
    
  //   // Check if the 'profilePicture' field exists and is not empty
  //   String? profilePic = userData['profilePicture']; 

  //   if (role == 'admin') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
  //   } 
  //   else if (role == 'lecturer') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(fullName: userData['fullName'] ?? 'User')));
  //   } 
  //   else if (role == 'facility_manager') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FMDashboard()));
  //   } 
  //   else if (role == 'hostel_supervisor') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(fullName: userData['fullName'] ?? 'User')));
  //   } 
  //   else if (role == 'maintenance') {
  //     // === NEW SECURITY CHECK ===
  //     // If they are maintenance staff but have NO picture, force them to upload one.
  //     if (profilePic == null || profilePic.isEmpty) {
  //       print("Maintenance user missing photo. Redirecting to upload...");
  //       Navigator.pushReplacement(
  //         context, 
  //         MaterialPageRoute(builder: (context) => UploadProfileScreen(userId: uid))
  //       );
  //     } else {
  //       // They have a picture, let them in.
  //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaintenanceDashboard()));
  //     }
  //   } 
  //   else {
  //     // Fallback
  //     // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
  //   }
  // }

  // void _navigateBasedOnRole(String role) {
  //   if (role == 'admin') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
  //   } 
  //   else if (role == 'lecturer') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LecturerDashboard()));
  //   } 
  //   else if (role == 'facility_manager') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FMDashboard()));
  //   } 
  //   else if (role == 'hostel_supervisor') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HSDashboard()));
  //   } 
  //   else if (role == 'maintenance') {
  //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaintenanceDashboard()));
  //   } 
  //   else {
  //     // Fallback
  //     // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
  //   }
  // }

  Future<void> _handleSubmit() async {
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
        // _navigateBasedOnRole(userData['role']);
        _navigateBasedOnRole(userData);

      } else {
       

        await _authService.registerUser(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Verify your Email"),
            content: Text(
              "A verification link has been sent to ${_emailController.text}.\n\nPlease check your inbox or spam to verify your email before logging in."
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  setState(() {
                    isLogin = true; // Switch back to login mode automatically
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                  });
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Clean up the error message (remove "Exception: " prefix)
      String message = e.toString().replaceAll('Exception: ', '');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
                      const Icon(Icons.school, size: 90, color: nileBlue),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                isLogin ? 'Log in to your Account' : 'Create an Account',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nileBlue),
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
                keyboardType: TextInputType.visiblePassword,
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
                  keyboardType: TextInputType.visiblePassword,
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
                    backgroundColor: nileGreen,
                    disabledBackgroundColor: nileGreen.withOpacity(0.6),
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
                      style: const TextStyle(color: nileBlue),
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