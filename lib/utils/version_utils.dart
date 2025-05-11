import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionUtils {
  static Future<void> checkForUpdate(BuildContext context) async {
    final dio = Dio();
    try {
      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get latest version
      final response =
          await dio.get('http://hungryhenry.xyz/argumate/versions.json');
      final latestVersion = response.data['latest'];

      if (isUpdateAvailable(currentVersion, latestVersion)) {
        if (!context.mounted) return;

        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('发现新版本'),
            content:
                Text('当前版本: $currentVersion\n最新版本: $latestVersion\n\n是否立即更新？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('稍后更新'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('立即更新'),
              ),
            ],
          ),
        );

        if (shouldUpdate == true) {
          final String platform = Platform.isWindows
              ? 'exe'
              : Platform.isAndroid
                  ? 'apk'
                  : Platform.isMacOS
                      ? 'dmg'
                      : "unknown";
          final url = 'http://hungryhenry.xyz/argumate/latest.$platform';

          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法打开更新链接')),
            );
          }
        }
      }
    } catch (e) {
      print(e);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检查更新失败')),
      );
    }
  }

  static bool isUpdateAvailable(String currentVersion, String latestVersion) {
    // 解析版本号
    List<String> parseVersion(String version) {
      List<String> parts = version.split('-');
      String mainPart = parts[0];
      String? prereleasePart = parts.length > 1 ? parts[1] : null;

      List<String> mainSegments = mainPart.split('.');
      if (mainSegments.length != 3) {
        throw FormatException('Invalid version format: $version');
      }

      List<String> result = [...mainSegments];
      if (prereleasePart != null) {
        result.add(prereleasePart);
      }
      return result;
    }

    // 比较两个版本号
    int compareVersions(List<String> a, List<String> b) {
      // 比较主版本号
      for (int i = 0; i < 3; i++) {
        int aNum = int.parse(a[i]);
        int bNum = int.parse(b[i]);
        if (aNum != bNum) {
          return aNum.compareTo(bNum);
        }
      }

      // 处理预发布版本
      bool aHasPre = a.length > 3;
      bool bHasPre = b.length > 3;

      if (!aHasPre && !bHasPre) return 0; // 都没有预发布版本
      if (aHasPre && !bHasPre) return -1; // 当前版本是预发布，最新版本不是
      if (!aHasPre && bHasPre) return 1; // 最新版本是预发布，当前版本不是

      // 比较预发布部分
      List<String> aPre = a[3].split('.');
      List<String> bPre = b[3].split('.');

      for (int i = 0;; i++) {
        if (i >= aPre.length && i >= bPre.length) return 0;
        if (i >= aPre.length) return -1;
        if (i >= bPre.length) return 1;

        String aElem = aPre[i];
        String bElem = bPre[i];

        bool aIsNum = int.tryParse(aElem) != null;
        bool bIsNum = int.tryParse(bElem) != null;

        if (aIsNum && bIsNum) {
          int aNum = int.parse(aElem);
          int bNum = int.parse(bElem);
          if (aNum != bNum) return aNum.compareTo(bNum);
        } else if (aIsNum) {
          return -1;
        } else if (bIsNum) {
          return 1;
        } else {
          int compare = aElem.compareTo(bElem);
          if (compare != 0) return compare;
        }
      }
    }

    try {
      List<String> current = parseVersion(currentVersion);
      List<String> latest = parseVersion(latestVersion);
      return compareVersions(current, latest) < 0;
    } catch (e) {
      throw ArgumentError('Invalid version format: $e');
    }
  }
}
