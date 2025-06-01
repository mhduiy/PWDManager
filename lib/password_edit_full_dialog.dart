import 'package:flutter/material.dart';
import 'password.dart';
import 'databasehelper.dart';
import 'utils/password_strength.dart';
import 'password_generator.dart';

// 添加显示密码生成器的函数
void _showPasswordGenerator(BuildContext context, TextEditingController passwordController, ValueNotifier<String> passwordNotifier) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: PasswordGenerator(
        onPasswordGenerated: (generatedPassword) {
          passwordController.text = generatedPassword;
          passwordNotifier.value = generatedPassword;
        },
      ),
    ),
  );
}

Future<void> _insertPassword(BuildContext context, String purpose, String account, String password, String note) async {
  Password newPassword = Password(purpose: purpose, account: account, password: password, note: note);
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.insertPassword(newPassword.toMap());
  Navigator.of(context).pop(); // 关闭对话框
}

Future<void> _editPassword(BuildContext context, String purpose, String account, String password, String note, int id) async {
  Password newPassword = Password(purpose: purpose, account: account, password: password, note: note);
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.updatePassword(id, newPassword.toMap());
  Navigator.of(context).pop(); // 关闭对话框
}

void showEditPasswordFullDialog(BuildContext context, {bool isEdit = false, int id = -1}) {
  TextEditingController purposeController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  // 用于监听密码变化
  ValueNotifier<String> passwordNotifier = ValueNotifier<String>('');
  passwordController.addListener(() {
    passwordNotifier.value = passwordController.text;
  });

  Password password = Password(purpose: "", account: "", password: "", note: "");

  if (isEdit) {
    if (id < 0) return;
     DatabaseHelper().getPasswordById(id).then((passwordData) {
      if (passwordData != null) {
        password = Password.fromMap(passwordData);
        purposeController.text = password.purpose;
        accountController.text = password.account;
        passwordController.text = password.password;
        noteController.text = password.note;
        passwordNotifier.value = password.password;
      }
    });
  }

  // 用于存储每个编辑框的错误信息
  Map<TextEditingController, String?> errorMessages = {
    purposeController: null,
    accountController: null,
    passwordController: null,
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16.0),
      ),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 自定义导航条
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16.0),
                    ),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: AppBar(
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(isEdit ? '编辑密码' : '添加新密码'),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          // 校验每个编辑框的内容
                          bool isValid = true;
                          errorMessages.forEach((controller, error) {
                            if (controller.text.isEmpty) {
                              errorMessages[controller] = '此项不能为空';
                              isValid = false;
                            } else {
                              errorMessages[controller] = null;
                            }
                          });

                          if (isValid) {
                            String purpose = purposeController.text;
                            String account = accountController.text;
                            String password = passwordController.text;
                            String note = noteController.text;
                            if (isEdit) {
                              _editPassword(context, purpose, account, password, note, id);
                            } else {
                              _insertPassword(context, purpose, account, password, note);
                            }
                          
                            // 强制刷新 UI 以显示错误信息
                            setState(() {});
                          }
                        },
                      ),
                    ],
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
                // 内容区域
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: purposeController,
                            decoration: InputDecoration(
                              labelText: '描述用途',
                              border: const OutlineInputBorder(),
                              errorText: errorMessages[purposeController],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: accountController,
                            decoration: InputDecoration(
                              labelText: '账户名',
                              border: const OutlineInputBorder(),
                              errorText: errorMessages[accountController],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: '密码',
                              border: const OutlineInputBorder(),
                              errorText: errorMessages[passwordController],
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.generating_tokens),
                                onPressed: () {
                                  _showPasswordGenerator(context, passwordController, passwordNotifier);
                                },
                                tooltip: '密码生成器',
                              ),
                            ),
                          ),
                          // 添加密码强度指示器
                          ValueListenableBuilder<String>(
                            valueListenable: passwordNotifier,
                            builder: (context, password, child) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: PasswordStrengthIndicator(
                                  password: password,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              labelText: '备注',
                              border: const OutlineInputBorder(),
                              errorText: errorMessages[noteController],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
