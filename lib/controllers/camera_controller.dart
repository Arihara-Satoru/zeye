// lib/controllers/camera_controller.dart

import 'dart:async'; // 导入定时器
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 导入Hive Flutter
import 'package:easy_onvif/onvif.dart'; // 导入easy_onvif库
import '../models/camera_model.dart'; // 导入摄像头模型

/// 摄像头控制器
/// 管理摄像头的添加、删除、更新和持久化存储，并处理快照刷新和在线状态
class CameraController extends GetxController {
  // 摄像头列表，使用RxList使其可观察
  final RxList<Camera> cameras = <Camera>[].obs;
  // Hive Box实例，用于数据持久化
  late final Box<Camera> _cameraBox; // 声明为late final
  // 定时器列表，用于管理每个摄像头的快照刷新
  final Map<String, Timer> _snapshotTimers = {};

  @override
  void onInit() {
    super.onInit();
    _cameraBox = Hive.box<Camera>('cameras'); // 在onInit中获取Box实例
    _loadCameras(); // 加载摄像头数据
    _startAllSnapshotRefresh(); // 启动所有摄像头的快照刷新
  }

  @override
  void onClose() {
    _cancelAllSnapshotRefresh(); // 关闭时取消所有定时器
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
    _startSnapshotRefresh(camera); // 添加后启动快照刷新
  }

  /// 更新一个摄像头
  void updateCamera(Camera updatedCamera) {
    final int index = cameras.indexWhere(
      (camera) => camera.url == updatedCamera.url,
    );
    if (index != -1) {
      _cameraBox.putAt(index, updatedCamera); // 更新Hive Box中的数据
      cameras[index] = updatedCamera; // 更新RxList
      // 如果在线状态或URL改变，重新启动快照刷新
      if (cameras[index].isOnline != updatedCamera.isOnline ||
          cameras[index].url != updatedCamera.url) {
        _cancelSnapshotRefresh(updatedCamera.url);
        _startSnapshotRefresh(updatedCamera);
      }
    }
  }

  /// 删除一个摄像头
  void removeCamera(Camera camera) {
    final int index = cameras.indexWhere((c) => c.url == camera.url);
    if (index != -1) {
      _cameraBox.deleteAt(index); // 从Hive Box中删除数据
      cameras.removeAt(index); // 从RxList中删除
      _cancelSnapshotRefresh(camera.url); // 删除后取消快照刷新
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

  /// 启动所有摄像头的快照刷新
  void _startAllSnapshotRefresh() {
    for (var camera in cameras) {
      _startSnapshotRefresh(camera);
    }
  }

  /// 为单个摄像头启动快照刷新定时器
  void _startSnapshotRefresh(Camera camera) {
    // 如果已经有定时器，先取消
    _cancelSnapshotRefresh(camera.url);

    // 每分钟刷新一次快照
    _snapshotTimers[camera.url] = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) {
      _getSnapshot(camera);
    });
    // 立即获取一次快照
    _getSnapshot(camera);
  }

  /// 取消单个摄像头的快照刷新定时器
  void _cancelSnapshotRefresh(String cameraUrl) {
    _snapshotTimers[cameraUrl]?.cancel();
    _snapshotTimers.remove(cameraUrl);
  }

  /// 取消所有摄像头的快照刷新定时器
  void _cancelAllSnapshotRefresh() {
    _snapshotTimers.forEach((url, timer) => timer.cancel());
    _snapshotTimers.clear();
  }

  /// 获取ONVIF设备的快照并更新摄像头状态
  Future<void> _getSnapshot(Camera camera) async {
    try {
      // 尝试连接ONVIF设备并获取快照URI
      final onvif = await Onvif.connect(
        host: '${camera.ipAddress}:${camera.port}', // 将IP和端口合并到host中
        username: camera.username,
        password: camera.password,
      );

      // 获取媒体服务地址
      final capabilities = await onvif.deviceManagement.getCapabilities();
      final mediaXAddr = capabilities.media?.xAddr;

      if (mediaXAddr == null) {
        throw Exception('无法获取媒体服务地址');
      }

      // 获取配置文件
      final profiles = await onvif.media.getProfiles();
      if (profiles.isEmpty) {
        throw Exception('未找到任何配置文件');
      }

      // 获取快照URI
      final snapshotUri = await onvif.media.getSnapshotUri(
        profiles.first.token,
      );

      // 检查快照URI是否为空
      if (snapshotUri == null || snapshotUri.isEmpty) {
        throw Exception('无法获取快照URI，返回为空');
      }

      // 解析快照URI，确保使用正确的快照端口
      Uri uri = Uri.parse(snapshotUri);
      String finalSnapshotUrl;

      // 检查URI是否包含端口，或者端口是否为80
      // 如果URI没有端口，或者端口不是80，则使用camera.snapshotPort
      if (uri.port == 0 || uri.port.toString() != camera.snapshotPort) {
        finalSnapshotUrl =
            '${uri.scheme}://${uri.host}:${camera.snapshotPort}${uri.path}';
      } else {
        finalSnapshotUrl = snapshotUri;
      }

      // 更新摄像头模型
      final updatedCamera = camera.copyWith(
        isOnline: true,
        snapshotUrl: finalSnapshotUrl, // 使用处理后的快照URL
      );
      updateCamera(updatedCamera); // 更新到Hive和RxList
      print('摄像头 ${camera.name} 快照获取成功: $finalSnapshotUrl');
    } catch (e) {
      print('获取摄像头 ${camera.name} 快照失败: $e');
      print(
        'ONVIF连接尝试信息: Host=${camera.ipAddress}:${camera.port}, Username=${camera.username}, Password=${camera.password}',
      );
      // 如果获取失败，将设备标记为离线，并清除快照URL
      final updatedCamera = camera.copyWith(isOnline: false, snapshotUrl: null);
      updateCamera(updatedCamera); // 更新到Hive和RxList
    }
  }
}
