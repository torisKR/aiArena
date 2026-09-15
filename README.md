# Tokenfront: Orbital Signal War
Flutter와 Flame으로 만든 오프라인 **AI 토큰 전쟁 시뮬레이션**입니다. Amethyst, Cobalt, Volt, Prism 네 AI 코어가 각각 1,000개의 활성 토큰으로 동일한 전장을 시작합니다. 플레이어는 토큰 하나에 지휘 신호를 연결하고, 적의 토큰 공급량을 소각하면서 현재 토큰이 제거되기 전에 같은 코어의 다음 토큰으로 지휘권을 넘깁니다.

## 주요 기능

- 4개 AI 코어 × 1,000개 활성 토큰의 결정론적 전투 시뮬레이션
- 30Hz 게임 루프, 공간 그리드 근접 탐색, 추적·회피 AI
- Android 모바일 조이스틱·대시와 터치 기반 카메라 조작
- 로비·전투 HUD·결과 화면, 미니맵, 가로 전투 레이아웃
- 영어·한국어·일본어·중국어(간체)와 접근성/저사양 설정
- War Token 보상과 장식 아이템 해금·장착을 기기 로컬에 저장

분석은 여전히 외부 전송 없이 동작합니다. Android 디버그 AdMob 통합은 Google 테스트 광고만 사용하며,
동의가 준비되지 않았거나 오프라인이면 광고를 건너뛰고 게임을 계속합니다. 계정 동기화·서버 원장·IAP는 연결되어 있지 않습니다.

## 토큰 용어

- **활성 AI 토큰:** 전투 시뮬레이션의 유닛입니다. 생존 수가 각 코어의 실시간 토큰 공급량이며, 제거된 유닛은 소각된 토큰으로 집계됩니다.
- **War Token (WT):** 전투 결과로 받는 기기 로컬 장식 재화입니다. 전투 성능과 무관하며 암호화폐·블록체인·현금성 자산이 아닙니다.

## 기술 스택과 구조

- Flutter 3.44.6 / Dart 3.12.2, Flame 1.37.0
- `lib/game/`: 시뮬레이션·유닛·전투 규칙
- `lib/story/`: 캠페인 작전·결말·로컬라이제이션
- `lib/ui/`: 로비·전투·결과·설정 화면
- `lib/app/`, `lib/services/`: 런타임·로컬 저장·광고/분석 어댑터
- `assets/`: 오디오·키 아트·토큰 아틀라스

## 시작하기

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
flutter build apk --debug
```

Android 기기 확인은 `flutter run -d <android-device-id>`를 사용합니다. 스토어 번들은 서명 환경을 준비한 뒤 `flutter build appbundle --release`로 생성합니다.
