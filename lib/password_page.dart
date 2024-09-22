import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pwd_manager_flutter/password_edit_full_dialog.dart';
import 'password.dart';
import 'databasehelper.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key, required this.title});
  final String title;

  @override
  State<PasswordPage> createState() => PasswordPageState();
}

class PasswordPageState extends State<PasswordPage> {
  List<Password> passwords = [];

  @override
  void initState() {
    super.initState();
    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.addListener((){
      print("重新加载");
      _loadPasswords();
    });
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> passwordMaps = await dbHelper.getPasswords();
    setState(() {
      passwords = passwordMaps.map((map) => Password.fromMap(map)).toList();
    });
  }

  Future<void> _insertPassword(Password password) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.insertPassword(password.toMap());
    await _loadPasswords();
  }

  Future<void> _deletePassword(int index) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.deletePassword(passwords[index].id!);
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
    return Column(
        children: [
          Expanded(
              child:
              AnimatedList(
                key: _listKey,
                initialItemCount: passwords.length,
                itemBuilder: (context, index, animation) {
                  return _buildItem(context, index, animation, passwords[index]);
                },
              )
          )
        ]);
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation, Password password) {
    return SizeTransition(
      sizeFactor: animation,
      child: InkWell(
        onTap: (){
          showEditPasswordFullDialog(context);
        },
        onLongPress: () {
          _showDeleteConfirmationDialog(context, index);
        },
        splashColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 8.0),
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(password.purpose, style: const TextStyle(fontSize: 16)),
                    Text(password.account, style: const TextStyle(fontSize: 12, color: Color(0xFF008C8C)))
                  ]),
              const Spacer(), // 使用 Spacer 来推挤
              TextButton(onPressed: () {
                _copyToClipboard(password.account);
              }, child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.copy,
                    size: 16.0,
                  ),
                  SizedBox(width: 8.0),
                  Text("账号")
                ],
              )),
              const SizedBox(width: 0.0), // 添加一个间距
              TextButton(onPressed: () {
                _copyToClipboard(password.password);
              }, child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.copy,
                    size: 16.0,
                  ),
                  SizedBox(width: 8.0),
                  Text("密码")
                ],
              )),
              const SizedBox(width: 8.0),
              const Icon(Icons.arrow_forward_ios, size: 16.0),
              const SizedBox(width: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条数据吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('删除'),
              onPressed: () {
                _deletePassword(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
}
