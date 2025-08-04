import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:zeye/conpoments/connect_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 确保在平台线程上初始化
  MediaKit.ensureInitialized(); // 初始化 MediaKit
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy ONVIF Demo',
      theme: ThemeData(primarySwatch: Colors.grey),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy ONVIF Demo')),
      body: const Center(child: Text('点击右下角按钮添加摄像头')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (context) => OnvifHomePage());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
