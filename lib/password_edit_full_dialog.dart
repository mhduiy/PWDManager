import 'package:flutter/material.dart';
import 'password.dart';
import 'databasehelper.dart';

Future<void> _insertPassword(BuildContext context, String purpose, String account, String password, String note) async {
  if (purpose.isEmpty || account.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('用途、账户名和密码不能为空')),
    );
    return;
  }

  print("添加一个数据到数据库中");
  Password newPassword = Password(purpose: purpose, account: account, password: password, note: note);
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.insertPassword(newPassword.toMap());
  Navigator.of(context).pop(); // 关闭对话框
}

void showEditPasswordFullDialog(BuildContext context) {
  TextEditingController purposeController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("添加新项目"),
              actions: [
                TextButton(onPressed: () {
                  String purpose = purposeController.text;
                  String account = accountController.text;
                  String password = passwordController.text;
                  String note = noteController.text;

                  _insertPassword(context, purpose, account, password, note);
                }, child: const Text("保存")),
                const SizedBox(
                  width: 10,
                )
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(
                      labelText: '描述用途', // 可选的标签文字
                      border: OutlineInputBorder(), // 添加边框
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: '账户名', // 可选的标签文字
                      border: OutlineInputBorder(), // 添加边框
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: '密码', // 可选的标签文字
                      border: OutlineInputBorder(), // 添加边框
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: '备注', // 可选的标签文字
                      border: OutlineInputBorder(), // 添加边框
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Card(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Chip(label: Text("生活"), backgroundColor: Color.fromARGB(0, 0, 128, 255)),
                            Chip(label: Text("工作"), backgroundColor: Color.fromARGB(0, 0, 128, 255)),
                            Chip(label: Text("网站"), backgroundColor: Color.fromARGB(0, 0, 128, 255)),
                            Chip(label: Text("App"), backgroundColor: Color.fromARGB(0, 0, 128, 255)),
                          ],
                        ),
                      )
                  )
                ],
              ),
            ) // 在所有方向上添加16像素的填充
        ),
      );
    },
  );
}