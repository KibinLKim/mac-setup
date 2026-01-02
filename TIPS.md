# Mac 개발 환경 사용 팁

## 터미널 (Warp)
- **세로 분할:** `Cmd + D`
- **가로 분할:** `Cmd + Shift + D`
- **패널 이동:** `Cmd + Option + 방향키`
- **패널 닫기:** `Cmd + W`
- **화면 클리어:** `Cmd + K`

## CLI 명령어
| 명령어 | 설명 |
|--------|------|
| `eza` (ll) | 이쁜 ls |
| `bat` (cat) | 하이라이팅 cat |
| `rg` | 빠른 검색 (ripgrep) |
| `fzf` | 퍼지 파인더 |
| `jq` | JSON 파싱 |
| `yq` | YAML 파싱 |
| `lg` | lazygit |
| `tldr` | 명령어 예제 |
| `http` | API 테스트 (httpie) |

## fzf 단축키
- `Ctrl + R` - 히스토리 퍼지 검색

## ripgrep (rg)
```bash
rg "검색어"           # 기본 검색
rg -i "검색어"        # 대소문자 무시
rg "검색어" -t py     # 특정 파일 타입만
rg -l "검색어"        # 파일명만 보기
rg -C 3 "검색어"      # 앞뒤 3줄 컨텍스트
```

## uv (Python)
```bash
uv python install         # 최신 Python 설치
uv python list            # 설치된 버전 확인
uv pip install 패키지     # 패키지 설치
uv venv                   # 가상환경 생성
uv run python app.py      # 실행
```

## Git
```bash
gh auth login             # GitHub 로그인
git config --global user.name "이름"
git config --global user.email "이메일"
```

## Claude Code + VS Code
- 외부 터미널에서 VS Code diff 연결: claude 실행 후 `/ide` 입력
- VS Code 확장 `anthropics.claude-code` 자동 설치됨
