import 'package:easy_onvif/onvif.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 导入GetX
import 'package:zeye/controllers/camera_controller.dart'; // 导入摄像头控制器
import 'package:zeye/models/camera_model.dart'; // 导入摄像头模型

class OnvifHomePage extends StatefulWidget {
  const OnvifHomePage({super.key});
  @override
  State<OnvifHomePage> createState() => _OnvifHomePageState();
}

class _OnvifHomePageState extends State<OnvifHomePage> {
  final _hostController = TextEditingController(text: '192.168.1.8');
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'bosmasmart');

  String? _manufacturer;
  String? _model;
  String? _serialNumber;
  String? _streamUri;
  String? _error;

  bool _loading = false;

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
      _manufacturer = null;
      _model = null;
      _serialNumber = null;
      _streamUri = null;
    });

    try {
      final onvif = await Onvif.connect(
        host: _hostController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      final deviceInfo = await onvif.deviceManagement.getDeviceInformation();

      final profiles = await onvif.media.getProfiles();

      String? streamUri;
      if (profiles.isNotEmpty) {
        streamUri = await onvif.media.getStreamUri(profiles.first.token);
      }

      setState(() {
        _manufacturer = deviceInfo.manufacturer ?? '无';
        _model = deviceInfo.model ?? '无';
        _serialNumber = deviceInfo.serialNumber ?? '无';
        _streamUri = streamUri?.replaceFirst(
          'rtsp://',
          'rtsp://${_usernameController.text}:${_passwordController.text}@',
        );

        // 创建Camera对象并添加到控制器
        if (_streamUri != null) {
          final camera = Camera(
            name: _hostController.text, // 暂时用IP作为名称
            url: _streamUri!,
            username: _usernameController.text,
            password: _passwordController.text,
            ipAddress: _hostController.text,
            port: '554', // 默认RTSP端口
          );
          // 在setState完成后再执行这些操作
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.find<CameraController>().addCamera(camera);
            Get.back(); // 连接成功后关闭对话框
          });
        }
      });
    } catch (e) {
      setState(() {
        _error = '连接失败: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface, // 从主题里取背景颜色
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: '摄像头 IP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _connect,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.grey)
                  : const Text('连接摄像头'),
            ),
            const SizedBox(height: 30),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_manufacturer != null) ...[
              Text('制造商: $_manufacturer'),
              Text('型号: $_model'),
              Text('序列号: $_serialNumber'),
              const SizedBox(height: 12),
              if (_streamUri != null) ...[
                const Text('视频流地址:'),
                SelectableText(_streamUri!),
              ],
              SizedBox(height: 12),
              // 移除播放RTSP流按钮，因为现在直接在主界面显示卡片并点击播放
              // if (_streamUri != null)
              //   ElevatedButton(
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => RtspPage(url: _streamUri!),
              //         ),
              //       );
              //     },
              //     child: const Text('播放 RTSP 流'),
              //   ),
            ],
          ],
        ),
      ),
    );
  }
}
