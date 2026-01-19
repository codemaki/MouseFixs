# MouseFix 🥊

macOS에서 마우스 사이드 버튼으로 앞으로가기/뒤로가기를 사용할 수 있게 해주는 메뉴바 앱입니다.

## 기능

- **마우스 버튼 4**: 앞으로가기 (Command+])
- **마우스 버튼 5**: 뒤로가기 (Command+[)
- 모든 앱에서 동작 (브라우저, Finder, PDF 뷰어 등)

## 빌드 방법

```bash
chmod +x build.sh
./build.sh
```

## 실행 방법

```bash
open build/MouseFix.app
```

## 설치 방법

Applications 폴더에 복사:

```bash
cp -r build/MouseFix.app /Applications/
```

그 다음 Applications 폴더에서 MouseFix 앱을 실행하세요.

## 접근성 권한 설정

앱을 처음 실행하면 접근성 권한을 요청합니다. 다음 단계를 따라주세요:

1. **시스템 설정** > **개인정보 보호 및 보안** > **접근성** 으로 이동
2. 왼쪽 하단의 🔒 자물쇠를 클릭하고 비밀번호 입력
3. **MouseFix** 또는 **Terminal** (터미널에서 실행한 경우)을 찾아 체크 활성화
4. 앱을 재시작

## 사용 방법

1. 앱이 실행되면 메뉴바에 🥊 아이콘이 나타납니다
2. 아이콘을 클릭하면 버튼 매핑 정보를 볼 수 있습니다
3. 마우스 사이드 버튼 4번을 누르면 앞으로가기, 5번을 누르면 뒤로가기가 실행됩니다
4. Safari, Chrome, Firefox, Finder, Preview 등 모든 앱에서 동작합니다

## 시스템 요구사항

- macOS 11.0 (Big Sur) 이상
- Xcode Command Line Tools (Swift 컴파일러)
- 마우스 사이드 버튼이 있는 마우스

## 문제 해결

### 마우스 버튼이 작동하지 않는 경우
- 접근성 권한이 제대로 설정되었는지 확인
- 앱을 재시작
- 시스템을 재시동
- 마우스가 사이드 버튼을 지원하는지 확인

### 빌드가 실패하는 경우
Xcode Command Line Tools 설치:
```bash
xcode-select --install
```

## 라이선스

MIT License
