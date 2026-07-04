# Android 출시 전 필수 TODO

> 관리 규칙: 작업이 실제로 반영되고 검증까지 끝난 항목만 `[x]`로 변경하고 `완료됨`을 표시한다.

- [ ] **1. Android 패키지 ID 확정 및 변경** — 미완료
  - `com.example.hehe`를 최종 패키지 ID로 변경
  - Android namespace와 `MainActivity` 패키지 경로 변경
  - Firebase Android 앱 및 `google-services.json` 갱신
  - 카카오·네이버 개발자 콘솔의 Android 패키지/키 해시 설정 갱신
  - 변경 후 소셜 로그인과 FCM 동작 검증

- [ ] **2. Play 배포용 release 서명 구성** — 미완료
  - 업로드 키스토어 생성 및 안전하게 별도 보관
  - `key.properties`와 release `signingConfig` 연결
  - 키스토어와 비밀번호 파일이 Git에서 제외되는지 확인
  - Play App Signing 사용 설정
  - release AAB가 debug 인증서가 아닌 업로드 인증서로 서명됐는지 검증

- [ ] **3. 약관·개인정보처리방침·회원탈퇴 연결** — 미완료
  - 서비스 이용약관 공개 URL 준비 및 앱에 연결
  - 개인정보처리방침 공개 URL 준비 및 앱과 Play 스토어 정보에 연결
  - 앱 내부 회원탈퇴 또는 계정 삭제 요청 경로 구현
  - 앱 외부에서도 접근 가능한 계정 삭제 요청 URL 준비
  - Play Console 데이터 보안 및 계정 삭제 항목 작성

- [ ] **4. Android 출시 브랜딩 적용** — 미완료
  - Flutter 기본 런처 아이콘을 HeHe 아이콘으로 교체
  - Android adaptive icon 구성
  - Android 네이티브 스플래시 화면 적용
  - 앱 표시 이름 `hehe`를 최종 표기로 변경
  - 실제 기기에서 라이트·다크 모드 시작 화면 확인

- [x] **5. release 빌드에서 테스트 기능과 민감 로그 제거** — 완료됨 (2026-07-04)
  - 완료됨: 홈 화면의 FCM 테스트 발송 버튼 제거
  - 완료됨: FCM 테스트 API·Repository·DTO 및 엔드포인트 제거
  - 완료됨: 전체 FCM 토큰 및 인증 토큰 값 출력 제거
  - 완료됨: 소스와 release AAB 바이너리에서 테스트 API·토큰 로그 문자열 미검출
  - 검증: `flutter analyze`, 전체 테스트, release AAB 빌드 통과

- [ ] **6. Naver Reverse Geocode secret의 클라이언트 노출 제거** — 앱 작업 완료, 외부 확인 필요
  - 완료됨: 앱에서 Naver Map client ID·secret을 직접 사용하는 구조 제거
  - 완료됨: secret이 필요 없는 OS 네이티브 지오코더로 지역 라벨 기능 이전
  - 완료됨: 좌표별 1일 메모리 캐시와 한국 주소 라벨 정규화 적용
  - 완료됨: 소스와 release AAB 바이너리에서 Naver secret 관련 문자열 미검출
  - 미완료: 기존 Naver Cloud secret을 실제 배포 빌드에 사용한 적이 있다면 콘솔에서 폐기·교체 확인
  - 검증: `flutter analyze`, 전체 테스트, release AAB 빌드 통과

## 최종 출시 검증

- [ ] 위 필수 TODO 6개가 모두 `완료됨` 상태인지 확인
- [ ] `flutter analyze` 통과
- [ ] 전체 테스트 통과
- [ ] 최종 설정으로 release AAB 빌드 성공
- [ ] AAB 서명 인증서·패키지 ID·versionCode 확인
- [ ] Play 내부 테스트 트랙에서 로그인·지도·위치 권한·푸시·회원탈퇴 스모크 테스트
