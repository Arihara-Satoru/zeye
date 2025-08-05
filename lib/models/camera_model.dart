// lib/models/camera_model.dart

import 'package:hive/hive.dart'; // 导入Hive

part 'camera_model.g.dart'; // Hive生成的文件

/// 摄像头模型类
/// 用于存储摄像头的相关信息
@HiveType(typeId: 0) // HiveType注解，typeId必须唯一
class Camera {
  @HiveField(0) // HiveField注解，索引必须唯一且递增
  final String name; // 摄像头名称
  @HiveField(1)
  final String url; // RTSP流地址
  @HiveField(2)
  final String username; // 用户名
  @HiveField(3)
  final String password; // 密码
  @HiveField(4)
  final String ipAddress; // IP地址
  @HiveField(5)
  final String port; // 端口
  @HiveField(6)
  @HiveField(6)
  bool isOnline; // 设备在线状态，true为在线，false为离线
  @HiveField(7)
  String? snapshotUrl; // 快照URL
  @HiveField(8) // 新增快照端口字段
  final String snapshotPort; // 快照端口，通常为80

  /// 构造函数
  Camera({
    required this.name,
    required this.url,
    required this.username,
    required this.password,
    required this.ipAddress,
    required this.port,
    this.isOnline = false, // 默认离线
    this.snapshotUrl, // 快照URL，可为空
    String? snapshotPort, // 将参数改为可空
  }) : snapshotPort = snapshotPort ?? '80'; // 如果传入null，则使用默认值'80'

  /// 复制构造函数，用于创建新的Camera对象并修改部分属性
  Camera copyWith({
    String? name,
    String? url,
    String? username,
    String? password,
    String? ipAddress,
    String? port,
    bool? isOnline,
    String? snapshotUrl,
    String? snapshotPort, // 复制构造函数中也添加
  }) {
    return Camera(
      name: name ?? this.name,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isOnline: isOnline ?? this.isOnline,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      snapshotPort: snapshotPort ?? this.snapshotPort, // 复制构造函数中也添加
    );
  }
}
