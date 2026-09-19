import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  LANGS,
  pickTargets,
  mergeTranslations,
  pickText,
} from '../src/services/translate_api.js';

// 공지 자동 번역 (070)
//
// 기계가 옮긴 글이라 틀릴 수 있다. 그래서 **원문을 절대 잃지 않는 것**이
// 이 규칙의 요지다.

describe('옮길 언어 고르기', () => {
  test('적은 언어는 빼고 나머지 셋', () => {
    assert.deepEqual(pickTargets('ko'), ['en', 'es', 'pt']);
    assert.deepEqual(pickTargets('es'), ['ko', 'en', 'pt']);
  });

  test('모르는 언어면 넷 다 옮긴다', () => {
    // 원문 자리가 없으므로 뺄 것도 없다.
    assert.deepEqual(pickTargets('fr'), LANGS);
  });
});

describe('원문과 번역 합치기', () => {
  test('적은 언어 자리에는 원문이 들어간다', () => {
    // 그 자리에까지 번역을 넣으면 담당자가 적은 말이 기계가 다듬은 말로
    // 바뀐다.
    const out = mergeTranslations('ko', '3조는 강당 앞에 모여 주세요', {
      en: 'Group 3, meet in front of the hall',
      ko: '기계가 다시 옮긴 한국어',
    });
    assert.equal(out.ko, '3조는 강당 앞에 모여 주세요');
    assert.equal(out.en, 'Group 3, meet in front of the hall');
  });

  test('빈 번역은 넣지 않는다', () => {
    // 빈 문자열을 넣으면 화면이 "번역이 있다" 고 보고 빈 칸을 띄운다.
    const out = mergeTranslations('ko', '원문', { en: '', es: '   ', pt: 'ok' });
    assert.equal('en' in out, false);
    assert.equal('es' in out, false);
    assert.equal(out.pt, 'ok');
  });

  test('번역이 하나도 없어도 원문은 남는다', () => {
    // 번역기를 안 붙인 서버가 이 상태다.
    const out = mergeTranslations('ko', '원문', {});
    assert.deepEqual(out, { ko: '원문' });
  });

  test('원문이 비면 아무것도 안 만든다', () => {
    assert.deepEqual(mergeTranslations('ko', '', {}), {});
  });
});

describe('보여 줄 한 줄 고르기', () => {
  const i18n = { ko: '한국어', en: 'English' };

  test('그 사람의 언어로', () => {
    assert.equal(pickText(i18n, 'en', '원문'), 'English');
  });

  test('없는 언어면 원문으로 돌아간다', () => {
    // 번역이 실패한 언어가 여기로 온다. 빈 화면보다 원문이 낫다.
    assert.equal(pickText(i18n, 'es', '원문'), '원문');
  });

  test('번역 덩이 자체가 없으면 원문', () => {
    // 070 이전에 보낸 공지가 이 상태다.
    assert.equal(pickText(null, 'es', '원문'), '원문');
    assert.equal(pickText(undefined, 'ko', '원문'), '원문');
  });

  test('빈 문자열은 번역으로 치지 않는다', () => {
    assert.equal(pickText({ es: '   ' }, 'es', '원문'), '원문');
  });
});
