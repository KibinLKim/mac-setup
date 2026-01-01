#!/bin/bash

# ============================================
# Mac 개발 환경 설정 스크립트
# ============================================

# 설정
CLI_TOOLS=(git gh eza bat ripgrep fzf jq yq lazygit node pnpm uv httpie tldr watch)

# Homebrew 경로 (Intel vs Apple Silicon)
if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

# 백그라운드 프로세스 ID 저장
SUDO_PID=""
CASK_APPS=(
    "Visual Studio Code:visual-studio-code"
    "Docker:docker"
    "Google Chrome:google-chrome"
    "Rectangle:rectangle"
    "Slack:slack"
    "Claude Code:claude-code"
)
VSCODE_EXTENSIONS=(
    ms-python.python
    charliermarsh.ruff
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools
    eamodio.gitlens
    redhat.vscode-yaml
    ms-vscode-remote.remote-ssh
    haack.warp-companion
)

# 정리 함수 (스크립트 종료 시 호출)
cleanup() {
    if [[ -n "$SUDO_PID" ]] && kill -0 "$SUDO_PID" 2>/dev/null; then
        kill "$SUDO_PID" 2>/dev/null
    fi
}

# sudo 권한 요청 및 유지
setup_sudo() {
    echo "🔐 관리자 권한이 필요합니다..."
    sudo -v || { echo "  ✗ sudo 권한 획득 실패"; exit 1; }
    # sudo 세션 유지 (60초마다 갱신)
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done) 2>/dev/null &
    SUDO_PID=$!
    # 스크립트 종료 시 백그라운드 프로세스 정리
    trap cleanup EXIT
}

# 헤더 출력
print_header() {
    echo ""
    echo "══════════════════════════════════════════"
    echo "  🚀 Mac 개발 환경 설정 스크립트"
    echo "══════════════════════════════════════════"
    echo ""
}

# 섹션 헤더 출력
print_section() {
    echo "$1"
    echo "──────────────────────────────────────────"
}

# Homebrew 설치
install_homebrew() {
    echo "🍺 Homebrew 설치 확인..."
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # shellenv를 아키텍처에 맞게 설정
        if ! grep -q 'brew shellenv' ~/.zshrc; then
            echo "eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zshrc
        fi
        eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        echo "  ✓ Homebrew 설치 완료"
    else
        echo "  ✓ Homebrew (이미 설치됨)"
    fi
    # Homebrew 업데이트
    echo "  ↻ Homebrew 업데이트 중..."
    brew update &>/dev/null
    echo ""
}

# brew 패키지 설치 헬퍼
brew_install() {
    local type="$1" name="$2" pkg="$3"
    if brew list --$type "$pkg" &>/dev/null; then
        echo "  ✓ $name (이미 설치됨)"
    elif brew install --$type "$pkg" &>/dev/null; then
        echo "  ✓ $name"
    else
        echo "  ✗ $name (설치 실패)"
    fi
}

# CLI 도구 설치
install_cli_tools() {
    print_section "📦 CLI 도구 설치..."
    for tool in "${CLI_TOOLS[@]}"; do
        brew_install formula "$tool" "$tool"
    done
    echo ""
}

# Warp 설치 (DMG 직접 설치)
install_warp() {
    print_section "🚀 Warp 설치..."
    if [[ -d "/Applications/Warp.app" ]]; then
        echo "  ✓ Warp (이미 설치됨)"
    else
        local dmg_path="/tmp/warp.dmg"

        # DMG 다운로드
        if ! curl -fsSL "https://app.warp.dev/download?package=dmg" -o "$dmg_path"; then
            echo "  ✗ Warp (다운로드 실패)"
            echo ""
            return 1
        fi

        # DMG 마운트
        local mount_output
        mount_output=$(hdiutil attach "$dmg_path" -nobrowse 2>&1)
        if [[ $? -ne 0 ]]; then
            echo "  ✗ Warp (DMG 마운트 실패)"
            rm -f "$dmg_path"
            echo ""
            return 1
        fi

        local mount_point
        mount_point=$(echo "$mount_output" | sed -n 's/.*\(\/Volumes\/.*\)/\1/p')

        # 앱 복사
        if [[ -d "${mount_point}/Warp.app" ]]; then
            cp -R "${mount_point}/Warp.app" /Applications/
            echo "  ✓ Warp"
        else
            echo "  ✗ Warp (앱을 찾을 수 없음)"
        fi

        # 정리
        hdiutil detach "$mount_point" &>/dev/null
        rm -f "$dmg_path"
    fi
    echo ""
}

# Cask 앱 설치
install_cask_apps() {
    print_section "📦 Cask 앱 설치..."
    for item in "${CASK_APPS[@]}"; do
        brew_install cask "${item%%:*}" "${item##*:}"
    done
    echo ""
}

# Python 설치
install_python() {
    print_section "🐍 Python 설치..."
    uv python install &>/dev/null && echo "  ✓ Python (최신 버전)" || echo "  ✓ Python (이미 설치됨)"
    uv tool install ruff &>/dev/null && echo "  ✓ ruff (uv)" || echo "  ✓ ruff (uv, 이미 설치됨)"
    echo ""
}

# VS Code 확장 프로그램 설치
install_vscode_extensions() {
    print_section "🔌 VS Code 확장 프로그램 설치..."
    local vscode="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if [[ ! -f "$vscode" ]]; then
        echo "  ⚠ VS Code가 설치되지 않음 (건너뜀)"
        echo ""
        return
    fi

    # 설치된 확장 목록 캐시
    local installed_extensions
    installed_extensions=$("$vscode" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        local ext_lower
        ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        if echo "$installed_extensions" | grep -q "^${ext_lower}$"; then
            echo "  ✓ $ext (이미 설치됨)"
        elif "$vscode" --install-extension "$ext" &>/dev/null; then
            echo "  ✓ $ext"
        else
            echo "  ✗ $ext (설치 실패)"
        fi
    done
    echo ""
}

# 쉘 설정 (fzf + alias)
setup_shell() {
    print_section "⚙️  쉘 설정..."

    # fzf 키바인딩
    local fzf_install="${HOMEBREW_PREFIX}/opt/fzf/install"
    if grep -q "fzf" ~/.zshrc 2>/dev/null; then
        echo "  ✓ fzf 키바인딩 (이미 설정됨)"
    elif [[ -f "$fzf_install" ]]; then
        "$fzf_install" --all &>/dev/null
        echo "  ✓ fzf 키바인딩"
    else
        echo "  ⚠ fzf 미설치 (건너뜀)"
    fi

    # alias 설정
    if ! grep -q "# Custom alias" ~/.zshrc; then
        cat >> ~/.zshrc << 'EOF'

# Claude Code CLI (native 설치)
export PATH="$HOME/.local/bin:$PATH"

# Custom alias
alias ls="eza"
alias ll="eza -la"
alias cat="bat"
alias lg="lazygit"
alias npm="pnpm"
alias c="clear"
alias h="history"
EOF
        echo "  ✓ alias 추가됨"
    else
        echo "  ✓ alias (이미 설정됨)"
    fi
    echo ""
}

# 완료 메시지 출력
print_footer() {
    echo "══════════════════════════════════════════"
    echo "✅ 완료! 터미널 재시작하세요."
    echo ""
    echo "📋 설치 후 필요한 작업:"
    echo "──────────────────────────────────────────"
    echo "• VS Code: Cmd+Shift+P → Shell Command: Install"
    echo "• Docker: 앱 실행 → 권한 허용 → 초기 설정"
    echo "• Rectangle: 앱 실행 → 접근성 권한 허용"
    echo "• GitHub CLI: gh auth login"
    echo "• Git 설정: git config --global user.name/email"
    echo "• Claude Code: claude 실행 → 로그인"
    echo "• Warp: 테마, IDE 설정"
    echo "══════════════════════════════════════════"
    echo ""
}

# 메인 함수
main() {
    print_header
    setup_sudo
    install_homebrew
    install_cli_tools
    install_warp
    install_cask_apps
    install_python
    install_vscode_extensions
    setup_shell
    print_footer
}

# 스크립트 실행
main
