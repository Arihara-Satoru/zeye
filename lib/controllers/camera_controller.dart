// lib/controllers/camera_controller.dart

// lib/controllers/camera_controller.dart

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 导入Hive Flutter
import '../models/camera_model.dart'; // 导入摄像头模型，包含生成的适配器

/// 摄像头控制器
/// 管理摄像头的添加、删除、更新和持久化存储
class CameraController extends GetxController {
  // 摄像头列表，使用RxList使其可观察
  final RxList<Camera> cameras = <Camera>[].obs;
  // Hive Box实例，用于数据持久化
  late final Box<Camera> _cameraBox; // 声明为late final

  @override
  void onInit() {
    super.onInit();
    _cameraBox = Hive.box<Camera>('cameras'); // 在onInit中获取Box实例
    _loadCameras(); // 加载摄像头数据
  }

  /// 从Hive Box加载保存的摄像头数据
  void _loadCameras() {
    cameras.assignAll(_cameraBox.values.toList()); // 从Box中获取所有摄像头
  }

  /// 添加一个摄像头
  void addCamera(Camera camera) {
    cameras.add(camera);
    _cameraBox.add(camera); // 直接添加到Hive Box
  }

  /// 更新一个摄像头
  void updateCamera(Camera updatedCamera) {
    final int index = cameras.indexWhere(
      (camera) => camera.url == updatedCamera.url,
    );
    if (index != -1) {
      _cameraBox.putAt(index, updatedCamera); // 更新Hive Box中的数据
      cameras[index] = updatedCamera; // 更新RxList
    }
  }

  /// 删除一个摄像头
  void removeCamera(Camera camera) {
    final int index = cameras.indexWhere((c) => c.url == camera.url);
    if (index != -1) {
      _cameraBox.deleteAt(index); // 从Hive Box中删除数据
      cameras.removeAt(index); // 从RxList中删除
    }
  }

  /// 根据URL查找摄像头
  Camera? findCameraByUrl(String url) {
    try {
      return cameras.firstWhere((camera) => camera.url == url);
    } catch (e) {
      return null;
    }
  }
}
