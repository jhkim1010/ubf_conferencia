// 담당자가 등록을 고쳤을 때 본인에게 가는 메일의 글 (2026-11)
//
// 담당자가 명단에서 참가자의 동반자·투어·항공·입금을 고칠 수 있게 되자,
// 본인은 무엇이 바뀌었는지 모른 채 바뀐 금액을 내게 됐다. 고친 뒤 메일로
// "무엇을 고쳤고 지금 어떻게 되어 있는지" 를 알린다.
//
// 받는 사람의 언어로 짓는다(notify_text.js 와 같은 이유). DB 도 메일
// 서버도 쓰지 않는다 — test/edit_mail_text.test.js 로 본다.

const T = {
  subject: {
    ko: '[{program}] 담당자가 등록 정보를 고쳤습니다',
    en: '[{program}] An organizer updated your registration',
    es: '[{program}] Un responsable actualizó su inscripción',
    pt: '[{program}] Um responsável atualizou sua inscrição',
  },
  hello: {
    ko: '{name} 님,',
    en: 'Dear {name},',
    es: 'Estimado/a {name}:',
    pt: 'Prezado/a {name},',
  },
  intro: {
    ko: '{program} 담당자가 등록 정보를 고쳤습니다.',
    en: 'An organizer of {program} has updated your registration.',
    es: 'Un responsable de {program} actualizó su inscripción.',
    pt: 'Um responsável de {program} atualizou sua inscrição.',
  },
  changed: {
    ko: '고친 부분: {parts}',
    en: 'What changed: {parts}',
    es: 'Qué cambió: {parts}',
    pt: 'O que mudou: {parts}',
  },
  now: {
    ko: '지금 등록되어 있는 내용',
    en: 'Your registration now',
    es: 'Su inscripción ahora',
    pt: 'Sua inscrição agora',
  },
  total: { ko: '낼 돈', en: 'Amount due', es: 'Monto a pagar', pt: 'Valor a pagar' },
  companions: { ko: '함께 오는 분', en: 'Companions', es: 'Acompañantes', pt: 'Acompanhantes' },
  tours: { ko: '투어', en: 'Tours', es: 'Tours', pt: 'Passeios' },
  arrival: { ko: '도착 편', en: 'Arrival flight', es: 'Vuelo de llegada', pt: 'Voo de chegada' },
  departure: { ko: '출발 편', en: 'Departure flight', es: 'Vuelo de salida', pt: 'Voo de partida' },
  payment: { ko: '입금', en: 'Payment', es: 'Pago', pt: 'Pagamento' },
  none: { ko: '없음', en: 'None', es: 'Ninguno', pt: 'Nenhum' },
  cancelled: {
    ko: '이 등록은 참석 취소되었습니다.',
    en: 'This registration has been cancelled.',
    es: 'Esta inscripción fue cancelada.',
    pt: 'Esta inscrição foi cancelada.',
  },
  outro: {
    ko: '틀린 것이 있으면 담당자에게 알려 주십시오. 앱에서도 확인하실 수 있습니다: {url}',
    en: 'If anything is wrong, please tell the organizers. You can also check it in the app: {url}',
    es: 'Si algo no es correcto, avise a los responsables. También puede verlo en la app: {url}',
    pt: 'Se algo estiver errado, avise os responsáveis. Você também pode ver no app: {url}',
  },
  // 고친 부분
  part_profile: { ko: '기본 정보', en: 'Basic information', es: 'Datos básicos', pt: 'Dados básicos' },
  part_payment: { ko: '입금', en: 'Payment', es: 'Pago', pt: 'Pagamento' },
  part_companions: { ko: '함께 오는 분', en: 'Companions', es: 'Acompañantes', pt: 'Acompanhantes' },
  part_tours: { ko: '투어', en: 'Tours', es: 'Tours', pt: 'Passeios' },
  part_travel: { ko: '항공·숙박', en: 'Flights and lodging', es: 'Vuelos y alojamiento', pt: 'Voos e hospedagem' },
  part_cancel: { ko: '참석 취소', en: 'Cancellation', es: 'Cancelación', pt: 'Cancelamento' },
  // 입금 상태
  pay_pending: { ko: '확인 중', en: 'Being checked', es: 'En revisión', pt: 'Em verificação' },
  pay_confirmed: { ko: '확인됨', en: 'Confirmed', es: 'Confirmado', pt: 'Confirmado' },
  pay_rejected: { ko: '반려됨', en: 'Rejected', es: 'Rechazado', pt: 'Recusado' },
  pay_none: { ko: '아직 없음', en: 'Not yet', es: 'Aún no', pt: 'Ainda não' },
};

export const EDIT_PARTS = ['profile', 'payment', 'companions', 'tours', 'travel', 'cancel'];
const LANGS = ['ko', 'en', 'es', 'pt'];

function t(key, lang, params = {}) {
  const row = T[key];
  const tpl = row[lang] ?? row.en;
  return tpl.replace(/\{(\w+)\}/g, (_, k) => String(params[k] ?? ''));
}

/// 받는 사람의 언어. 앱에서 고른 언어가 먼저다. 없으면 나라로 짐작한다 —
/// 이 수양회는 중남미에서 열리므로 모르는 나라는 스페인어로 둔다.
export function mailLanguage(uiLanguage, country) {
  if (LANGS.includes(uiLanguage)) return uiLanguage;
  const c = String(country ?? '').trim().toUpperCase();
  if (['KR', 'KOREA', 'SOUTH KOREA', '대한민국', '한국'].includes(c)) return 'ko';
  if (['BR', 'BRAZIL', 'BRASIL', 'PT', 'PORTUGAL'].includes(c)) return 'pt';
  if (['US', 'USA', 'UNITED STATES', 'CA', 'CANADA', 'GB', 'UK', 'UNITED KINGDOM',
       'IE', 'IRELAND', 'AU', 'AUSTRALIA', 'NZ', 'DE', 'GERMANY', 'PH', 'PHILIPPINES',
       'IN', 'INDIA'].includes(c)) return 'en';
  return 'es';
}

/// 메일의 제목과 본문(평문).
///
/// reg: { name, program, currency, total, cancelled, companions: [{ name, age }],
///        tours: [이름], arrival, departure, payment: 'pending'|'confirmed'|'rejected'|null }
/// parts: 고친 부분들(EDIT_PARTS 중)
export function composeEditMail({ lang, reg, parts, url }) {
  const L = LANGS.includes(lang) ? lang : 'en';
  const program = reg.program ?? '';
  const changed = EDIT_PARTS.filter((p) => parts.includes(p))
    .map((p) => t(`part_${p}`, L))
    .join(', ');
  const money = reg.total == null
    ? '—'
    : `${reg.currency ?? ''} ${Number(reg.total).toLocaleString('en-US', { maximumFractionDigits: 2 })}`.trim();
  const companions = (reg.companions ?? []).length
    ? reg.companions.map((c) => (c.age == null ? c.name : `${c.name} (${c.age})`)).join(', ')
    : t('none', L);
  const tours = (reg.tours ?? []).length ? reg.tours.join(', ') : t('none', L);
  const pay = t(`pay_${reg.payment ?? 'none'}`, L);

  const lines = [
    t('hello', L, { name: reg.name || '' }),
    '',
    t('intro', L, { program }),
    t('changed', L, { parts: changed }),
    '',
  ];
  if (reg.cancelled) {
    lines.push(t('cancelled', L), '');
  } else {
    lines.push(
      `■ ${t('now', L)}`,
      `- ${t('total', L)}: ${money}`,
      `- ${t('companions', L)}: ${companions}`,
      `- ${t('tours', L)}: ${tours}`,
      `- ${t('arrival', L)}: ${reg.arrival || '—'}`,
      `- ${t('departure', L)}: ${reg.departure || '—'}`,
      `- ${t('payment', L)}: ${pay}`,
      '',
    );
  }
  lines.push(t('outro', L, { url }));
  return { subject: t('subject', L, { program }), text: lines.join('\n') };
}
