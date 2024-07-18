import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key, required this.title});
  final String title;

  @override
  State<AuthenticationPage> createState() => AuthenticationPageState();
}

class AuthenticationPageState extends State<AuthenticationPage> {
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
              color: Theme.of(context).colorScheme.primary
            ),
            const SizedBox(height: 30,),
            Text("PWD 管理器已被锁定", style: TextStyle(fontSize: 28, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 30,),
            TextButton(
                onPressed: (){},
                child: const Text(
                  "解锁",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black
                  ),
                ),
            )
          ],
        )

      ),
    );
  }
}