// UBF 전세계 챕터 데이터 (ubf_chapters_full.json 기반)
// 대륙, 국가, 챕터, 지부장 이메일 포함

import 'dart:convert';
import 'package:flutter/services.dart';

/// 챕터 데이터 모델
class UbfChapter {
  final String name;
  final List<String> emails; // 지부장 이메일 목록

  const UbfChapter({required this.name, this.emails = const []});

  factory UbfChapter.fromJson(Map<String, dynamic> json) {
    return UbfChapter(
      name: json['name'] as String,
      emails: (json['emails'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// 국가별 챕터 데이터 모델
class UbfNationData {
  final String continent;
  final String nation;
  final List<UbfChapter> chapters;

  const UbfNationData({
    required this.continent,
    required this.nation,
    required this.chapters,
  });

  factory UbfNationData.fromJson(Map<String, dynamic> json) {
    return UbfNationData(
      continent: json['continent'] as String,
      nation: json['nation'] as String,
      chapters: (json['chapters'] as List)
          .map((c) => UbfChapter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 이메일 매칭 결과 — 지부장 확인용
class ChapterLeaderMatch {
  final String continent;
  final String nation;
  final String chapterName;

  const ChapterLeaderMatch({
    required this.continent,
    required this.nation,
    required this.chapterName,
  });
}

/// JSON에서 챕터 데이터 로드
Future<List<UbfNationData>> loadUbfChapters() async {
  final jsonStr = await rootBundle.loadString('assets/ubf_chapters.json');
  final List<dynamic> jsonList = json.decode(jsonStr);
  return jsonList
      .map((e) => UbfNationData.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 대륙 목록 추출 (중복 제거, 알파벳순)
List<String> getContinents(List<UbfNationData> data) {
  return data.map((e) => e.continent).toSet().toList()..sort();
}

/// 특정 대륙의 국가 목록 (알파벳순)
List<String> getNationsForContinent(List<UbfNationData> data, String continent) {
  return data
      .where((e) => e.continent == continent)
      .map((e) => e.nation)
      .toList()
    ..sort();
}

/// 특정 국가의 챕터 목록
List<UbfChapter> getChaptersForNation(List<UbfNationData> data, String nation) {
  final match = data.where((e) => e.nation == nation);
  if (match.isEmpty) return [];
  return match.first.chapters;
}

/// 이메일로 지부장 매칭 (대소문자 무시)
/// 매칭되는 모든 챕터를 반환
List<ChapterLeaderMatch> findLeaderByEmail(
  List<UbfNationData> data,
  String email,
) {
  final lowerEmail = email.toLowerCase().trim();
  final matches = <ChapterLeaderMatch>[];

  for (final nation in data) {
    for (final chapter in nation.chapters) {
      for (final e in chapter.emails) {
        if (e.toLowerCase().trim() == lowerEmail) {
          matches.add(ChapterLeaderMatch(
            continent: nation.continent,
            nation: nation.nation,
            chapterName: chapter.name,
          ));
        }
      }
    }
  }

  return matches;
}
