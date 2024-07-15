import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'password_page.dart';
import 'my_page.dart';

// 应用程序入口
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PWD 管理器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainFrame(title: 'PWD 管理器'),
    );
  }
}

class MainFrame extends StatefulWidget {
  const MainFrame({super.key, required this.title});
  final String title;

  @override
  State<MainFrame> createState() => MainFrameState();
}

// MyHomePage 对应的状态类
class MainFrameState extends State<MainFrame> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    PasswordPage(title: "密码"),
    MyPage(title: "我的")
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 首次启动时会调用这个函数来构建Widget
  @override
  Widget build(BuildContext context) {
    final GlobalKey<AnimatedListState> _listKey =
        GlobalKey<AnimatedListState>();
    final List<int> items = List<int>.generate(100, (int index) => index);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return MyPage(title: "我的");
              }));
            },
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
      drawer: const Drawer(
          child: Center(
        child: Text("无事发生"),
      )),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.delete),
            label: '删除记录',
            onTap: () => print('First tapped'),
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            label: '添加记录',
            onTap: () => _showFullScreenDialog(context),
          )
        ],
      ),
    );
  }

  void _showFullScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.white,
          child: Scaffold(
              appBar: AppBar(
                title: Text("添加新项目"),
                actions: [
                  TextButton(onPressed: () {}, child: Text("保存")),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
              body: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: '描述用途', // 可选的标签文字
                        border: OutlineInputBorder(), // 添加边框
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: '账户名', // 可选的标签文字
                        border: OutlineInputBorder(), // 添加边框
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: '密码', // 可选的标签文字
                        border: OutlineInputBorder(), // 添加边框
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: '备注', // 可选的标签文字
                        border: OutlineInputBorder(), // 添加边框
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Card(
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
}
