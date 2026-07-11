import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화 (앱 키가 설정된 경우에만)
  if (AppConstants.kakaoAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: AppConstants.kakaoAppKey);
  }

  // TODO: Firebase 초기화 (Push 알림 사용 시)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(
      child: UbfApp(),
    ),
  );
}
