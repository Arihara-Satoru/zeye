import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 导入GetX
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.
import 'package:zeye/controllers/camera_controller.dart'; // 导入摄像头控制器
import 'package:zeye/models/camera_model.dart'; // 导入摄像头模型

/// RTSP播放页面
class RtspPage extends StatefulWidget {
  final Camera camera; // 接收Camera对象

  const RtspPage({super.key, required this.camera});

  @override
  State<RtspPage> createState() => _RtspPageState();
}

class _RtspPageState extends State<RtspPage> {
  // 创建一个[Player]来控制播放。
  late final player = Player();
  // 创建一个[VideoController]来处理[Player]的视频输出。
  late final controller = VideoController(player);
  // 获取摄像头控制器实例
  late final CameraController cameraController; // 延迟初始化

  @override
  void initState() {
    super.initState();
    cameraController = Get.find(); // 在initState中获取控制器实例
    // 构建RTSP URL，包含用户名和密码（如果存在）
    String rtspUrl = widget.camera.url;
    if (widget.camera.username.isNotEmpty &&
        widget.camera.password.isNotEmpty) {
      // 假设URL格式为 rtsp://ip:port/path
      // 插入用户名和密码到URL中
      final uri = Uri.parse(widget.camera.url);
      rtspUrl =
          '${uri.scheme}://${widget.camera.username}:${widget.camera.password}@${uri.host}:${uri.port}${uri.path}';
    }

    // 播放媒体
    player.open(Media(rtspUrl));

    // 监听播放器状态，更新摄像头连接状态
    player.stream.playing.listen((isPlaying) {
      if (isPlaying) {
        // 播放开始，更新摄像头连接状态为true
        final updatedCamera = widget.camera.copyWith(isConnected: true);
        cameraController.updateCamera(updatedCamera);
      }
    });
  }

  @override
  void dispose() {
    // 播放器销毁时，更新摄像头连接状态为false
    final updatedCamera = widget.camera.copyWith(isConnected: false);
    // 在setState完成后再执行这些操作
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cameraController.updateCamera(updatedCamera);
    });
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.camera.name}（如果加载时间过长请返回重新进入）'),
      ), // 显示摄像头名称作为标题

      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 9.0 / 16.0,
          // 使用[Video]小部件显示视频输出。
          child: Video(controller: controller),
        ),
      ),
    );
  }
}
