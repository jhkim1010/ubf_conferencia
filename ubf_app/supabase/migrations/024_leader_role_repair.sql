-- 리더인데 역할이 participant 로 남은 계정 복구
--
-- 인앱 "리더로 전환하기" 는 leaders 행만 만들고 users.role 은 건드리지
-- 않았다. 화면은 role 로 홈을 고르므로, 그런 계정은 앱을 다시 켜면 참가자
-- 홈으로 떨어져 자기가 만든 수양회에 들어갈 수 없었다. 재등록도
-- "이미 리더입니다"(400)로 막혀 빠져나올 방법이 없었다.
--
-- 앞으로는 /leaders/register 가 role 을 함께 올린다. 이 구문은 이미 그
-- 상태에 빠져 있는 기존 계정을 되돌린다.
--
-- 멱등하다: 두 번 돌려도 두 번째는 대상이 없어 0행이다.
-- director 는 조건에서 제외되므로 강등되지 않는다.
UPDATE users
   SET role = 'admin', updated_at = NOW()
 WHERE role = 'participant'
   AND EXISTS (SELECT 1 FROM leaders l WHERE l.user_id = users.id);
