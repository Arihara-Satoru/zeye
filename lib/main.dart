import 'package:flutter/material.dart';
import 'package:easy_onvif/onvif.dart';
import 'package:media_kit/media_kit.dart';
import 'package:zeye/page/rtsp_page.dart';

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
      title: 'Easy ONVIF Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OnvifHomePage(),
      routes: {'/rtsp': (context) => RtspPlayerPage()},
    );
  }
}

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
        _streamUri = streamUri;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Easy ONVIF Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
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
                  ? const CircularProgressIndicator(color: Colors.white)
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
              if (_streamUri != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/rtsp');
                  },
                  child: const Text('播放 RTSP 流'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
