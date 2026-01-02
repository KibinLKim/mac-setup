# mac-setup

macOS default development environment setup script

## 설치 항목

### CLI 도구
- git, gh (GitHub CLI)
- eza, bat, ripgrep, fzf (더 나은 기본 명령어)
- jq, yq (JSON/YAML 파싱)
- lazygit (Git TUI)
- node, pnpm (Node.js)
- uv (Python 패키지 매니저)
- httpie, tldr, watch

### GUI 앱
- Warp (터미널)
- Visual Studio Code
- Docker
- Google Chrome
- Rectangle (창 관리)
- Slack

### VS Code 확장
- Python, Ruff
- ESLint, Prettier
- Docker, Kubernetes
- GitLens, YAML, Remote SSH
- Claude Code
- Warp Companion (Warp 테마 동기화)

### 기타
- Claude Code
- Python (uv로 설치)
- fzf 키바인딩
- 쉘 alias

## 사용법
```bash
git clone https://github.com/KibinLKim/mac-setup.git
cd mac-setup
./mac-setup.sh
```

> 새 맥에서 `git clone` 실행 시 Xcode Command Line Tools 설치 프롬프트가 뜹니다. 설치 완료 후 다시 실행하세요.

## 기능

- **단일 비밀번호 입력**: 시작 시 한 번만 비밀번호 입력 (이후 자동 처리)
- **진행률 표시**: `[1/15] ⏳ Docker 설치 중... 완료` 형식으로 실시간 진행 상황 표시
- **실패 요약**: 스크립트 끝에 설치 실패 항목 요약 출력
- **멱등성**: 반복 실행해도 이미 설치된 항목은 자동 스킵
- **로깅**: 자동 로그 파일 생성
  - `mac-setup-날짜시간.log` - 정상 출력
  - `mac-setup-날짜시간.err` - 에러 출력 (에러 없으면 자동 삭제)

## 설치 후

1. Docker: 앱 실행 → 권한 허용 → 초기 설정
2. Rectangle: 앱 실행 → 접근성 권한 허용
3. GitHub CLI: `gh auth login`
4. Git 설정: `git config --global user.name "이름"` / `git config --global user.email "이메일"`
5. Claude Code: `claude` 실행 → 로그인
6. Warp: 테마, IDE 설정

> 터미널 재시작과 VS Code `code` 명령어는 자동 설정됩니다.
