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

  // 显示重命名对话框
  void _showRenameDialog(BuildContext context, CameraController controller) {
    final TextEditingController nameController = TextEditingController(
      text: camera.name,
    );
    Get.dialog(
      AlertDialog(
        title: const Text('重命名摄像头'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '新名称'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedCamera = camera.copyWith(
                  name: nameController.text,
                );
                controller.updateCamera(updatedCamera);
                Get.back();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(
    BuildContext context,
    CameraController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('删除摄像头'),
        content: Text('确定要删除摄像头 "${camera.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              controller.removeCamera(camera);
              Get.back();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CameraController cameraController = Get.find(); // 获取摄像头控制器

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: GestureDetector(
        onLongPress: () =>
            _showRenameDialog(context, cameraController), // 长按重命名
        child: InkWell(
          onTap: () {
            // 点击卡片导航到RTSP页面，并传递摄像头信息
            Get.to(() => RtspPage(camera: camera));
          },
          child: Stack(
            children: [
              Padding(
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
                    // 显示快照
                    if (camera.isOnline && camera.snapshotUrl != null)
                      Expanded(
                        child: Center(
                          child: Image.network(
                            camera.snapshotUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 50);
                            },
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Icon(
                            camera.isOnline
                                ? Icons.videocam
                                : Icons.videocam_off,
                            size: 50,
                            color: camera.isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4.0),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Chip(
                        label: Text(camera.isOnline ? '在线' : '离线'),
                        backgroundColor: camera.isOnline
                            ? Colors.green[100]
                            : Colors.red[100],
                        labelStyle: TextStyle(
                          color: camera.isOnline
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 删除按钮
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _showDeleteConfirmDialog(context, cameraController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
