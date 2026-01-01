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

## 설치 후

1. 터미널 재시작
2. VS Code에서 `Cmd+Shift+P` → `Shell Command: Install 'code' command in PATH` 실행
3. Docker Desktop 실행

## 참고

- 반복 실행해도 문제없음 (이미 설치된 항목은 자동 스킵)
