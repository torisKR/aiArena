# Tokenfront: Orbital Signal War

Flutter + Flame으로 만든 오프라인 싱글플레이 전쟁 시뮬레이션입니다. Amethyst, Cobalt, Volt, Prism 네 진영이 각각 1,000개 유닛으로 시작해 총 4,000개 유닛이 실시간으로 싸웁니다. 플레이어가 조종하던 유닛이 쓰러져도 같은 진영이 생존해 있으면 지휘권과 카메라가 다음 유닛으로 이어집니다.

상용 화면과 결정론적 시뮬레이션 모두 타사 상표와 혼동되지 않는 중립 진영명을 사용합니다.

## 구현 범위

### 전투와 조작

- 4개 진영 × 1,000개, 총 4,000개 유닛과 진영별 동일한 Lv.1–10 분포
- 고정 30Hz 전투 시뮬레이션, 일반 AI 10–15Hz 의사결정, `SpatialGrid` 기반 근접 탐색
- 조종 유닛에서 멀리 떨어진 타깃 없는 `Seek` 유닛만 약 5Hz로 낮추고, 근거리·추적·교전 유닛은 10–15Hz를 유지
- 화면 경계와 96 월드 단위 여백 밖의 생존 유닛은 렌더링에서 제외하고, 매치 시작 때 만든 4,000개 `Unit` 객체는 사망 뒤에도 고정 풀 안에서 유지
- 높은 레벨의 확정 승리, 동레벨의 시드 기반 50/50 판정, 교전 잠금과 회복 시간
- 추적·회피·분리 조향과 진영별 랠리 포인트
- 15분 제한과 생존 수 → 생존 레벨 합 → 처치 수 순의 종료 판정
- 기본 이동속도 64, 모바일 조이스틱·대시, 웹/데스크톱 WASD·방향키·Space; 모바일 가로 화면은 104dp 조이스틱과 72dp 대시 터치 영역을 사용하고, HUD 포커스 이동 뒤에도 키 해제가 동기화되며 화면 회전 시 남은 입력을 즉시 해제
- 더 가까운 전투 카메라, 마우스 드래그·휠 줌, 조종 유닛 추적과 완만한 밀집도 자동 줌
- 우측 하단 전술 미니맵에서 네 진영·현재 viewport·조종 유닛을 확인하고 탭/드래그로 전장을 탐색
- 사망 후 정확한 1.5초 지휘 승계: 히트스톱, 0.5배 슬로모션, 후계 점수 계산, 곡선 카메라 이동, 강조 링, 정상 속도 복귀
- 후계 점수는 레벨 50%, 적과의 안전거리 30%, 비전투 상태 20%를 사용
- 실시간 HUD, 네 진영 생존 수, 남은 시간, 현재 Lv./처치/승계 수, 관전자 상태

### 화면, 설정, 접근성

- 반응형 로비·전투 HUD·결과 화면과 앱 비활성화 시 자동 일시정지/재개
- 논리 디스플레이 최단변이 600dp 미만인 Android/iOS 및 Web은 전투 진입 시 양쪽 가로 방향을 best-effort로 요청하고, 세로 레이아웃에서는 전투 렌더링과 입력을 차단합니다. 전투 종료·로비 복귀·앱 루트 해제 시 플랫폼 기본 방향으로 복원하며, 600dp 이상 화면과 기타 데스크톱 플랫폼에는 요청하지 않습니다.
- 영어를 기준으로 한국어·일본어·중국어(간체)를 지원하며, 기기 언어 자동 감지와 앱 내 언어 선택을 모두 제공
- 선택한 언어는 로컬 설정에 저장되어 재실행 뒤에도 유지
- 시스템 설정과 앱 설정을 함께 따르는 Reduce Motion
- 키보드 포커스 표시, Tab 탐색 보존, 스크린리더용 상태·조작 의미 정보
- Low-spec 모드: 장식 효과·그리드·전투 플래시·HUD 갱신량을 줄이고 과도한 줌아웃을 제한
- 마우스 카메라, 오디오, 햅틱, 분석 공유, 광고 요청을 각각 켜고 끄는 설정
- 전투 중 광고 요청과 조작권 승계 중 끼어드는 광고를 차단하는 정책 경계

### 아트, 오디오와 꾸미기

- Blender MCP로 만든 256×64 런타임 토큰 아틀라스에서 진영별 64×64 셀을 샘플링하며, 로딩 실패 시 절차적 벡터 토큰으로 안전하게 대체
- Blender 장면에서 렌더한 1440×900 키 아트를 로비에 사용
- `dash.wav`, `impact.wav`, `relay.wav`는 외부 녹음 없이 프로젝트용으로 직접 만든 짧은 WAV 신호음
- Flame Audio의 크기가 제한된 `AudioPool`을 사용하며, 전투음은 동시 재생과 호출 빈도를 제한
- 오디오 로딩이나 재생 실패가 전투를 중단하지 않으며 설정에서 완전히 끌 수 있음
- War Token 기본 보상, 결과 화면의 보상형 추가 지급, 중복 지급 방지 흐름 구현
- Signal Locker에서 지휘 외곽색, 이동 흔적, 사망 효과만 해금·장착 가능하며 전투 능력치는 바뀌지 않음
- 지갑·해금·장착, 성능·입력·오디오 설정, 분석·광고 선택은 버전된 로컬 스냅샷으로 재실행 뒤에도 복원됩니다. 저장은 기기·브라우저 단위이며 계정 동기화, 서버 원장, IAP는 연결되어 있지 않습니다.

## 광고·분석 어댑터 상태

광고 배치와 보상 처리는 구현되어 있지만 실제 광고 네트워크 SDK는 포함하지 않습니다.

- 기본 실행은 `NoOpAdService`를 사용하므로 광고 인벤토리를 요청하거나 표시하지 않습니다.
- `FakeAdService`는 배너·전면·보상형 성공, 실패, 예외 상황을 결정론적으로 검증하는 테스트/개발용 어댑터입니다.
- `PolicyAdService`는 배너를 로비·결과로 제한하고, 전면 광고를 결과 화면을 닫은 뒤 최대 2경기당 1회로 제한하며, 보상형 광고를 결과 화면으로 제한합니다.
- 오프라인, 동의 거부, ATT 상태, 어댑터 오류는 값으로 처리되어 매치 시작·결과·기본 보상을 막지 않습니다.
- `DOUBLE REWARD`는 데모 버튼이 아니라 실제 보상 처리 경로입니다. 다만 기본 NoOp 빌드에서는 “광고 없음”으로 안전하게 종료되고, Fake 어댑터 테스트에서는 광고 완료 후 추가 War Token이 한 번만 지급됩니다.
- 라이브 AdMob/H5 Games Ads를 사용하려면 퍼블리셔 ID, 광고 단위 ID, 플랫폼 SDK 기반 `AdService` 구현과 스토어 동의 문구를 별도로 연결해야 합니다.

분석 이벤트도 타입이 있는 로컬 버퍼와 개인정보 게이트까지 구현되어 있습니다. 기본 `NoOpAnalyticsAdapter`는 외부로 전송하지 않으며, 실제 분석 SDK나 수집 엔드포인트는 아직 연결되어 있지 않습니다.

## 실행 및 빌드

현재 기준 도구 조합은 Flutter 3.44.6, Dart 3.12.2, Flame 1.37.0입니다.

```sh
flutter pub get
flutter analyze
flutter test
```

### Web

일반 Flutter Web 실행·빌드는 CanvasKit 렌더러를 사용합니다. 현재 보존된 표준 빌드 진입점은 `build/web/main.dart.js`입니다.

```sh
flutter run -d chrome
flutter build web --release
```

Cloudflare Pages 업로드는 개인정보 화면과 Play 게시 계획이 완료되기 전까지
**INTERIM FEATURE PREVIEW — PRIVACY REDEPLOY REQUIRED** 경계로만 취급합니다.
최종 배포가 아니며 기존 `tokenfront-ai-arena` 프로젝트를 삭제하지 않습니다.
Task 7에서 개인정보 surface와 Web/AAB source parity를 확인한 뒤 같은
`tokenfront-orbital-war` 프로젝트를 재배포해야 합니다.

```sh
find build/web -type f -print0 | sort -z | xargs -0 shasum -a 256 > /tmp/tokenfront-orbital-war-build.sha256
npx wrangler pages deploy build/web --project-name tokenfront-orbital-war
```

Task 12의 release Web build와 46-file pre-deploy digest는
`.omo/evidence/task-12/`에 기록되어 있습니다. 현재 interim preview는
[tokenfront-orbital-war.pages.dev](https://tokenfront-orbital-war.pages.dev/)에서
확인할 수 있으며 deployment ID는
`e74f7d12-c7c5-40c0-9d87-83240b57de5c`입니다. 이 배포는 Task 12의 dirty
working-tree build이므로 커밋 결합형 최종 릴리스 증거가 아닙니다.

Chrome 장치가 없으면 웹 서버 모드로 실행한 뒤 출력된 주소를 Safari 등에서 열 수 있습니다.

```sh
flutter run -d web-server
```

WebAssembly 빌드는 선택 사항이며 기본값이 아닙니다. `--wasm` 빌드는 WasmGC를 지원하는 브라우저에서 Skwasm을 우선 사용하고, Flutter가 호환성용 CanvasKit 경로도 함께 생성합니다. 현재 별도로 보존된 Wasm 진입점은 `build/web_wasm/main.dart.wasm`입니다.

```sh
flutter build web --release --wasm
```

예전 HTML 렌더러를 전제로 한 `--web-renderer html` 사용법은 현재 프로젝트와 Flutter 도구 체인에 해당하지 않습니다.

### Android

```sh
flutter build apk --debug
flutter run -d <android-device-id>
```

스토어용 App Bundle은 배포 서명을 구성한 뒤 생성합니다.

```sh
flutter build appbundle --release
```

### iOS

```sh
flutter build ios --simulator
flutter run -d <ios-simulator-id>
flutter build ios --release --no-codesign
```

마지막 명령은 코드 서명 없는 빌드 확인용입니다. TestFlight/App Store 제출에는 Apple 개발자 계정, 프로비저닝, 서명과 실제 기기 검증이 별도로 필요합니다.

### 통합 테스트

단위·위젯·성능 테스트 전체는 `flutter test`로 실행합니다. 2026-08-05 통합 체크포인트의 기본 VM 실행은 **190개를 통과하고 Web 저장소 전용 1개를 건너뛰었습니다**. 여기에는 4,000-unit 스폰·분산 대형·공간 질의·고정 풀 성능, 자유 이동과 확대된 모바일 조작 영역, Signal Chronicle 5개 작전·결말·손상 저장 복구, 네 언어 전투 지령과 접근성, Blender 런타임 아틀라스, Play 그래픽 규격, War Token·설정·동의의 자동 저장과 재실행 복원이 포함됩니다. Web 저장소 전용 테스트는 별도의 실제 Chromium 실행 대상이며, `integration_test/app_smoke_test.dart`는 앱 시작, 설정 열기, 매치 진입, 앱 pause/resume과 결정론적 Chronicle/Skirmish 시나리오를 검사합니다.

```sh
flutter test -d <device-or-simulator-id> integration_test/app_smoke_test.dart
```

### 보존된 2026-07-15 실행 검증

다음 결과는 2026-07-15 당시 이전 빌드에서 수집한 플랫폼 증거입니다. 현재 4,000-unit 카메라·미니맵·방향 처리 변경의 대상 플랫폼 검증으로 간주하지 않습니다.

| 대상 | 환경 | 확인 결과 |
|---|---|---|
| Android 실제 기기 | Samsung SM A175N · `RFKYB09D9TL` · Android 16 | 통합 smoke 테스트 통과 |
| iOS Simulator | iPhone 17 Pro Max · iOS 26.5 | 동일 통합 smoke 테스트 통과 |
| Web | macOS 로컬 Chrome·Safari, 표준 CanvasKit 빌드 | 실제 렌더링, 키보드·포인터 입력, 화면 비율, pause/resume 확인; Chrome 앱 오류 로그 0건 |

### 실제 기기 성능 프로필

`tooling/performance_profile_app.dart`는 4,000개 유닛을 카메라 크기의 100×40 밀집 전투 구역에 배치하고, 3초 워밍업 뒤 FPS 측정치를 초기화해 30초 동안 샘플링하는 전용 profile-mode 진입점입니다. 오디오와 햅틱은 측정에서 제외하며 결과를 `TOKENFRONT_PERFORMANCE` JSON 한 줄로 출력합니다. 결과에는 고정 30Hz, 평균/1% low FPS, 렌더 컬링, 아틀라스 배치, SpatialGrid 방문 수가 포함됩니다.

```sh
flutter run --profile -d <android-device-id> \
  -t tooling/performance_profile_app.dart
```

Samsung SM A175N · `RFKYB09D9TL` · Android 16의 기존 400-unit 성공 실행 결과는 [원본 측정 기록](docs/performance-profile-sm-a175n-2026-07-15.json)에 역사적 기준으로 보존했습니다. 이 기록은 4,000-unit 변경 전 측정이므로 새 규모의 실제 기기 FPS를 입증하지 않습니다.

- 400개 유닛 할당, 30초 밀집 전투 샘플(2026-07-15 이전 규모)
- 프레임 샘플 2,599개, 관측 프레임 처리율 86.63 FPS
- 순간 FPS 산술 평균 88.38 FPS, 1% low 45 FPS
- 워밍업을 포함한 누적 시뮬레이션 958틱
- 처리되지 않은 Flutter 예외 0건; 수정 뒤 지휘 인계 테이프 렌더 예외가 재발하지 않았고 전용 회귀 테스트가 같은 경로를 보호

따라서 당시 400-unit 빌드의 평균 60 FPS·밀집 전투 30 FPS 기준은 해당 실제 Android 기기와 30초 profile 세션에서 입증됐습니다. 현재 4,000-unit 빌드는 자동화된 30Hz 공간 질의·고정 풀 회귀 검사를 통과했으며, 같은 실제 기기에서 새 30초 profile 결과를 다시 수집해야 합니다.

## Blender MCP 자산

저장소에는 키 아트, 런타임 스프라이트 아틀라스와 향후 재생성용 스크립트가 함께 들어 있습니다. 개발자 로컬 환경에서 사용한 것으로 기록된 구성요소는 **BlenderMCP 배포판 1.6.4**, **MCP SDK 1.28.1**, **Blender 5.1.2**입니다. 이 세 값은 서로 다른 구성요소의 버전이며 `1.28.1`을 BlenderMCP 버전으로 부르지 않습니다. 저장소에는 해당 실행의 커밋된 MCP 요청/응답, 서버 종료 확인, 또는 현재 바이너리를 이 환경이 생성했다는 영수증이 없습니다. 이 저장소에는 BlenderMCP 서버나 Blender 애드온을 vendoring하지 않습니다.

```text
assets/blender/
  tokenfront_arena.blend        편집 가능한 Blender 장면
  tokenfront_arena.glb          교환용 3D 내보내기
  tokenfront_keyart.png         1440×900 앱 로비 키 아트
  tokenfront_token_atlas.blend  런타임 토큰 아틀라스의 Blender 원본
assets/images/
  tokenfront_token_atlas.png    256×64 RGBA 런타임 아틀라스
  tokenfront_token_atlas.json   네 진영 64×64 프레임 manifest
tooling/
  build_tokenfront_scene.py     기본 메시·머티리얼로 장면 생성/저장/렌더/내보내기
  build_token_sprite_atlas.py   네 진영 아틀라스·manifest·Blend 원본 생성
  blender_mcp_call.py           로컬 Blender MCP stdio ↔ socket 호출 도우미
```

BlenderMCP의 소스·애드온·서버·라이선스는 이 저장소에 포함되지 않는 외부 prerequisite입니다. 생성 당시 사용한 로컬 checkout은 `.gitignore`로 제외되어 있으므로 fresh clone에서 자동으로 제공된다고 가정하지 마세요. upstream BlenderMCP는 별도로 설치·검토해야 하며, 이 프로젝트가 그 파일을 재배포한다고 주장하지 않습니다. 이미 커밋된 결과물은 BlenderMCP를 실행하지 않아도 사용할 수 있습니다. 기존 편집 가능한 `.blend` 파일은 과거 개발자 로컬 경로를 보존할 수 있으므로 이식 가능성의 증거로 취급하지 마세요. 경로를 하드코딩하지 않는 `tooling/` 스크립트는 **향후 재생성**에만 적용됩니다.

생성 스크립트는 외부 모델, 텍스처, 생성형 3D API를 내려받지 않고 Blender 기본 메시와 자체 머티리얼만 사용합니다. 호출 도우미는 `DISABLE_TELEMETRY=true`와 `PYTHONDONTWRITEBYTECODE=1`을 적용합니다.

### 재생성

1. 별도로 설치한 BlenderMCP 애드온을 GUI Blender에 설치·활성화하고, 3D View의 BlenderMCP 패널에서 socket 서버를 시작합니다. 기본 주소는 `localhost:9876`입니다. 애드온 소스는 이 저장소의 경로가 아닙니다.
2. `blender-mcp` 실행 파일과 MCP Python 패키지가 들어 있는 외부 Python 환경을 지정합니다. 기록된 macOS 실행에서는 다음 캐시 경로를 사용했습니다(다른 컴퓨터에서는 자신의 설치 경로로 바꿉니다).

```sh
export BLENDER_MCP_CACHE_ENV=/Users/toris/.cache/uv/archive-v0/2MdHiH30JWRWtlL_
export BLENDER_MCP_EXECUTABLE="$BLENDER_MCP_CACHE_ENV/bin/blender-mcp"

cd /Users/toris/projects/aiArena
python3 tooling/blender_mcp_call.py --list-tools
python3 tooling/blender_mcp_call.py \
  --code-file tooling/build_tokenfront_scene.py \
  --user-prompt "Rebuild Tokenfront arena from repository script"

python3 tooling/blender_mcp_call.py \
  --code-file tooling/build_token_sprite_atlas.py \
  --user-prompt "Rebuild Tokenfront runtime token atlas"
```

`BLENDER_MCP_CACHE_ENV`에는 `bin/python`과 MCP 의존성이 있어야 합니다. `BLENDER_MCP_EXECUTABLE`은 그 환경의 `bin/blender-mcp` 또는 외부 설치의 절대 경로를 가리켜야 합니다. `--code-file` 경로를 사용하면 호출 도우미가 자신의 위치에서 저장소 루트를 계산해 Blender 코드와 모듈 경로에 전달하므로 복제 경로를 소스에 하드코딩하지 않습니다. Blender MCP는 임의 Python 코드를 실행할 수 있으므로 신뢰하는 로컬 스크립트만 사용하고 실행 전에 장면을 저장하세요.

장면 생성은 `.tokenfront_arena.pending.glb`로 먼저 내보내고 GLB 2.0 컨테이너·길이·JSON 문서를 검증한 뒤 `tokenfront_arena.glb`로 원자적으로 승격합니다. 내보내기나 검증이 실패하면 예외가 MCP 도구 결과로 전달되고 `TOKENFRONT_SCENE_READY`는 출력되지 않습니다. 성공한 응답 안의 ready JSON은 [receipt schema](docs/blender-generation-receipt.schema.json)를 따르며 파일명, GLB 바이트 길이, SHA-256, 청크 정보와 객체 수만 포함합니다. 이 응답을 실행 당시 별도 보관해야 생성 실행 증거가 되며, 현재 커밋에는 그러한 실행 영수증이 없습니다.

## 주요 구조

```text
lib/
  app/tokenfront_runtime.dart       오프라인 안전 런타임과 보상 조정
  game/simulation.dart              결정론적 전투, AI, 공간 그리드
  game/tokenfront_game.dart         Flame 아틀라스 렌더링·컬링, 입력, 카메라, 오디오, 승계
  economy/                          로컬 War Token과 꾸미기 카탈로그
  services/ads/                     정책, NoOp/Fake 광고 어댑터
  services/analytics/               타입 이벤트와 로컬 버퍼
  services/privacy/                 동의·ATT·식별자 게이트
  settings/                         접근성·성능·입력·오디오 설정
  l10n/                             영어·한국어·일본어·중국어 번역 리소스와 생성 코드
  ui/                               로비, 전투 HUD, 설정, Locker, 결과
test/                               단위·성능·위젯 테스트
integration_test/                   앱 smoke 테스트
tooling/performance_profile_app.dart 실제 기기 밀집 전투 profile 측정 진입점
```

## 출시 전 전용 작업

아래 항목은 현재 오프라인 게임 코어와 smoke QA의 완료 범위에 포함되지 않습니다.

- 라이브 AdMob 퍼블리셔·광고 단위 ID, H5 Games Ads 구성, 분석 프로젝트 ID와 플랫폼 SDK 어댑터 연결
- iOS 네이티브 ATT 시스템 프롬프트, 승인된 추적·동의 문구와 플랫폼 동의 SDK 연결
- War Token을 구매 가능하게 만들 경우 서버 거래 원장·계정 동기화·구매 복원 추가
- Android/iOS 릴리스 서명·프로비저닝, 스토어 메타데이터·연령 등급·출시 국가, 개인정보처리방침과 데이터 수집·공유 신고 최종화
- SM A175N의 과거 400-unit 30초 결과와 별도로, 대표 Android/iOS 실제 기기와 실제 배포 브라우저에서 현재 4,000-unit 장시간·반복 FPS·1% low, 발열·메모리·resume 내구성 측정
- 실제 기기와 브라우저의 오디오 지연·햅틱 품질, 선택형 Wasm/Skwasm 배포 경로의 호환성 확인

2026-08-05 통합 체크포인트는 기본 VM 자동 테스트 190개를 통과했고 Web 저장소 전용 1개는 해당 실행에서 건너뛰었습니다. 위 Android·iOS·Chrome·Safari smoke QA와 SM A175N의 30초 profile 합격은 2026-07-15 이전 빌드의 보존 증거이며, 현재 4,000-unit 빌드의 실제 기기 방향 동작과 장시간 성능은 별도 출시 검증 항목입니다.
