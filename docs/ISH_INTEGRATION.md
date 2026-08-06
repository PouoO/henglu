# iSH-ARM64 嵌入式沙盒

把 iSH-ARM64 嵌进 Kelivo（henglu），让 app 里能跑 Alpine Linux shell。

## 目录

- `ios/deps/build_ish.sh`：拉取 OpenMinis/ish-arm64 并编成静态库
- `ios/deps/prepare_alpine_rootfs.sh`：下载 Alpine minirootfs 并转成 fakefs
- `ios/ish_sandbox/`：本地 CocoaPods 插件，封装 iSH 启动、rootfs 解压、MethodChannel
- `lib/services/ish_sandbox_service.dart`：Dart 调用入口
- `codemagic.yaml`：CI 构建流程

## 本地构建（需要 macOS + Xcode）

```bash
cd ios/deps
./build_ish.sh              # 编出静态库
./prepare_alpine_rootfs.sh  # 准备 rootfs

cd ../..
flutter pub get
flutter build ios --no-codesign
```

## CI

`codemagic.yaml` 会先安装依赖并跑上面两个脚本，缓存结果后执行 Flutter 构建。

## Dart 用法

```dart
final ish = IshSandboxService.instance;
if (await ish.boot()) {
  final pid = await ish.execute('/bin/ls -la /');
}
```

## 注意

- iSH 是 GPLv3，嵌入后整个 app 授权也必须是 GPLv3
- 首次编 iSH 很慢（30-60 分钟），主要靠 Codemagic cache 续命
- rootfs 压缩包会增大 ipa 体积
