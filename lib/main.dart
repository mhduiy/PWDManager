import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'password_page.dart';
import 'my_page.dart';
import 'password_edit_full_dialog.dart';
import 'authentication_page.dart';

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
      home: const AuthenticationPage(title: "锁定")
      // home: const AuthenticationPage(title: ""),
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
class MainFrameState extends State<MainFrame> with WidgetsBindingObserver  {
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
        title: Text(widget.title, style: TextStyle(fontSize: 18),),
        centerTitle: true,
        actions: [
          IconButton(
      // search_outlined
            icon: const Icon(Icons.lock, size: 22,),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                return AuthenticationPage(title: "锁定");
              }));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 22,),
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
            child: Icon(Icons.add),
            label: '添加记录',
            onTap: () => showEditPasswordFullDialog(context),
          )
        ],
      ),
    );
  }
}
