// 알림 문구의 번역 (056)
//
// 오류 문구(055)와 다른 점이 하나 있고, 그것이 이 파일이 따로 있는 이유다.
//
// 오류는 요청이 들어온 **그 자리에서** 나가므로 Accept-Language 를 보면
// 된다. 알림은 아니다 — 담당자가 봉사를 부탁할 때, 밤에 크론이 돌 때 만들어
// 지고, 받는 사람은 그 자리에 없다. 그래서 문구를 **미리 조립해 두면 안
// 되고**, 받는 사람이 정해진 뒤에 그 사람의 언어로 지어야 한다.
//
// 그래서 라우트는 완성된 문장 대신 `{ key, params }` 를 넘긴다.
//
// 담당자가 손으로 적은 말(공지 본문, 봉사 요청에 덧붙인 말)은 여기 없다.
// 그것은 그 사람의 말이므로 옮기지 않는다.

const T = {
  // ── 참가자에게 ────────────────────────────────────────────
  serviceAskTitle: {
    ko: '봉사 부탁',
    es: 'Un pedido de ayuda',
    en: 'A favor to ask',
    pt: 'Um pedido de ajuda',
  },
  serviceAssignedTitle: {
    ko: '봉사 배정',
    es: 'Quedó a su cargo',
    en: 'It is yours to do',
    pt: 'Ficou a seu cargo',
  },
  serviceAskBody: {
    ko: '{name} 님, {what} 을(를) 부탁드립니다. 앱에서 수락 여부를 알려 주십시오.',
    es: '{name}, le pedimos {what}. Diga en la aplicación si puede.',
    en: '{name}, we would like to ask you for {what}. Let us know in the app.',
    pt: '{name}, gostaríamos de pedir {what}. Diga no aplicativo se pode.',
  },
  serviceAssignedBody: {
    ko: '{name} 님, 적어 주신 대로 {what} 을(를) 맡아 주시게 되었습니다.',
    es: '{name}, como usted se ofreció, queda a su cargo {what}.',
    en: '{name}, as you offered, {what} is yours to do.',
    pt: '{name}, como você se ofereceu, {what} fica a seu cargo.',
  },
  serviceCallDefault: {
    ko: '봉사자를 찾습니다 — {n}자리',
    es: 'Buscamos quien ayude — {n} lugares',
    en: 'Looking for help — {n} places',
    pt: 'Procuramos quem ajude — {n} lugares',
  },
  departureCheckTitle: {
    ko: '✈️ 예정대로 출발합니까?',
    es: '✈️ ¿Sale como estaba previsto?',
    en: '✈️ Are you leaving as planned?',
    pt: '✈️ Vai sair como estava previsto?',
  },
  departureCheckBody: {
    ko: '3시간 뒤 출발입니다. 지연이나 결항이 있으면 알려 주십시오.',
    es: 'Sale en 3 horas. Avísenos si hay demora o cancelación.',
    en: 'You leave in 3 hours. Tell us if it is delayed or cancelled.',
    pt: 'Sai em 3 horas. Avise se houver atraso ou cancelamento.',
  },

  // ── 담당자에게 ────────────────────────────────────────────
  // 공동 관리자가 스페인어를 쓴다. 담당자용이라고 한국어로 두면 그 사람은
  // 무슨 일이 일어났는지 모른다.
  admRegistrationEdited: {
    ko: '✏️ <b>[{program}] 등록 정보 수정</b>\n\n👤 {who}\n이 등록 내용을 수정했습니다.',
    es: '✏️ <b>[{program}] Cambió su inscripción</b>\n\n👤 {who}\nModificó lo que había cargado.',
    en: '✏️ <b>[{program}] Registration changed</b>\n\n👤 {who}\nChanged what they had filled in.',
    pt: '✏️ <b>[{program}] Mudou a inscrição</b>\n\n👤 {who}\nAlterou o que havia preenchido.',
  },
  admRegistrationSubmitted: {
    ko: '🎉 <b>[{program}] 최종 등록 제출</b>\n\n👤 {who} 이(가) 등록을 최종 제출했습니다.',
    es: '🎉 <b>[{program}] Inscripción terminada</b>\n\n👤 {who} terminó de inscribirse.',
    en: '🎉 <b>[{program}] Registration finished</b>\n\n👤 {who} finished registering.',
    pt: '🎉 <b>[{program}] Inscrição concluída</b>\n\n👤 {who} concluiu a inscrição.',
  },
  admDepartureChanged: {
    ko: '✈️ <b>출발 변경</b>\n\n👤 {who}\n{what}{note}',
    es: '✈️ <b>Cambió la salida</b>\n\n👤 {who}\n{what}{note}',
    en: '✈️ <b>Departure changed</b>\n\n👤 {who}\n{what}{note}',
    pt: '✈️ <b>Mudou a saída</b>\n\n👤 {who}\n{what}{note}',
  },
  admDepartureDelayed: {
    ko: '지연 → {when}',
    es: 'Demorado → {when}',
    en: 'Delayed → {when}',
    pt: 'Atrasado → {when}',
  },
  admDepartureCancelled: {
    ko: '결항·변경',
    es: 'Cancelado o cambiado',
    en: 'Cancelled or changed',
    pt: 'Cancelado ou alterado',
  },
  admServiceCallSent: {
    ko: '[봉사] {what} — {n}자리 도움 요청을 보냈습니다',
    es: '[Ayuda] {what} — se pidió ayuda para {n} lugares',
    en: '[Service] {what} — asked for help with {n} places',
    pt: '[Ajuda] {what} — pediu ajuda para {n} lugares',
  },
  admServiceVolunteered: {
    ko: '[봉사] {who} 님이 {what} 에 손을 들었습니다',
    es: '[Ayuda] {who} se ofreció para {what}',
    en: '[Service] {who} offered to do {what}',
    pt: '[Ajuda] {who} se ofereceu para {what}',
  },
  admAnnouncement: {
    ko: '[공지] {body}',
    es: '[Aviso] {body}',
    en: '[Notice] {body}',
    pt: '[Aviso] {body}',
  },
  admSos: {
    ko: '🆘 <b>[{program}] SOS 긴급 알림</b>\n\n👤 {who}\n⚠️ 상황: {what}{where}{note}\n\n<i>앱에서 확인하고 즉시 대응해 주세요.</i>',
    es: '🆘 <b>[{program}] SOS</b>\n\n👤 {who}\n⚠️ Situación: {what}{where}{note}\n\n<i>Mírelo en la aplicación y responda ya.</i>',
    en: '🆘 <b>[{program}] SOS</b>\n\n👤 {who}\n⚠️ Situation: {what}{where}{note}\n\n<i>Open the app and respond now.</i>',
    pt: '🆘 <b>[{program}] SOS</b>\n\n👤 {who}\n⚠️ Situação: {what}{where}{note}\n\n<i>Veja no aplicativo e responda já.</i>',
  },
  sosWhere: {
    ko: '\n📍 위치: {url}',
    es: '\n📍 Dónde: {url}',
    en: '\n📍 Where: {url}',
    pt: '\n📍 Onde: {url}',
  },
  sosWhereUnknown: {
    ko: '\n📍 위치: 수신 불가',
    es: '\n📍 Dónde: no se pudo saber',
    en: '\n📍 Where: could not tell',
    pt: '\n📍 Onde: não foi possível saber',
  },

  // SOS 상황. 알림 문장 한가운데 들어가므로 여기만 한국어면 반쪽이 된다.
  admDailySummary: {
    ko: '📊 <b>[{program}] 일일 등록 현황</b>\n\n👥 총 등록: {total}명\n✅ 등록 완료: {done}명\n⏳ 진행 중: {doing}명\n💰 입금 대기: {pending}건\n✔️ 입금 확인: {confirmed}건',
    es: '📊 <b>[{program}] Cómo va la inscripción</b>\n\n👥 Anotados: {total}\n✅ Terminaron: {done}\n⏳ A medio hacer: {doing}\n💰 Pagos por confirmar: {pending}\n✔️ Pagos confirmados: {confirmed}',
    en: '📊 <b>[{program}] Where registration stands</b>\n\n👥 Signed up: {total}\n✅ Finished: {done}\n⏳ Half done: {doing}\n💰 Payments to confirm: {pending}\n✔️ Payments confirmed: {confirmed}',
    pt: '📊 <b>[{program}] Como vai a inscrição</b>\n\n👥 Inscritos: {total}\n✅ Concluíram: {done}\n⏳ Pela metade: {doing}\n💰 Pagamentos a confirmar: {pending}\n✔️ Pagamentos confirmados: {confirmed}',
  },
  admSosPushTitle: {
    ko: '🆘 SOS: {who}', es: '🆘 SOS: {who}', en: '🆘 SOS: {who}', pt: '🆘 SOS: {who}',
  },
  sosHealth: { ko: '🚑 건강/의료 응급', es: '🚑 Urgencia médica', en: '🚑 Medical emergency', pt: '🚑 Emergência médica' },
  sosSafety: { ko: '🆘 신변 위협', es: '🆘 Está en peligro', en: '🆘 In danger', pt: '🆘 Está em perigo' },
  sosLost:   { ko: '🗺️ 길을 잃음', es: '🗺️ Se perdió', en: '🗺️ Lost', pt: '🗺️ Se perdeu' },

  // ── 이름을 못 얻었을 때 ───────────────────────────────────
  someone: { ko: '참가자', es: 'Un participante', en: 'A participant', pt: 'Um participante' },
};

export const NOTIFY_KEYS = Object.keys(T);
export const NOTIFY = T;

/// 그 사람의 언어로 문장을 짓는다.
///
/// 모르는 언어면 한국어로 둔다 — 지금까지와 같다.
export function say(key, params = {}, lang = 'ko') {
  const row = T[key];
  if (!row) return '';
  const tpl = row[lang] ?? row.ko;
  return tpl.replace(/\{(\w+)\}/g, (_, k) => {
    const v = params?.[k];
    if (v === undefined || v === null || v === '') {
      // 이름이 비어 있으면 "님," 같은 조각만 남아 말이 안 된다.
      return k === 'name' || k === 'who' ? say('someone', {}, lang) : '';
    }
    // 값 자체가 문구일 수 있다 — 같은 언어로 마저 짓는다.
    if (typeof v === 'object' && v.key) return say(v.key, v.params, lang);
    return String(v);
  });
}
