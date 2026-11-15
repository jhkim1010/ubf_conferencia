// 참석 취소 이유(076). DB 없이 시험할 수 있게 따로 둔다.
//
// 짧게 받는다. 담당자 명단의 한 칸과 텔레그램 한 줄에 보이는 글이다.
export function normalizeCancelReason(v) {
  if (typeof v !== 'string') return null;
  const t = v.trim().slice(0, 500);
  return t === '' ? null : t;
}
