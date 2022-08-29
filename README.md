# ⚗️ ZeroTo7Seg (Team 0to100)
Flutter 7-segment OCR using Tesseract LSTM

## 💻 작동 환경
- Flutter 3.0.* (프로젝트 작성 당시 3.0.4)
- Dart >=2.16.2 <3.0.0 (프로젝트 작성 당시 2.17.5)

## 🧩 작동 설정
- OpenCV (프로젝트 작성 당시 4.6.0)

해당 프로젝트는 [as1605/opencv_flutter_ffi](https://github.com/SemteulGaram/opencv_flutter_ffi) 의 OpenCV Dart FFI 를 사용하였음

### 🤖 Android
- 위 레포지티에서 다음 폴더를 현 프로젝트로 복사하거나
- README를 참조해 아래 폴더들을 다운받아야 작동 가능
- `/android/src/main/jniLibs`
- `/android/include/opencv2`

### 🍎 IOS
- 파일이 너무 커 위 레포지티에도 해당 폴더가 없음
- README를 참조해 아래 폴더들을 다운받아야 작동 가능
- `/ios/opencv2.framework`

---
## 🔰 공동 작업자에게 도움이 될 문서
- Git 명령어가 헷갈린다면... - [Git 간편 안내서 (한글)](https://rogerdudler.github.io/git-guide/index.ko.html)
- [Flutter 설치 (한글)](https://flutter-ko.dev/docs/get-started/install)
  - (2022-07-19 기준) $\sf \color{red}!\space해당\space설치\space문서의\space다운로드\space링크는\space깨져\space있으니\space공식\space SDK\space다운로드를\space이용하고\space설치\space문서만\space참조할\space것$ [공식 SDK](https://docs.flutter.dev/get-started/install)
  - 공식 문서와 같이 안드로이드 스튜디오 설치방법을 권장. 설치 후 안드로이드 디버깅 연결하고 바로 휴대폰에서 앱 디버깅 가능
- [Flutter 문서 (한글)](https://flutter-ko.dev/docs) [(영문)](https://docs.flutter.dev/)
  - (2022-07-19 기준) 한글 사이트 최적화가 2019년도에서 멈춰 있음. 하지만 여전히 많은 부분을 참조가능
- 현재 이 문서를 편집하고 싶으면... - [마크다운 작성법](https://gist.github.com/ihoneymon/652be052a0727ad59601)
---
## 🗃️ 프로젝트 간단 파일 구조
- `assets` - 이미지와 테서락트 모델과 같은 외부 리소스 포함 폴더
- `lib` - 메인 소스코드와 각 스크린 Dart 코드 폴더
  - `screen` - 만들어둔 각종 레이아웃과 프로세싱 코드. 복사해서 새로운 버전을 만들고 `main.dart`에 다른 스크린처럼 추가해 코드 테스트 가능
    - `segment_ocr_scan.dart` - 아마 제일 관심 있을 파일. 카메라부터 Tesseract OCR 까지 처리 코드가 있는 Dart파일
    - ...
  - `main.dart` - 어플리케이션의 각종 정보를 정의하는 루트파일
- `android` - $\sf \color{gray}안드로이드\space빌드\space관련\space파일$
  - ...
- `ios` - $\sf \color{gray}IOS\space빌드\space관련\space파일$
  - ...
- `pubspec.yaml` - 어플리케이션 메타데이터. 해당 파일의 `dependencies:` 부분에 원하는 기능이 담긴 [Dart 패키지](https://pub.dev/) 종속성 추가 가능
- `README.md` - 현재 이 문서. 다른 공동 작업자를 위해 중요 변경점을 적어둘 수 있습니다 [마크다운 작성법](https://gist.github.com/ihoneymon/652be052a0727ad59601)
---
## 🗒️ 다른 사람에게 남기는 메모
- Github를 사용할 때 다른 어떠한 실수도 되돌릴 수 있지만. 매우 큰 파일이나 개인정보가 업로드 되지 않도록 각별히 주의 - [gitignore 사용법](https://chunggaeguri.tistory.com/entry/GitHub-gitignore-%EC%82%AC%EC%9A%A9%EB%B2%95)
- 공동편집하다보면 동시에 편집하는 부분에서 충돌이 발생할 수 있음. 충돌시 대처법 - [Git merge 시 conflict(충돌) 해결법](https://devilfront.tistory.com/152)
- _...이하 자유롭게 작성..._
