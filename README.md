# 离线电子秤收银

从 [cashiertraeV2](https://github.com/lijingpan/cashiertraeV2) 下载并独立放在 `electronic-scale/`。这是 Android 横屏 Flutter 应用，商品保存在设备本地 SQLite，串口读取电子秤，USB 热敏打印机打印小票；日常称重和收银不需要网络。

## 使用

1. 在“菜单管理”添加商品，选择按公斤计价或按件计价，并填写价格。
2. 在“设置”填写秤的串口路径和波特率。原仓库默认 `/dev/ttyS4`、`9600`，请按实际设备修改；点击“测试串口连接”检查当前输入值，再保存。
3. 按公斤计价时，将商品放上秤，等待重量稳定后加入购物车。串口数据无效或超过 3 秒没有更新时，旧重量不能入单。按件计价不需要连接秤。
4. “设置 → 打印小票”默认开启。开启时需要连接支持的 USB 打印机，打印成功才会清空本单；失败时保留购物车。关闭后按钮变为“完成本单”，无需打印机即可结单。该开关保存在本机，重启后仍生效。

## 设备范围

- 秤：原仓库 `serialport-1.1.0.aar` 支持的 Android 串口设备和现有 16 字节报文协议；计价单位为 kg。其他协议或端口需要适配。
- 打印机：原仓库 `autoreplyprint.aar` 支持的 USB 58 mm 热敏打印机；目前自动查找 VID `0x4B43` 或 `0x0FE6`。其他打印机需要扩充识别和打印驱动。
- 若设备限制串口读写权限，需按设备厂商说明授权；单纯安装应用不能解除系统权限限制。

## 开发构建

需要 Flutter SDK（Dart SDK 与 `pubspec.yaml` 的 `^3.10.7` 兼容）、Android SDK 和 JDK 17。
副屏插件 `presentation_displays` 的 Android 兼容修正版已放在 `vendor/presentation_displays/`，构建时使用项目内版本，无需修改全局 Pub 缓存。

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK 输出在 `build/app/outputs/flutter-apk/app-release.apk`。当前 Android release 构建配置仍使用调试签名，仅适合内部设备试用。正式分发前需要配置专用签名并在目标秤与打印机上实测。

已在 Android 35 模拟器断网验证应用启动、打印开关重启保留、创建按件商品、加入购物车及无打印结单。模拟器无法验证真实串口称重和 USB 出纸。
