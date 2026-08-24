# Tokenfront: Orbital Signal War
Flutter와 Flame으로 만든 오프라인 싱글플레이 전쟁 시뮬레이션입니다. Amethyst, Cobalt, Volt, Prism 네 진영이 전장을 점유하고, 플레이어는 한 유닛을 지휘하다가 사망 시 같은 진영의 후계 유닛으로 지휘권을 넘깁니다.

## 주요 기능

- 4개 진영 × 1,000개 유닛의 결정론적 전투 시뮬레이션
- 30Hz 게임 루프, 공간 그리드 근접 탐색, 추적·회피 AI
- 모바일 조이스틱·대시와 웹/데스크톱 키보드·마우스 카메라
- 로비·전투 HUD·결과 화면, 미니맵, 가로 전투 레이아웃
- 영어·한국어·일본어·중국어(간체)와 접근성/저사양 설정
- War Token 보상과 장식 아이템 해금·장착을 기기 로컬에 저장

광고와 분석은 어댑터 경계만 제공하며 기본 빌드는 외부 네트워크로 전송하지 않습니다. 계정 동기화·서버 원장·IAP는 연결되어 있지 않습니다.

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
flutter run -d chrome
```

Android 확인은 `flutter run -d <device-id>`, iOS 시뮬레이터 확인은 `flutter run -d <simulator-id>`를 사용합니다. 스토어 번들은 서명 환경을 준비한 뒤 `flutter build appbundle --release`로 생성합니다.
