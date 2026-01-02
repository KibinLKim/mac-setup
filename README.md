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
git clone https://github.com/your-username/mac-setup.git
cd mac-setup
chmod +x mac-setup.sh
./mac-setup.sh
```

스크립트 실행 시 로그 파일이 자동 생성됩니다:
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

## 참고

- 반복 실행해도 문제없음 (이미 설치된 항목은 자동 스킵)
