import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb; // 导入kIsWeb用于判断是否是Web平台
import 'package:universal_platform/universal_platform.dart'; // 导入universal_platform用于判断平台

/// 媒体工具类，用于处理截图和录屏（待实现）功能
class MediaTools {
  /// 请求存储权限
  /// 请求存储权限
  /// 返回true表示权限已授予，false表示权限被拒绝或永久拒绝
  static Future<bool> requestStoragePermission() async {
    // 对于非Android/iOS平台，通常不需要显式存储权限
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        debugPrint('存储权限被拒绝');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint('存储权限被永久拒绝，请在设置中启用');
        openAppSettings();
        return false;
      }
      return false;
    }
    // 对于桌面平台（Windows, macOS, Linux）和Web，默认认为有权限
    return true;
  }

  /// 截图指定Widget并保存到相册
  /// [key]：要截图的Widget的GlobalKey
  /// [context]：BuildContext，用于显示SnackBar
  static Future<void> captureAndSaveScreenshot(
    GlobalKey key,
    BuildContext context,
  ) async {
    // 检查并请求存储权限 (仅对移动平台有效)
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      bool hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有存储权限，无法保存截图')));
        return;
      }
    }

    try {
      // 获取RenderRepaintBoundary
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('无法找到RenderRepaintBoundary');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('截图失败：无法找到截图区域')));
        return;
      }

      // 将Widget渲染成图片
      ui.Image image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        debugPrint('无法将图片转换为ByteData');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('截图失败：图片数据为空')));
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      String? savePath;
      String message;

      if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
        // 移动平台保存到相册
        final result = await ImageGallerySaver.saveImage(pngBytes);
        if (result['isSuccess']) {
          savePath = result['filePath'];
          message = '截图已保存到相册: $savePath';
        } else {
          message = '截图保存失败: ${result['errorMessage']}';
        }
      } else if (UniversalPlatform.isWindows ||
          UniversalPlatform.isMacOS ||
          UniversalPlatform.isLinux) {
        // 桌面平台保存到图片目录
        final directory =
            await getDownloadsDirectory(); // 或者 getApplicationDocumentsDirectory(), getDownloadsDirectory()
        if (directory == null) {
          message = '截图保存失败: 无法获取下载目录';
        } else {
          final String fileName =
              'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
          final File file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pngBytes);
          savePath = file.path;
          message = '截图已保存到: $savePath';
        }
      } else if (kIsWeb) {
        // Web平台，提供下载链接或直接下载
        // 在Web上，通常是直接触发下载，而不是保存到“相册”
        // 这里简化处理，实际可能需要更复杂的JS交互
        message = 'Web平台截图功能待实现或直接下载';
        // 实际Web截图保存可能需要使用dart:html的Blob和URL.createObjectURL
        // 或者让用户手动保存图片
      } else {
        message = '不支持的平台，无法保存截图';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('截图过程中发生错误: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('截图失败: $e')));
    }
  }

  /// 录屏功能（待实现）
  static Future<void> startScreenRecording() async {
    // TODO: 实现录屏功能
    debugPrint('开始录屏...');
    // 这里可以集成第三方录屏插件或原生录屏API
  }

  static Future<void> stopScreenRecording() async {
    // TODO: 实现停止录屏功能
    debugPrint('停止录屏...');
  }
}
