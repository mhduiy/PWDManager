import 'package:flutter/material.dart';

class PasswordItemAddPage extends StatefulWidget {
  const PasswordItemAddPage({super.key, required this.title});
  final String title;

  @override
  State<PasswordItemAddPage> createState() => MyPageState();
}

class MyPageState extends State<PasswordItemAddPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

        ],
      ),
    );
  }
}