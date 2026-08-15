// 환율 (054)
//
// 장부는 현지 통화로 적고 수양회 통화로 합계를 낸다. 그 사이를 잇는 값이다.
//
// **아르헨티나는 환율이 하나가 아니다.** 공식과 블루가 하루에도 따로 움직이고,
// 현장에서 실제로 바꾸는 것은 블루다 — 공식 환율로 셈하면 장부가 실제와
// 20% 넘게 벌어진다. 그래서 ARS 는 dolarapi 의 블루를 쓰고, 나머지 통화는
// 일반 환율표를 쓴다.
//
// 가져온 값은 **고칠 수 있는 기본값**이다. 그날 실제로 바꾼 환율이 이것과
// 다를 수 있고, 그때는 담당자가 적은 값이 맞다.

const BLUE_URL = 'https://dolarapi.com/v1/dolares/blue';
const RATES_URL = 'https://open.er-api.com/v6/latest/USD';

// 한 시간에 한 번만 물어본다. 장부를 적을 때마다 바깥에 나가면 화면이 느려지고,
// 환율은 그 사이에 장부를 뒤집을 만큼 움직이지 않는다.
const TTL_MS = 60 * 60 * 1000;
const cache = new Map();

function fresh(key) {
  const hit = cache.get(key);
  if (!hit) return null;
  if (Date.now() - hit.at > TTL_MS) return null;
  return hit.value;
}

async function fetchJson(url) {
  // 환율을 못 가져와도 장부는 적을 수 있어야 한다. 던지지 않는다.
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(6000) });
    if (!res.ok) return null;
    return await res.json();
  } catch (err) {
    console.error('환율 조회 실패:', url, err.message);
    return null;
  }
}

/// 아르헨티나 블루. 파는 값(venta)을 쓴다 — 달러를 페소로 바꿔 쓰는 쪽이
/// 우리 처지이기 때문이다.
export async function blueRate() {
  const hit = fresh('blue');
  if (hit) return hit;
  const body = await fetchJson(BLUE_URL);
  const venta = Number(body?.venta);
  if (!Number.isFinite(venta) || venta <= 0) return null;
  const value = {
    currency: 'ARS',
    rate: venta,
    source: 'blue',
    at: body?.fechaActualizacion ?? null,
  };
  cache.set('blue', { at: Date.now(), value });
  return value;
}

/// 그 밖의 통화. 1 달러당 얼마인지.
export async function marketRate(currency) {
  const code = String(currency ?? '').toUpperCase();
  if (!/^[A-Z]{3}$/.test(code)) return null;
  if (code === 'USD') return { currency: 'USD', rate: 1, source: 'same' };

  const hit = fresh('rates');
  let rates = hit;
  if (!rates) {
    const body = await fetchJson(RATES_URL);
    rates = body?.rates ?? null;
    if (rates) cache.set('rates', { at: Date.now(), value: rates });
  }
  const r = Number(rates?.[code]);
  if (!Number.isFinite(r) || r <= 0) return null;
  return { currency: code, rate: r, source: 'market' };
}

/// 이 통화를 어디서 가져올지 정한다.
export async function rateFor(currency) {
  const code = String(currency ?? '').toUpperCase();
  if (code === 'ARS') {
    // 블루가 안 오면 일반 환율이라도 준다 — 공식 환율이 맞지 않더라도
    // 아무 값도 못 주는 것보다는 낫고, 담당자가 고칠 수 있다.
    return (await blueRate()) ?? (await marketRate('ARS'));
  }
  return marketRate(code);
}

/// 현지 금액을 수양회 통화로. 소수점 둘째 자리까지.
///
/// rate 는 **1 수양회통화당 현지 통화** 다. 640000 페소를 1545 로 나누면
/// 414.24 달러.
export function toBase(localAmount, rate) {
  const a = Number(localAmount);
  const r = Number(rate);
  if (!Number.isFinite(a) || a <= 0) return null;
  if (!Number.isFinite(r) || r <= 0) return null;
  return Math.round((a / r) * 100) / 100;
}
