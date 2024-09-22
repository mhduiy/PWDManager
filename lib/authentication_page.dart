import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'main.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key, required this.title});
  final String title;

  @override
  State<AuthenticationPage> createState() => AuthenticationPageState();
}

class AuthenticationPageState extends State<AuthenticationPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on Exception {
      canCheckBiometrics = false;
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: '阔以弄指纹验证仨',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on Exception catch (e) {
      return;
    }
    if (!mounted) {
      return;
    }

    if (authenticated) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return const MainFrame(title: 'PWD 管理器');
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline, // 使用复制图标
              size: 100.0, // 设置图标大小
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 30),
            Text(
              "PWD 管理器已被锁定",
              style: TextStyle(
                fontSize: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: _canCheckBiometrics ? _authenticateWithBiometrics : null,
              child: const Text(
                "解锁",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}