import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/join_link.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 초대 링크(https://…/?program=<uuid>)로 열렸는지 **여기서** 본다.
  //
  // 라우터 안에서만 보면 웹에서 놓친다. Flutter 웹은 기본이 해시 전략이라
  // 주소가 `https://…/?program=x#/home` 꼴이 되는데, GoRouter 는 `#` 뒤만
  // 보므로 쿼리가 그 시야 밖에 있다. Uri.base 는 주소 전체를 준다.
  //
  // 네이티브에서는 Uri.base 가 실행 경로라 해당 파라미터가 없어 그냥 지나간다.
  final fromUrl = programIdFromQuery(Uri.base.queryParameters);
  if (fromUrl != null) PendingJoin.remember(fromUrl);

  // 카카오 SDK 초기화 (앱 키가 설정된 경우에만)
  if (AppConstants.kakaoAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: AppConstants.kakaoAppKey);
  }

  // TODO: Firebase 초기화 (Push 알림 사용 시)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: UbfApp()));
}
