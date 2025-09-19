import 'dart:async';
import 'package:flutter/services.dart';

class InstallPluginV2Fork {
  static const MethodChannel _channel = MethodChannel('install_plugin_v2');

  /// Install APK at [filePath]. [appId] should be your app's applicationId (used for FileProvider authority).
  static Future<bool> installApk(String filePath, String appId) async {
    final res = await _channel.invokeMethod('installApk', {'filePath': filePath, 'appId': appId});
    return res == true;
  }
}
