# Zeye - Easy ONVIF 摄像头管理与 RTSP 播放器

Zeye 是一个基于 Flutter 开发的应用程序，旨在提供一个简单易用的界面，用于连接 ONVIF 兼容的 IP 摄像头，获取设备信息，并播放其 RTSP 视频流。

## 主要功能

- **ONVIF 摄像头连接**: 通过输入摄像头的 IP 地址、用户名和密码，应用程序可以连接到 ONVIF 兼容的摄像头。
- **设备信息获取**: 连接成功后，可以显示摄像头的制造商、型号和序列号等基本信息。
- **RTSP 流地址获取**: 应用程序能够从摄像头获取可用的 RTSP 视频流地址。
- **RTSP 视频播放**: 集成了 `media_kit` 库，支持直接在应用程序内播放获取到的 RTSP 视频流。

## 技术栈

- **Flutter**: 用于构建跨平台的用户界面。
- **easy_onvif**: 用于与 ONVIF 兼容的摄像头进行通信。
- **media_kit**: 用于高性能的视频播放，支持 RTSP 流。

## 如何运行

### 1. 克隆仓库

```bash
git clone [您的仓库地址]
cd zeye
```

### 2. 安装 Flutter 依赖

```bash
flutter pub get
```

### 3. 运行应用程序

在连接 Android 设备或启动模拟器后，运行：

```bash
flutter run
```

### 4. 构建 APK (Android)

如果您需要构建发布版本的 APK，请运行：

```bash
flutter build apk --release
```

**注意**: 在构建 Android APK 之前，请确保 `android/app/src/main/AndroidManifest.xml` 文件中已包含网络权限：

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 使用说明

1.  在主界面输入您的 ONVIF 兼容摄像头的 IP 地址、用户名和密码。
2.  点击“连接摄像头”按钮。
3.  连接成功后，将显示摄像头信息和视频流地址。
4.  点击“播放 RTSP 流”按钮，即可在新页面观看视频流。

## 贡献

欢迎任何形式的贡献！如果您有任何建议或发现 Bug，请随时提交 Issue 或 Pull Request。

## 许可证

[根据您的项目选择合适的许可证，例如 MIT, Apache 2.0 等]
