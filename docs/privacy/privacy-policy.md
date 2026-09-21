# Tokenfront: Orbital Signal War Privacy Policy

## Forthcoming monetization — DRAFT, disabled; publication pending

Applies only to a future version after 1.2.0; no effective date has been approved. Shipped 1.2.0 has no login or purchase flow. The implementation in this working tree is disabled, the backend is not deployed, and the Play product is not created. The 1.2.0 policy below remains separately scoped; its no-account statements must not be reused for an enabled release.

Google sign-in would be optional for gameplay and required to buy or restore the proposed one-time remove-ads purchase (KRW 3,900, subject to Play product/price setup). It removes banners and interstitials, not optional rewarded ads. Restore uses the same Google identity plus Google Play purchase verification; it does not upload or synchronize game progress.

The app would send a fresh Google ID token and server challenge over HTTPS to Toris’s Cloudflare Workers backend. The backend verifies Google signatures, audience and nonce, and checks purchases with Google Play. Cloudflare would process these requests and store billing records in D1; Google processes authentication and payment/verification under its own terms. A stable hash of Google issuer/subject and a random purchase-account binding link records across reinstalls/devices. These are **pseudonymous, NOT anonymous**, account identifiers. The backend does not persist the raw Google subject, email or profile. ID tokens are exchanged transiently; billing sessions stay in app memory for up to 15 minutes, without a stored Google refresh token.

D1 would store account identifiers/binding, product ID, purchase-token hash and AES-256-GCM encrypted purchase token, order ID, active/terminal status, verification and next-check timestamps, and reconciliation/abuse-control records. Only the purchase token has application-level encryption in this schema; do not claim that order/status fields are similarly encrypted. Tokens are decrypted for repeat verification/refund checks. Cloudflare also processes network metadata, with a hashed IP used for edge rate limiting. Payment-card details are handled by Google Play, not this billing database.

The app would locally cache a signed remove-ads entitlement, account binding and clock high-water mark. The signed grant expires 30 days after the last positive Google verification; it is not a lifetime offline grant or an API credential. Offline refund/revocation visibility may be delayed until expiry. Logout/account switching invalidates the in-memory grant and attempts local cache removal (storage failures may leave an old signed cache usable until its original expiry); clearing app storage/uninstalling removes local data, **not backend billing records**. Neither action is account deletion.

**Release blockers:** no account/data-deletion endpoint or operational deletion workflow exists, and retention periods for account/purchase records, logs and backups have not been approved or implemented. The 30-day grant lifetime is not a backend retention period. Before enabling login/sales, define retention and legal exceptions, implement authenticated deletion and any required in-app/web request mechanism, test identity verification and deletion effects on restore/refunds/backups, and approve/publish revised policies and Console disclosures. Do not promise deletion completion or a response deadline.

Draft inquiry route only: email the existing public contact **korea@toris.kr** with subject “Tokenfront privacy / deletion inquiry” and describe the request; do not send passwords, ID/session tokens or purchase tokens. This is not an operational account-deletion service or a verified deletion URL. Public contact and policy URLs are unchanged; ownership/routing must be confirmed before launch.

## 차기 수익화 기능 — 초안, 비활성화; 공개 대기

1.2.0 이후 차기 버전에만 적용할 초안이며 시행일은 미승인입니다. 출시된 1.2.0에는 로그인·구매 기능이 없습니다. 작업 트리의 구현은 비활성화 상태이고 백엔드는 미배포, Play 상품은 미생성입니다. 아래 1.2.0 방침의 계정 없음 설명은 기능 활성화 버전에 적용되지 않습니다.

게임 이용에는 Google 로그인이 선택 사항이지만, 제안된 일회성 광고 제거 구매(3,900원, Play 상품·가격 설정 필요)와 복원에는 필요합니다. 배너·전면 광고를 제거하며 선택형 보상 광고는 유지됩니다. 동일 Google 계정과 Google Play 구매 검증으로 복원하며 게임 진행은 업로드·동기화하지 않습니다.

앱은 Google ID 토큰과 서버 챌린지를 HTTPS로 Toris의 Cloudflare Workers 백엔드에 보내고, 백엔드는 Google 서명·대상·nonce 및 Google Play 구매를 검증합니다. Cloudflare는 요청 처리와 D1 저장을, Google은 자체 약관에 따른 인증·결제·구매 검증을 담당합니다. Google 발급자/사용자 ID의 안정적 해시와 무작위 구매 계정 연결값으로 재설치·다른 기기의 기록을 연결합니다. 이는 **가명 식별자이며 익명 정보가 아닙니다**. 원본 Google 사용자 ID, 이메일, 프로필은 백엔드에 보관하지 않습니다. ID 토큰은 일시적으로 교환하며, 최대 15분의 결제 세션은 앱 메모리에만 두고 Google 갱신 토큰은 저장하지 않습니다.

D1에는 계정 식별자·연결값, 상품 ID, 구매 토큰 해시 및 AES-256-GCM 암호화 구매 토큰, 주문 ID, 활성·종료 상태, 검증·다음 확인 시각, 재검증·남용 방지 기록이 저장됩니다. 이 스키마에서 애플리케이션 수준으로 암호화하는 것은 구매 토큰이며 주문·상태 필드까지 같은 방식으로 암호화한다고 주장하지 않습니다. 환불 등 재검증 시 토큰을 복호화합니다. Cloudflare는 네트워크 메타데이터도 처리하며 IP 해시를 요청 제한에 사용합니다. 카드 정보는 Google Play가 처리하고 이 결제 DB에는 저장하지 않습니다.

기기에는 서명된 광고 제거 권한, 계정 연결값과 시계 확인값을 저장합니다. 권한은 마지막 Google 정상 검증 후 30일에 만료하며 평생 오프라인 권한이나 API 인증 수단이 아닙니다. 오프라인에서는 환불·철회 반영이 만료까지 지연될 수 있습니다. 로그아웃·계정 전환은 메모리 권한을 무효화하고 로컬 캐시 삭제를 시도합니다. 저장 실패 시 기존 서명 캐시가 원래 만료일까지 다시 사용될 수 있습니다. 앱 데이터 삭제·제거는 로컬 데이터만 삭제하며 서버 결제 기록이나 계정을 삭제하지 않습니다.

**출시 차단 조건:** 계정·데이터 삭제 엔드포인트와 운영 절차가 없고 계정·구매 기록, 로그·백업 보유 기간도 승인·구현되지 않았습니다. 권한의 30일 유효기간은 서버 보유 기간이 아닙니다. 로그인·판매 활성화 전에 보유 기간·법적 예외, 본인 확인과 삭제 절차, 필요한 앱 내·웹 요청 수단을 구현하고 복원·환불·백업에 대한 영향을 검증하며 방침·Console 공개 정보를 승인·게시해야 합니다. 삭제 완료나 처리 기한은 약속하지 않습니다.

문의 경로 초안: 기존 공개 연락처 **korea@toris.kr**로 제목 “Tokenfront 개인정보 / 삭제 문의”와 요청 내용을 보내세요. 비밀번호, ID·세션 토큰, 구매 토큰은 보내지 마세요. 이는 운영 중인 계정 삭제 서비스나 검증된 삭제 URL이 아닙니다. 기존 공개 연락처·정책 URL은 유지하며 출시 전 담당·전달 경로 확인이 필요합니다.

## Shipped 1.2.0 policy / 출시된 1.2.0 방침

The historical effective date below is not the effective date of the draft above. / 아래 기존 시행일은 위 초안의 시행일이 아닙니다.

Effective date: August 5, 2026

Tokenfront: Orbital Signal War (the “App”) is provided by Toris. This policy explains how the release covered by this policy handles information.

## Summary

The App is an offline game. Gameplay and local progress stay on the device. Debug and profile builds use Google Mobile Ads test units; signed release builds use the configured Tokenfront production app and ad-unit IDs. When ad requests are enabled and consent permits, Google may process ad requests, device information, diagnostics, and advertising identifiers under Google's terms.

## Information stored on your device

The App stores game progress and settings only on your device. This may include your War Token balance, unlocked and equipped cosmetic items, language, accessibility, camera, haptics, audio, local privacy choices, Signal Chronicle progress, medals, transmissions, endings, and directive-bonus history.

This information is not sent to Toris or any third party. AdMob is a separate advertising flow described below. Android automatic cloud backup is disabled; backup rules exclude local game state on Android 11 and lower and exclude it from cloud backup and device-to-device transfer on Android 12+. Clearing the App’s data or uninstalling the App removes this local information. In the web version, you can remove it by clearing the site’s local storage.

## Analytics and advertising choices

Analytics remains unavailable in this release. Android ad requests are optional and consent-gated. Use Settings → AD PRIVACY OPTIONS to revisit the Google privacy form when it is required. Gameplay and performance events may be held temporarily in memory during a session, but they are not transmitted and are discarded when the App process ends.

## Data collection and sharing

- Personal data collected off device: AdMob may process ad-request/device data when ads are enabled
- Data shared with third parties: Google Mobile Ads data as described by Google
- Accounts or cloud profiles: none
- Precise location, contacts, photos, camera, or microphone access: none
- Advertising identifiers: may be processed by AdMob when consent and ad requests permit

## Data retention and deletion

Toris does not retain gameplay or local-state data on a server. Google Mobile Ads may retain advertising/request data under Google’s terms. You control locally stored progress and settings. Clear the App’s storage or uninstall it to delete them.

## Public policy hosting

The complete policy is readable in the App and its URL is visible and copyable. Opening `https://tokenfront-orbital-war.pages.dev/privacy.html` is an explicit external-browser action. Cloudflare Pages and the external browser may process ordinary web-request data, such as IP address and routing data, under their own terms. The Android App does not embed this page and does not send gameplay or local-state data to it.

## Children’s privacy

The App is intended for players aged 13 and older and is not directed to children under 13. The App does not knowingly collect children’s personal information; Google Mobile Ads processing is governed by the consent flow and Google’s terms. If a future version changes these practices, this policy and the relevant store disclosures will be updated before that version is released.

## Security

Keeping gameplay data on your device reduces exposure; advertising is a separate network data flow. No method of storage is completely secure, so keep your device and operating system protected.

## Changes to this policy

This policy may be updated when the App’s features or legal requirements change. The effective date above will be revised, and material changes will be disclosed before the affected version is released.

## Contact

Toris

Email: korea@toris.kr

---

# AI 전쟁 시뮬레이터 개인정보처리방침

시행일: 2026년 8월 5일

Toris가 제공하는 AI 전쟁 시뮬레이터(이하 “앱”)의 이 방침 적용 대상 릴리스가 정보를 처리하는 방식을 안내합니다.

## 요약

앱은 오프라인 게임입니다. 디버그·프로필 빌드는 Google Mobile Ads 테스트 단위를 사용하고, 서명된 릴리스 빌드는 설정된 Tokenfront 운영 앱·광고 단위 ID를 사용합니다. 광고 요청을 켜고 동의 절차가 허용하면 Google이 광고 요청, 기기 정보, 진단 정보 및 광고 식별자를 처리할 수 있습니다.

## 기기에 저장되는 정보

앱은 게임 진행 상태와 설정만 사용자의 기기에 저장합니다. 여기에는 War Token 잔액, 해제·장착한 꾸미기 항목, 언어, 접근성, 카메라, 햅틱, 오디오, 로컬 개인정보 선택, Signal Chronicle 진행 상태, 메달, 전송 기록, 엔딩 및 지령 보너스 기록이 포함될 수 있습니다.

이 정보는 Toris 또는 제3자에게 전송되지 않습니다. AdMob은 아래에 설명한 별도의 광고 흐름입니다. Android 자동 클라우드 백업은 비활성화되어 있으며, 백업 규칙은 Android 11 이하의 로컬 게임 상태와 Android 12 이상에서의 클라우드 백업 및 기기 간 전송을 제외합니다. Android에서는 앱 데이터를 삭제하거나 앱을 제거하면 로컬 정보가 삭제됩니다. 웹 버전에서는 해당 사이트의 로컬 저장소를 삭제할 수 있습니다.

## 분석 및 광고 선택

분석 전송은 이 릴리스에서 사용할 수 없습니다. Android 광고 요청은 선택 사항이며 동의 절차로 제한됩니다. 게임플레이 및 성능 이벤트가 세션 중 메모리에 일시적으로 보관될 수 있으나 외부로 전송되지 않고 앱 프로세스가 종료되면 삭제됩니다.

## 데이터 수집 및 공유

- 기기 외부로 수집하는 개인정보: 광고 요청이 켜져 있으면 AdMob이 광고 요청·기기 데이터를 처리할 수 있음
- 제3자와 공유하는 데이터: Google Mobile Ads가 Google 설명에 따라 처리하는 데이터
- 계정 또는 클라우드 프로필: 없음
- 정밀 위치, 연락처, 사진, 카메라 또는 마이크 접근: 없음
- 광고 식별자: Android AD_ID 권한 제거 여부를 최종 AAB에서 확인하며, 기타 광고 요청·기기 데이터는 별도 광고 설명에 따름

## 보유 및 삭제

Toris는 게임플레이 또는 로컬 상태 데이터를 서버에 보유하지 않습니다. Google Mobile Ads는 Google 약관에 따라 광고·요청 데이터를 보유할 수 있습니다. 로컬 진행 상태와 설정은 이용자가 관리합니다. 앱 저장공간을 삭제하거나 앱을 제거하면 해당 정보가 삭제됩니다.

## 공개 정책 페이지 호스팅

전체 방침은 앱에서 읽을 수 있고 URL을 보고 복사할 수 있습니다. `https://tokenfront-orbital-war.pages.dev/privacy.html`을 여는 것은 이용자가 외부 브라우저에서 명시적으로 수행하는 동작입니다. Cloudflare Pages와 외부 브라우저는 자체 조건에 따라 IP 주소와 라우팅 정보 등 일반적인 웹 요청 데이터를 처리할 수 있습니다. Android 앱은 이 페이지를 내장하지 않으며 게임플레이나 로컬 상태 데이터를 보내지 않습니다.

## 아동의 개인정보

앱은 만 13세 이상 이용자를 대상으로 하며 만 13세 미만 아동을 대상으로 하지 않습니다. 광고 관련 데이터 처리는 위의 광고 설명과 Google 약관 및 동의 절차에 따릅니다. 향후 버전에서 처리 방식이 바뀌는 경우 해당 버전을 출시하기 전에 이 방침과 관련 스토어 공개 정보를 업데이트합니다.

## 보안

게임 진행 정보를 기기에 보관하여 노출 가능성을 줄이며 광고는 별도의 네트워크 데이터 흐름입니다. 다만 어떠한 저장 방식도 완전한 보안을 보장할 수 없으므로 기기와 운영체제를 안전하게 유지해 주세요.

## 방침 변경

앱 기능 또는 관련 법적 요구사항이 변경되면 이 방침을 업데이트할 수 있습니다. 상단 시행일을 수정하고 중요한 변경은 해당 버전 출시 전에 안내합니다.

## 문의

Toris

이메일: korea@toris.kr
