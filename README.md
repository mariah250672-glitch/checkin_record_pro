# checkin_record_pro（签到记录器）

纯本地、无服务器的 Android 签到应用：人脸 + 定位围栏校验，本地区块链存证，二维码（S2 自包含）跨设备校验。

## 功能

- 单用户 Profile（昵称、备注）
- 人脸录入与签到比对
- 签到点围栏（方案 A）：超出半径**拒绝**签到
- 本地区块链 JSON 存储，可检测篡改
- 记录详情生成校验 QR，另一台设备「扫码校验」无需联网

## 环境

- Flutter 3.x（stable）
- Android 7.0+（minSdk 24）
- 真机推荐（需相机、GPS）

## 运行

```bash
cd checkin_record_pro
flutter pub get
flutter run
```

## 仓库

https://github.com/mariah250672-glitch/checkin_record_pro

## 说明

人脸比对为端侧轻量特征方案，适用于 MVP；生产环境可替换为 TFLite 人脸嵌入模型以提升准确率。
