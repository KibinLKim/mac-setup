#!/bin/bash

# ============================================
# Mac 개발 환경 설정 스크립트
# ============================================

set -euo pipefail

# ===== 설정 =====
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)
readonly LOG_FILE="./mac-setup-${TIMESTAMP}.log"
readonly ERR_FILE="./mac-setup-${TIMESTAMP}.err"
readonly HOMEBREW_PREFIX=$([[ $(uname -m) == "arm64" ]] && echo "/opt/homebrew" || echo "/usr/local")

CLI_TOOLS=(git gh eza bat ripgrep fzf jq yq lazygit node pnpm uv httpie tldr watch)

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
    anthropic.claude-code
    haack.warp-companion
)

# 런타임 변수
SUDO_PID=""
TEE_LOG_PID=""
TEE_ERR_PID=""
LOG_FIFO=""
ERR_FIFO=""
FAILED_ITEMS=()

# ===== 유틸리티 함수 =====

setup_logging() {
    LOG_FIFO="/tmp/mac-setup-log-$$"
    ERR_FIFO="/tmp/mac-setup-err-$$"
    mkfifo "$LOG_FIFO" "$ERR_FIFO"

    tee -a "$LOG_FILE" < "$LOG_FIFO" &
    TEE_LOG_PID=$!
    tee -a "$ERR_FILE" < "$ERR_FIFO" >&2 &
    TEE_ERR_PID=$!

    exec 3>&1 4>&2
    exec > "$LOG_FIFO" 2> "$ERR_FIFO"
}

cleanup() {
    # sudo 갱신 프로세스 종료
    [[ -n "$SUDO_PID" ]] && kill "$SUDO_PID" 2>/dev/null && wait "$SUDO_PID" 2>/dev/null
    # stdout/stderr 복원
    exec 1>&3 2>&4 3>&- 4>&- 2>/dev/null || true
    # tee 프로세스 대기
    [[ -n "$TEE_LOG_PID" ]] && wait "$TEE_LOG_PID" 2>/dev/null
    [[ -n "$TEE_ERR_PID" ]] && wait "$TEE_ERR_PID" 2>/dev/null
    # FIFO 정리
    rm -f "$LOG_FIFO" "$ERR_FIFO" 2>/dev/null
}

refresh_sudo() { sudo -v 2>/dev/null; }

setup_sudo() {
    echo "🔐 관리자 권한이 필요합니다..."
    sudo -v || { echo "  ✗ sudo 권한 획득 실패"; exit 1; }
    (while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 15; done) &
    SUDO_PID=$!
    trap cleanup EXIT
}

print_section() {
    echo "$1"
    echo "──────────────────────────────────────────"
}

# 진행률 표시와 함께 배열 항목 처리
run_with_progress() {
    local -n items=$1
    local callback=$2
    local total=${#items[@]} i=0

    for item in "${items[@]}"; do
        ((i++))
        echo -n "  [$i/$total] "
        $callback "$item"
    done
}

# brew 패키지 설치
brew_install() {
    local type=$1 name=$2 pkg=$3
    [[ "$type" == "cask" ]] && refresh_sudo

    if brew list --$type "$pkg" &>/dev/null; then
        echo "✓ $name (이미 설치됨)"
    elif brew install --$type "$pkg" &>/dev/null; then
        echo "✓ $name"
    else
        echo "✗ $name (설치 실패)"
        FAILED_ITEMS+=("$name")
    fi
}

# DMG 앱 설치
install_dmg_app() {
    local name=$1 url=$2 app_name=${3:-$1}
    local dmg_path="/tmp/${name,,}.dmg"

    if [[ -d "/Applications/${app_name}.app" ]]; then
        echo "  ✓ $name (이미 설치됨)"
        return 0
    fi

    if ! curl -fsSL "$url" -o "$dmg_path"; then
        echo "  ✗ $name (다운로드 실패)"
        FAILED_ITEMS+=("$name")
        return 1
    fi

    local mount_output
    if ! mount_output=$(hdiutil attach "$dmg_path" -nobrowse 2>&1); then
        echo "  ✗ $name (마운트 실패)"
        FAILED_ITEMS+=("$name")
        rm -f "$dmg_path"
        return 1
    fi

    local mount_point
    mount_point=$(echo "$mount_output" | grep -o '/Volumes/[^"]*' | head -1)

    if [[ -d "${mount_point}/${app_name}.app" ]]; then
        cp -R "${mount_point}/${app_name}.app" /Applications/
        echo "  ✓ $name"
    else
        echo "  ✗ $name (앱을 찾을 수 없음)"
        FAILED_ITEMS+=("$name")
    fi

    hdiutil detach "$mount_point" &>/dev/null
    rm -f "$dmg_path"
}

# ===== 설치 함수 =====

install_homebrew() {
    echo "🍺 Homebrew 설치 확인..."
    if ! command -v brew &>/dev/null; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
        if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
            echo "eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zprofile
        fi
        eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        echo "  ✓ Homebrew 설치 완료"
    else
        echo "  ✓ Homebrew (이미 설치됨)"
    fi
    echo "  ↻ Homebrew 업데이트 중..."
    brew update &>/dev/null
    echo ""
}

install_cli_tools() {
    print_section "📦 CLI 도구 설치..."
    _install_cli() { brew_install formula "$1" "$1"; }
    run_with_progress CLI_TOOLS _install_cli
    echo ""
}

install_warp() {
    print_section "🚀 Warp 설치..."
    install_dmg_app "Warp" "https://app.warp.dev/download?package=dmg"
    echo ""
}

install_cask_apps() {
    print_section "📦 Cask 앱 설치..."
    _install_cask() {
        local name="${1%%:*}" pkg="${1##*:}"
        brew_install cask "$name" "$pkg"
    }
    run_with_progress CASK_APPS _install_cask
    echo ""
}

install_python() {
    print_section "🐍 Python 설치..."
    if uv python install &>/dev/null; then
        echo "  ✓ Python (최신 버전)"
    else
        echo "  ✓ Python (이미 설치됨)"
    fi
    if uv tool install ruff &>/dev/null; then
        echo "  ✓ ruff (uv)"
    else
        echo "  ✓ ruff (uv, 이미 설치됨)"
    fi
    echo ""
}

install_vscode_extensions() {
    print_section "🔌 VS Code 확장 프로그램 설치..."
    local vscode="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

    if [[ ! -f "$vscode" ]]; then
        echo "  ⚠ VS Code가 설치되지 않음 (건너뜀)"
        echo ""
        return
    fi

    # code 명령어 설정
    refresh_sudo
    if [[ ! -L /usr/local/bin/code ]]; then
        sudo mkdir -p /usr/local/bin
        sudo ln -sf "$vscode" /usr/local/bin/code
        echo "  ✓ code 명령어 설정"
    else
        echo "  ✓ code 명령어 (이미 설정됨)"
    fi

    # 확장 설치
    local installed
    installed=$("$vscode" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    _install_ext() {
        local ext=$1 ext_lower=${1,,}
        if echo "$installed" | grep -q "^${ext_lower}$"; then
            echo "✓ $ext (이미 설치됨)"
        elif "$vscode" --install-extension "$ext" &>/dev/null; then
            echo "✓ $ext"
        else
            echo "✗ $ext (설치 실패)"
            FAILED_ITEMS+=("VS Code: $ext")
        fi
    }
    run_with_progress VSCODE_EXTENSIONS _install_ext
    echo ""
}

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
    if ! grep -q "# Custom alias" ~/.zshrc 2>/dev/null; then
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

print_header() {
    echo ""
    echo "══════════════════════════════════════════"
    echo "  🚀 Mac 개발 환경 설정 스크립트"
    echo "══════════════════════════════════════════"
    echo "📝 로그: $LOG_FILE"
    echo "📝 에러: $ERR_FILE"
    echo ""
}

print_footer() {
    echo "══════════════════════════════════════════"

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        echo "⚠️  일부 항목 설치 실패:"
        printf "  • %s\n" "${FAILED_ITEMS[@]}"
        echo ""
    fi

    cat << 'EOF'
✅ 완료!

📋 설치 후 필요한 작업:
──────────────────────────────────────────
• VS Code: code 명령어 사용 가능
• Docker: 앱 실행 → 권한 허용 → 초기 설정
• Rectangle: 앱 실행 → 접근성 권한 허용
• GitHub CLI: gh auth login
• Git 설정: git config --global user.name/email
• Claude Code: claude 실행 → 로그인
• Warp: 테마, IDE 설정
══════════════════════════════════════════
EOF
}

# ===== 메인 =====

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

# 실행
setup_logging
main

# 정리
[[ ! -s "$ERR_FILE" ]] && rm -f "$ERR_FILE"
cleanup
exec zsh -l
