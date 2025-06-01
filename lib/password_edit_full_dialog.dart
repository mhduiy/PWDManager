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

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            margin: const EdgeInsets.only(top: 60),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 拖拽指示器
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_rounded : Icons.add_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? '编辑密码' : '添加新密码',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                                Text(
                                  isEdit ? '修改密码信息' : '创建新的密码记录',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 内容区域
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 用途输入框
                            _buildAnimatedInputField(
                              controller: purposeController,
                              label: '描述用途',
                              hint: '请输入密码的用途描述',
                              icon: Icons.label_outline,
                              errorText: errorMessages[purposeController],
                              onChanged: (value) {
                                if (!isEdit && value.isNotEmpty) {
                                  setState(() {
                                    selectedCategory = CategoryManager.suggestCategory(value);
                                  });
                                }
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // 分类选择
                            _buildCategorySelector(context, selectedCategory, (newCategory) {
                              setState(() {
                                selectedCategory = newCategory;
                              });
                            }),
                            
                            const SizedBox(height: 20),
                            
                            // 账户输入框
                            _buildAnimatedInputField(
                              controller: accountController,
                              label: '账户名',
                              hint: '请输入用户名或邮箱',
                              icon: Icons.person_outline,
                              errorText: errorMessages[accountController],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // 密码输入框
                            _buildPasswordInputField(
                              context,
                              passwordController,
                              passwordNotifier,
                              errorMessages[passwordController],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // 备注输入框
                            _buildAnimatedInputField(
                              controller: noteController,
                              label: '备注（可选）',
                              hint: '添加备注信息',
                              icon: Icons.notes_outlined,
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // 保存按钮
                            _buildSaveButton(
                              context,
                              isEdit,
                              purposeController,
                              accountController,
                              passwordController,
                              noteController,
                              selectedCategory,
                              id,
                              errorMessages,
                              setState,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

// 构建动画输入框
Widget _buildAnimatedInputField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  String? errorText,
  int maxLines = 1,
  Function(String)? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ],
  );
}

// 构建分类选择器
Widget _buildCategorySelector(BuildContext context, String selectedCategory, Function(String) onCategorySelected) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '分类',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withOpacity(0.05),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoryManager.getSelectableCategories().map((category) {
            final isSelected = selectedCategory == category.id;
            return GestureDetector(
              onTap: () {
                onCategorySelected(category.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? category.color.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? category.color
                        : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
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
                    const SizedBox(width: 6),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected 
                            ? category.color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

// 构建密码输入框
Widget _buildPasswordInputField(
  BuildContext context,
  TextEditingController passwordController,
  ValueNotifier<String> passwordNotifier,
  String? errorText,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '密码',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: passwordController,
        decoration: InputDecoration(
          hintText: '请输入密码',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.blue),
              onPressed: () {
                _showPasswordGenerator(context, passwordController, passwordNotifier);
              },
              tooltip: '密码生成器',
            ),
          ),
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      const SizedBox(height: 8),
      // 密码强度指示器
      ValueListenableBuilder<String>(
        valueListenable: passwordNotifier,
        builder: (context, password, child) {
          return PasswordStrengthIndicator(password: password);
        },
      ),
    ],
  );
}

// 构建保存按钮
Widget _buildSaveButton(
  BuildContext context,
  bool isEdit,
  TextEditingController purposeController,
  TextEditingController accountController,
  TextEditingController passwordController,
  TextEditingController noteController,
  String selectedCategory,
  int id,
  Map<TextEditingController, String?> errorMessages,
  StateSetter setState,
) {
  return Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
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
          } else {
            // 强制刷新 UI 以显示错误信息
            setState(() {});
          }
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEdit ? Icons.save_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit ? '保存修改' : '添加密码',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
