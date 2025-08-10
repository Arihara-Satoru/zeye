// lib/controllers/camera_controller.dart

import 'dart:async'; // 导入定时器
import 'dart:io'; // 导入dart:io进行网络连接测试
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 导入Hive Flutter
import '../models/camera_model.dart'; // 导入摄像头模型

/// 摄像头控制器
/// 管理摄像头的添加、删除、更新和持久化存储，并处理在线状态检测
class CameraController extends GetxController {
  // 摄像头列表，使用RxList使其可观察
  final RxList<Camera> cameras = <Camera>[].obs;
  // Hive Box实例，用于数据持久化
  late final Box<Camera> _cameraBox; // 声明为late final
  // 定时器列表，用于管理每个摄像头的在线状态检测
  final Map<String, Timer> _onlineCheckTimers = {};

  @override
  void onInit() {
    super.onInit();
    _cameraBox = Hive.box<Camera>('cameras'); // 在onInit中获取Box实例
    _loadCameras(); // 加载摄像头数据
    _startAllOnlineChecks(); // 启动所有摄像头的在线状态检测
  }

  @override
  void onClose() {
    _cancelAllOnlineChecks(); // 关闭时取消所有定时器
    super.onClose();
  }

  /// 从Hive Box加载保存的摄像头数据
  void _loadCameras() {
    cameras.assignAll(_cameraBox.values.toList()); // 从Box中获取所有摄像头
  }

  /// 添加一个摄像头
  void addCamera(Camera camera) {
    cameras.add(camera);
    _cameraBox.add(camera); // 直接添加到Hive Box
    _startOnlineCheck(camera); // 添加后启动在线状态检测
  }

  /// 更新一个摄像头
  /// 使用摄像头的唯一ID来查找并更新
  void updateCamera(Camera updatedCamera) {
    final int index = cameras.indexWhere(
      (camera) => camera.id == updatedCamera.id, // 使用ID查找
    );
    if (index != -1) {
      // 更新Hive Box中的数据
      _cameraBox.putAt(index, updatedCamera);
      // 更新RxList
      cameras[index] = updatedCamera;

      // 如果URL改变，需要更新在线状态检测的定时器键（如果定时器是基于URL的）
      // 但现在定时器是基于ID的，所以URL改变不影响定时器本身，
      // 只需要确保_onlineCheckTimers的键是ID
      // 如果旧的URL对应的定时器存在，需要取消并用新的ID启动
      // 实际上，由于定时器现在将与ID关联，这里不需要特殊处理URL变化
      // 只需要确保_startOnlineCheck和_cancelOnlineCheck使用ID作为键
    }
  }

  /// 删除一个摄像头
  /// 使用摄像头的唯一ID来查找并删除
  void removeCamera(Camera camera) {
    final int index = cameras.indexWhere((c) => c.id == camera.id); // 使用ID查找
    if (index != -1) {
      _cameraBox.deleteAt(index); // 从Hive Box中删除数据
      cameras.removeAt(index); // 从RxList中删除
      _cancelOnlineCheck(camera.id!); // 删除后取消在线状态检测，使用ID，确保id不为空
    }
  }

  /// 根据ID查找摄像头
  Camera? findCameraById(String id) {
    try {
      return cameras.firstWhere((camera) => camera.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 启动所有摄像头的在线状态检测
  void _startAllOnlineChecks() {
    for (var camera in cameras) {
      _startOnlineCheck(camera);
    }
  }

  /// 为单个摄像头启动在线状态检测定时器
  /// 定时器现在与摄像头的唯一ID关联
  void _startOnlineCheck(Camera camera) {
    // 如果已经有定时器，先取消
    _cancelOnlineCheck(camera.id!); // 使用ID取消，确保id不为空

    // 每两分钟尝试连接
    _onlineCheckTimers[camera.id!] = Timer.periodic(
      // 使用ID作为键，确保id不为空
      const Duration(minutes: 2),
      (timer) {
        _checkOnlineStatus(camera);
      },
    );
    // 立即进行一次在线状态检测
    _checkOnlineStatus(camera);
  }

  /// 取消单个摄像头的在线状态检测定时器
  /// 使用摄像头的唯一ID来取消
  void _cancelOnlineCheck(String? cameraId) {
    // 参数改为可空cameraId
    if (cameraId != null) {
      _onlineCheckTimers[cameraId]?.cancel();
      _onlineCheckTimers.remove(cameraId);
    }
  }

  /// 取消所有摄像头的在线状态检测定时器
  void _cancelAllOnlineChecks() {
    _onlineCheckTimers.forEach((url, timer) => timer.cancel());
    _onlineCheckTimers.clear();
  }

  /// 检查摄像头在线状态
  Future<void> _checkOnlineStatus(Camera camera) async {
    try {
      // 尝试连接到摄像头的IP地址和端口，超时时间为10秒
      final socket = await Socket.connect(
        camera.ipAddress,
        int.parse(camera.port),
        timeout: const Duration(seconds: 10),
      );
      socket.destroy(); // 连接成功后立即关闭socket

      // 如果连接成功，更新摄像头在线状态为true
      if (!camera.isOnline) {
        final updatedCamera = camera.copyWith(isOnline: true);
        updateCamera(updatedCamera);
      }
    } catch (e) {
      // 如果连接失败或超时，更新摄像头在线状态为false
      if (camera.isOnline) {
        final updatedCamera = camera.copyWith(isOnline: false);
        updateCamera(updatedCamera);
      }
    }
  }
}
