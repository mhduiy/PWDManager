import 'package:flutter/material.dart';
import 'password.dart';
import 'databasehelper.dart';
import 'utils/password_strength.dart';
import 'password_generator.dart';
import 'utils/password_category.dart';

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

Future<void> _insertPassword(BuildContext context, String purpose, String account, String password, String note, String category) async {
  Password newPassword = Password(
    purpose: purpose, 
    account: account, 
    password: password, 
    note: note,
    category: category,
  );
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.insertPassword(newPassword.toMap());
  Navigator.of(context).pop(); // 关闭对话框
}

Future<void> _editPassword(BuildContext context, String purpose, String account, String password, String note, String category, int id) async {
  Password newPassword = Password(
    purpose: purpose, 
    account: account, 
    password: password, 
    note: note,
    category: category,
  );
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.updatePassword(id, newPassword.toMap());
  Navigator.of(context).pop(); // 关闭对话框
}

void showEditPasswordFullDialog(BuildContext context, {bool isEdit = false, int id = -1}) {
  TextEditingController purposeController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  
  // 分类选择
  String selectedCategory = 'other';

  // 用于监听密码变化
  ValueNotifier<String> passwordNotifier = ValueNotifier<String>('');
  passwordController.addListener(() {
    passwordNotifier.value = passwordController.text;
  });
  
  // 用于监听用途变化，智能推荐分类
  purposeController.addListener(() {
    if (!isEdit && purposeController.text.isNotEmpty) {
      selectedCategory = CategoryManager.suggestCategory(purposeController.text);
    }
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
        selectedCategory = password.category;
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
                              _editPassword(context, purpose, account, password, note, selectedCategory, id);
                            } else {
                              _insertPassword(context, purpose, account, password, note, selectedCategory);
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
                            onChanged: (value) {
                              if (!isEdit && value.isNotEmpty) {
                                setState(() {
                                  selectedCategory = CategoryManager.suggestCategory(value);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // 分类选择
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '分类',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: CategoryManager.getSelectableCategories().map((category) {
                                    final isSelected = selectedCategory == category.id;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedCategory = category.id;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? category.color.withOpacity(0.2)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected 
                                                ? category.color
                                                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              category.icon,
                                              size: 16,
                                              color: isSelected 
                                                  ? category.color
                                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              category.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected 
                                                    ? category.color
                                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
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
