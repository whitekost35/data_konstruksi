import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/auth_provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';

  void _handleLogin() async {
    if (_pinController.text.length != 6) {
      setState(() => _errorMessage = 'PIN harus 6 digit');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(_pinController.text);

    if (success) {
      if (mounted) {
        context.read<ProjectProvider>().refreshData(profileId: auth.role);
      }
    } else {
      setState(() => _errorMessage = 'PIN salah');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.lock_shield_fill, size: 80, color: Color(0xFF007AFF)),
              const SizedBox(height: 24),
              const Text(
                'Data Konstruksi',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
              ),
              const Text(
                'Masukkan 6 digit PIN',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              
              // PIN Input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 20)],
                ),
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 10),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '••••••',
                    hintStyle: TextStyle(color: Colors.black12, letterSpacing: 10),
                    contentPadding: EdgeInsets.symmetric(vertical: 20),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
              ),
              
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
                
              const SizedBox(height: 40),
              
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withValues(alpha: .2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: auth.isLoading ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: auth.isLoading 
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white, 
                                  fontSize: 16
                                )
                              ),
                        ),
                      ),
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
