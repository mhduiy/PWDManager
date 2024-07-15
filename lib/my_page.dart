import 'package:flutter/material.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.title});
  final String title;

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AvatarWidget(),
          SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
              child: Card(
                elevation: 2.0,
                child: SettingsList()
              ),
            )
          ),
        ],
      ),
    );
  }
}


class AvatarWidget extends StatelessWidget {
  const AvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80.0,
          height: 80.0,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary, // 设置圆形的颜色
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text("MY", style: TextStyle(fontSize: 25, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8.0), // 添加一个间距
        const Text("艾洋mhduiy"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: (){},
                style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.all(0)),),
                child: const Text("编辑资料", style: TextStyle(fontSize: 12))
            ),
            const SizedBox(width: 8.0), // 添加一个间距
            OutlinedButton(onPressed: (){},
                style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.all(0)),),
                child: const Text("退出登录", style: TextStyle(fontSize: 12))
            ),
          ],
        )
      ],
    );
  }
}


class SettingsList extends StatefulWidget {
  const SettingsList({Key? key}) : super(key: key);

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settings = [
      {
        "title": "深色模式",
        "description": "程序配色使用深色模式配色",
        "switch": true,
        "value": false,
      },
      {
        "title": "启用云同步",
        "description": "开启后自动进行云同步，需要事先登录账号",
        "switch": true,
        "value": false,
      },
      {
        "title": "使用指纹认证",
        "description": "使用设备指纹进行认证，安全性会低于密码认证",
        "switch": true,
        "value": false,
      },
      {
        "title": "使用人脸认证",
        "description": "使用设备人脸进行认证，安全性会低于密码认证",
        "switch": true,
        "value": false,
      },
      {
        "title": "立即锁定",
        "description": "当程序不再前台时立即锁定，需要再次认证",
        "switch": true,
        "value": false,
      },
      {
        "title": "禁止截图",
        "description": "程序主界面禁止被截图或录屏",
        "switch": true,
        "value": false,
      },
      {
        "title": "销毁所有数据",
        "description": "立即销毁设备本地以及网络上存储的所有密码数据",
        "switch": true,
        "value": false,
      },
      {
        "title": "测试项",
        "description": "测试测试测试",
        "switch": true,
        "value": false,
      },
      {
        "title": "测试项",
        "description": "测试测试测试",
        "switch": true,
        "value": false,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: settings.length,
      itemBuilder: (context, index) {
        return SettingItem(
          title: settings[index]['title'],
          description: settings[index]['description'],
          // switchValue: settings[index]['value'],
          onChanged: (value) {
            setState(() {
              settings[index]['value'] = value;
              if (settings[index]['title'] == "深色模式") {
                if (value) {
                  // MyApp.of(context)!.setDarkMode();
                } else {
                  // MyApp.of(context)!.setLightMode();
                }
              }
            });
          },
        );
      },
    );
  }
}

class SettingItem extends StatefulWidget {
  final String title;
  final String description;
  final ValueChanged<bool> onChanged;

  SettingItem({
    super.key,
    required this.title,
    required this.description,
    // required this.switchValue,
    required this.onChanged,
  });

  @override
  _SettingItemState createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem> {
  bool switchValue = true;
  void changeSwitchState(bool status) {
    setState(() {
      switchValue = !switchValue;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
      child: ListTile(
          title: Text(widget.title),
          subtitle: Text(
            widget.description,
            style: TextStyle(color: Colors.black.withAlpha(100)),
          ),
          trailing: Switch(
            value: switchValue,
            onChanged: changeSwitchState,
          ),
        ),
    );
  }
}