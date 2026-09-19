// 2027 수양회의 글을 네 언어로 채운다 (071·072)
//
// 번역기 열쇠를 넣기 전에 손으로 한 번 채운다. 양이 적고, 말씀 제목처럼
// 성경 구절에서 온 말은 기계보다 사람이 낫다 — "Apacentad la grey de Dios"
// 는 베드로전서 5:2 이고, 한국어에는 이미 정해진 표현이 있다.
//
// **원문은 건드리지 않는다.** theme_title·fee_basic_desc 같은 칸은 담당자가
// 적은 그대로 두고, 옆의 i18n 칸만 채운다.
//
// 투어 **이름은 옮기지 않는다** — Calafate·Catarata Iguazú 는 지명이라
// 옮기면 오히려 못 찾는다. 설명만 나눈다.
//
// 쓰는 법 — 반드시 확인부터:
//   cd server
//   node scripts/seed-2027-i18n.js          # 무엇이 바뀌는지 보여만 준다
//   node scripts/seed-2027-i18n.js --yes    # 실제로 쓴다
import { sql } from '../src/db.js';

const host = (process.env.DATABASE_URL ?? '').replace(/.*@([^.]+).*/s, '$1');
const apply = process.argv.includes('--yes');

// 베드로전서 5:2. **각 언어의 성경 표현을 그대로 쓴다.**
//
// 스페인어 원문이 RVR1960("Apacentad la grey de Dios")이므로 결이 같은 판을
// 고른다 — 영어는 KJV, 포르투갈어는 ARA, 한국어는 개역개정이다. 뜻만 맞는
// 말을 새로 지으면 성경에서 온 제목이 아니라 우리가 지은 표어가 된다.
const THEME_TITLE = {
  ko: '하나님의 양 무리를 치라',
  en: 'Feed the flock of God',
  es: 'Apacentad la grey de Dios',
  pt: 'Apascentai o rebanho de Deus',
};

const THEME_VERSE = {
  ko: '베드로전서 5:2a',
  en: '1 Peter 5:2a',
  es: '1Pedro 5:2a',
  pt: '1Pedro 5:2a',
};

const FEE_BASIC = {
  ko: '2027년 1월 21일 점심부터 24일 저녁까지 · 숙박(1월 21~23일) 포함',
  en: 'From lunch on 21 to dinner on 24 January 2027 · lodging (21–23 Jan) included',
  es: 'desde almuerzo de 21 hasta cena de 24 de Enero, 2027,  hospedaje (desde 21-23. Enero) está incluido',
  pt: 'Do almoço de 21 ao jantar de 24 de janeiro de 2027 · hospedagem (21–23 jan) incluída',
};

const FEE_PREMIUM = {
  ko: '부부실',
  en: 'Double room for couples',
  es: 'Habitación matrimonial',
  pt: 'Quarto de casal',
};

// 투어 설명. 이름으로 찾는다 — id 는 수양회마다 다르다.
const TOUR_DESC = {
  Calafate: {
    ko: '비행기 티켓 가격 미 포함.',
    en: 'Airfare not included.',
    es: 'No incluye el pasaje aéreo.',
    pt: 'Passagem aérea não incluída.',
  },
};

const [program] = await sql`
  SELECT id, name, theme_title, theme_verse, fee_basic_desc, fee_premium_desc
    FROM programs WHERE name LIKE 'La Conferencia%' AND is_active = true
   LIMIT 1`;

if (!program) {
  console.log('수양회를 못 찾았습니다.');
  process.exit(1);
}

console.log(`DB ${host}\n수양회: ${program.name.slice(0, 50)}\n`);
console.log('채울 것:');
console.log('  말씀 제목      ', Object.keys(THEME_TITLE).join(' '));
console.log('  성경 본문      ', Object.keys(THEME_VERSE).join(' '));
console.log('  기본 등급 설명 ', Object.keys(FEE_BASIC).join(' '));
console.log('  프리미엄 설명  ', Object.keys(FEE_PREMIUM).join(' '));

const tours = await sql`
  SELECT id, name FROM program_options
   WHERE program_id = ${program.id} AND is_active = true`;
const hits = tours.filter((t) => TOUR_DESC[t.name]);
for (const t of hits) {
  console.log(`  투어 설명      ${t.name} — ${Object.keys(TOUR_DESC[t.name]).join(' ')}`);
}

if (!apply) {
  console.log('\n실제로 쓰려면 --yes 를 붙이십시오. 아무것도 안 바꿨습니다.');
  process.exit(0);
}

await sql.transaction(async (client) => {
  await client.query(
    `UPDATE programs SET
       theme_title_i18n = $2::jsonb,
       theme_verse_i18n = $3::jsonb,
       fee_basic_desc_i18n = $4::jsonb,
       fee_premium_desc_i18n = $5::jsonb
     WHERE id = $1`,
    [
      program.id,
      JSON.stringify(THEME_TITLE),
      JSON.stringify(THEME_VERSE),
      JSON.stringify(FEE_BASIC),
      JSON.stringify(FEE_PREMIUM),
    ],
  );
  for (const t of hits) {
    await client.query(
      'UPDATE program_options SET description_i18n = $2::jsonb WHERE id = $1',
      [t.id, JSON.stringify(TOUR_DESC[t.name])],
    );
  }
});

console.log('\n채웠습니다. 원문 칸은 건드리지 않았습니다.');
process.exit(0);
