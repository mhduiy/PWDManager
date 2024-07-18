import 'package:flutter/material.dart';

void showEditPasswordFullDialog(BuildContext context) {
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