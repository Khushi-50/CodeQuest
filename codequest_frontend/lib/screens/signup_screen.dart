import 'package:flutter/material.dart';
import 'package:hackmol7/providers/quest_provider.dart';
import 'package:hackmol7/screens/language_selection_screen.dart';
import 'package:hackmol7/services/auth_service.dart';
import 'package:hackmol7/widgets/cyber_button.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Join the Quest',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.primary,
                  shadows: [
                    Shadow(color: AppColors.primaryGlow, blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to start your logic journey.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Social Auth (Google) - Still a UI requirement
              _buildGoogleButton(),

              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 32),

              // Custom Node.js Auth Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              // SizedBox(
              //   width: double.infinity,
              //   height: 56,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       if (_formKey.currentState!.validate()) {
              //         // TODO: Call your Node.js API Service here
              //         // Example: AuthService().register(_usernameController.text, ...)
              //         print("Sign up request sent to Node.js Backend");
              //       }
              //     },
              //     child: const Text('CREATE ACCOUNT'),
              //   ),
              // ),
              CyberButton(
                label: "CREATE ACCOUNT",
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  // 1. Show Loading Dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );

                  try {
                    bool success = await AuthService().register(
                      _usernameController.text.trim(),
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );

                    // 2. ONLY pop if the widget is still in the tree
                    if (!mounted) return;
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop(); // Specifically closes the dialog

                    if (success) {
                      await Provider.of<QuestProvider>(
                        context,
                        listen: false,
                      ).loadUserData();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionScreen(),
                        ),
                      );
                    } else {
                      // Handle logic error (e.g. Email taken)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Signup failed. Email might be in use.",
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // 3. Safety Check: If the dialog is still open, close it
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Connection error. Is the server on 5050?",
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              // CyberButton(
              //   label: "CREATE ACCOUNT",
              //   onPressed: () async {
              //     // 1. Basic Validation check
              //     if (!_formKey.currentState!.validate()) return;

              //     // 2. Show a loading indicator (Crucial so user doesn't double-tap)
              //     showDialog(
              //       context: context,
              //       barrierDismissible: false,
              //       builder: (context) => const Center(
              //         child: CircularProgressIndicator(
              //           color: AppColors.primary,
              //         ),
              //       ),
              //     );

              //     try {
              //       bool success = await AuthService().register(
              //         _usernameController.text.trim(),
              //         _emailController.text.trim(),
              //         _passwordController.text.trim(),
              //       );

              //       // Remove the loading dialog
              //       Navigator.pop(context);

              //       if (success) {
              //         // 3. Refresh Provider with the new Token/User
              //         await Provider.of<QuestProvider>(
              //           context,
              //           listen: false,
              //         ).loadUserData();

              //         // 4. Navigate to LANGUAGE SELECTION (New users need to pick a course!)
              //         Navigator.pushReplacement(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => const LanguageSelectionScreen(),
              //           ),
              //         );
              //       } else {
              //         print(
              //           "Registration Failed. Email might already be taken.",
              //         );
              //       }
              //     } catch (e) {
              //       Navigator.pop(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => const LanguageSelectionScreen(),
              //         ),
              //       );
              //       print("Connection Error: Is the server running on 5000?");
              //     }
              //   },
              // ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: () {}, // Handled by Node.js Passport/OAuth logic
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: AppColors.surfaceLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.g_mobiledata, size: 30, color: AppColors.primary),
          SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.surfaceLight)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: AppColors.surfaceLight)),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
