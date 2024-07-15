import 'package:flutter/material.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key, required this.title});
  final String title;

  @override
  State<PasswordPage> createState() => PasswordPageState();
}

class PasswordPageState extends State<PasswordPage> {
  @override
  Widget build(BuildContext context) {
    final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
    final List<int> items = List<int>.generate(100, (int index) => index);
    return Column(
      children: [
        Expanded(child:
          AnimatedList(
            key: _listKey,
            initialItemCount: items.length,
            itemBuilder: (context, index, animation) {
              return _buildItem(context, index, animation);
            },
          )
        )
      ]);
  }
}

Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
  return SizeTransition(
    sizeFactor: animation,
    child: InkWell(
      onTap: (){},
      splashColor: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 8.0), // 添加一个间距
            Container(
              width: 28.0,
              height: 28.0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // 设置圆形的颜色
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8.0), // 添加一个间距
            const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("QQ 密码", style: TextStyle(fontSize: 16)),
                  Text("2940441575", style: TextStyle(fontSize: 12, color: Color(0xFF008C8C)))
                ]),
            const Spacer(), // 使用 Spacer 来推挤
            TextButton(onPressed: (){}, child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.copy, // 使用复制图标
                  size: 16.0, // 设置图标大小
                ),
                SizedBox(width: 8.0), // 添加一个间距
                Text("账号")
              ],
            )),
            const SizedBox(width: 0.0), // 添加一个间距
            TextButton(onPressed: (){}, child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.copy, // 使用复制图标
                  size: 16.0, // 设置图标大小
                ),
                SizedBox(width: 8.0), // 添加一个间距
                Text("密码")
              ],
            )),
            const SizedBox(width: 8.0), // 添加一个间距
            const Icon(Icons.arrow_forward_ios, size: 16.0), // 向右箭头图标
            const SizedBox(width: 8.0), // 添加一个间距
          ],
        ),
      ),
    ),
  );
}