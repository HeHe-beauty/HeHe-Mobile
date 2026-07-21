# Android 출시 TODO

> 완료된 코드·빌드 작업은 이 문서에서 제거한다. 아래에는 Play Console/외부 서비스에서 직접 해야 하는 일과 실기기 확인만 남긴다.
>
> 현재 내부 테스트용 산출물: `1.0.4 (versionCode 5)`, `build/app/outputs/bundle/release/app-release.aab`

## P0 — 내부 테스트 핵심 기능 확인

- [ ] **네이버 로그인 서비스 검수 요청**
  - 내부 테스트 설치본에서 네이버 로그인과 로그아웃은 확인을 완료했다.
  - 프로덕션 출시 전에 Naver Developers에서 네이버 로그인 서비스 적용/검수를 요청한다.

- [ ] **로그인 이후 핵심 흐름 확인**
  - 최초 가입 동의 → 로그인 → 앱 재실행 후 세션 복원
  - 알림 비동의/동의, Android 알림 권한, FCM 수신, 야간·마케팅 동의 변경
  - 지도·현재 위치 권한·병원 상세·전화 연결·찜·최근 본 병원
  - 일정 생성/수정/삭제와 방문 전 알림
  - 이용약관·개인정보처리방침·계정 삭제 안내 링크
  - 재인증 후 회원탈퇴

- [ ] **내부 테스트 결과 전달**
  - 위 항목이 통과하면 알려준다. 프로덕션 번들에서는 진단 코드 표시를 끄고 `versionCode 5`보다 큰 최종 AAB를 생성해야 한다.

## P1 — Play Console 앱 콘텐츠 작성

- [ ] **콘텐츠 등급 설문 제출**
  - 현재 17세 표시는 설문이 완료되지 않은 상태에서 보인 임시/미확정 표시다.
  - Play Console의 앱 콘텐츠에서 실제 앱 내용에 맞게 IARC 설문을 끝까지 제출하고 결과를 확인한다.

- [ ] **정책 및 앱 액세스 항목 완료**
  - 타겟층 및 콘텐츠, 광고 포함 여부, 건강 관련 기능 여부를 정확히 작성한다.
  - 개인정보처리방침 URL: `https://www.hehehe.kr/privacy`
  - 계정 삭제 URL: `https://www.hehehe.kr/account-deletion`

- [ ] **Google Play 심사용 소셜 계정 준비 및 로그인 세부정보 등록**
  - 개인 계정이 아닌 Google 심사 전용 카카오·네이버 계정을 만든다. 실제 개인정보나 이용 기록은 넣지 않는다.
  - 카카오 앱이 개발 상태라면 심사용 카카오 계정을 개발자 테스트 가능 계정으로 등록한다.
  - 네이버 앱이 개발 상태라면 심사용 네이버 계정을 로그인 테스트 ID/멤버로 등록한다.
  - 각 심사용 계정으로 HeHe 회원가입과 필수 동의를 미리 완료하여 로그인 제한 기능 전체에 접근할 수 있게 한다.
  - 해외의 새 기기에서도 반복 사용할 수 있도록 2단계 인증, 문자 인증, OTP 및 만료되는 인증 절차가 나타나지 않게 한다.
  - Play 내부 테스트 설치본에서 로그아웃 상태로 시작하여 아래 계정과 안내만으로 로그인이 가능한지 검증한다.
  - Play Console 로그인 세부정보에 카카오 계정을 다음과 같이 영어로 등록한다.
    - 이름: `Kakao review account`
    - 사용자 이름: 심사용 카카오 계정 이메일
    - 비밀번호: 심사용 카카오 계정 비밀번호
    - 앱 액세스에 필요한 기타 정보:

      ```text
      1. Launch the app.
      2. Tap the profile icon in the top-right corner.
      3. Tap the yellow Kakao login button.
      4. On the Kakao sign-in page, enter the email address and password provided above.
      5. If a consent screen appears, tap "동의하고 계속하기" (Agree and continue).

      This account is already registered with HeHe and provides access to all login-restricted features. No OTP or two-step verification is required. The app interface is currently provided in Korean.
      ```

  - Play Console 로그인 세부정보에 네이버 계정을 별도 항목으로 다음과 같이 영어로 등록한다.
    - 이름: `Naver review account`
    - 사용자 이름: 심사용 네이버 ID 또는 이메일
    - 비밀번호: 심사용 네이버 계정 비밀번호
    - 앱 액세스에 필요한 기타 정보:

      ```text
      1. Launch the app.
      2. Tap the profile icon in the top-right corner.
      3. Tap the green Naver login button.
      4. On the Naver sign-in page, enter the username and password provided above.
      5. Complete the consent step if it is displayed.

      This account is already registered with HeHe and provides access to all login-restricted features. No OTP or two-step verification is required.
      ```

  - API 키, 네이티브 앱 키, Client ID/Secret 또는 액세스 토큰은 Play Console 로그인 정보에 입력하지 않는다.
  - 계정으로 모든 로그인 제한 기능에 실제로 접근되는 것을 확인한 뒤에만 전체 액세스 제공 확인란을 선택한다.

- [ ] **데이터 보안 섹션 작성**
  - 전송되는 위치 정보(주변 병원 조회), 계정/소셜 로그인 정보, 일정·찜·최근 본 병원·문의 활동, FCM 토큰을 실제 서버 처리 방식과 대조한다.
  - 전송 중 암호화, 데이터 삭제 요청, 필수/선택 수집 여부를 개인정보처리방침 및 서버 동작과 일치시킨다.

- [ ] **개발자 및 스토어 등록정보 완료**
  - 앱 카테고리, 개발자 표시명, 문의 이메일/웹사이트를 앱과 법률 문서의 정보와 일치시킨다.
  - 앱 이름·짧은 설명·전체 설명·512×512 아이콘·1024×500 그래픽·휴대전화 스크린샷을 등록한다.

## P2 — 비공개 테스트 및 프로덕션 접근

- [ ] 새 개인 개발자 계정에 해당하면 비공개 테스트에 12명 이상을 초대하고 14일 연속 참여 상태를 유지한다.
- [ ] 내부 테스트 참여자는 비공개 테스트 참여 전에 내부 테스트를 선택 해제하고 비공개 테스트에 다시 참여하게 한다.
- [ ] 비공개 테스트 피드백과 Play 사전 출시 보고서의 크래시·ANR·호환성 결과를 확인한다.
- [ ] 요건 충족 후 프로덕션 액세스를 신청한다.

## P3 — 최종 배포

- [ ] 내부/비공개 테스트 결과와 네이버 검수가 끝난 뒤 최종 프로덕션 AAB 생성을 요청한다.
- [ ] 최종 AAB의 `versionCode`가 모든 테스트 트랙보다 큰지 확인하고 프로덕션 트랙에 업로드한다.
- [ ] 검토 제출 전 스토어 정보·콘텐츠 등급·데이터 보안·법률 문서 답변이 서로 일치하는지 최종 확인한다.
- [ ] 단계적 출시 후 실제 Play 설치본에서 로그인, 지도, 알림, 약관 링크, 회원탈퇴를 다시 확인한다.
