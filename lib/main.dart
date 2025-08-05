import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:get/get.dart'; // 导入GetX
import 'package:hive_flutter/hive_flutter.dart'; // 导入Hive Flutter
import 'package:zeye/conpoments/connect_dialog.dart';
import 'package:zeye/controllers/camera_controller.dart'; // 导入摄像头控制器
import 'package:zeye/models/camera_model.dart'; // 导入摄像头模型
import 'package:zeye/page/rtsp_page.dart'; // 导入RTSP页面

Future<void> main() async {
  // 将main函数标记为async
  WidgetsFlutterBinding.ensureInitialized(); // 确保在平台线程上初始化
  MediaKit.ensureInitialized(); // 初始化 MediaKit

  // 初始化Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CameraAdapter()); // 注册Camera适配器
  await Hive.openBox<Camera>('cameras'); // 打开名为'cameras'的Box

  Get.put(CameraController()); // 注册摄像头控制器
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // 使用GetMaterialApp
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
    final CameraController cameraController = Get.find(); // 获取摄像头控制器

    return Scaffold(
      appBar: AppBar(title: const Text('Easy ONVIF Demo')),
      body: Obx(
        () => cameraController.cameras.isEmpty
            ? const Center(child: Text('点击右下角按钮添加摄像头'))
            : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 每行显示2个卡片
                  crossAxisSpacing: 8.0, // 水平间距
                  mainAxisSpacing: 8.0, // 垂直间距
                  childAspectRatio: 1.5, // 卡片宽高比
                ),
                itemCount: cameraController.cameras.length,
                itemBuilder: (context, index) {
                  final camera = cameraController.cameras[index];
                  return CameraCard(camera: camera);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.dialog(OnvifHomePage()); // 使用Get.dialog显示对话框
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 摄像头卡片组件
class CameraCard extends StatelessWidget {
  final Camera camera;

  const CameraCard({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: () {
          // 点击卡片导航到RTSP页面，并传递摄像头信息
          Get.to(() => RtspPage(camera: camera));
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                camera.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                'IP: ${camera.ipAddress}',
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
              const SizedBox(height: 4.0),
              Text(
                '端口: ${camera.port}',
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.bottomRight,
                child: Chip(
                  label: Text(camera.isConnected ? '已连接' : '未连接'),
                  backgroundColor: camera.isConnected
                      ? Colors.green[100]
                      : Colors.red[100],
                  labelStyle: TextStyle(
                    color: camera.isConnected
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
