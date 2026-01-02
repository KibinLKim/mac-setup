#!/bin/bash

# ============================================
# Mac 개발 환경 설정 스크립트
# ============================================

set -euo pipefail

# ===== 상수 =====

readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)
readonly LOG_FILE="./mac-setup-${TIMESTAMP}.log"
readonly ERR_FILE="./mac-setup-${TIMESTAMP}.err"
readonly HOMEBREW_PREFIX=$([[ $(uname -m) == "arm64" ]] && echo "/opt/homebrew" || echo "/usr/local")
readonly SUDOERS_FILE="/etc/sudoers.d/mac-setup-nopasswd"
readonly WARP_DMG_URL="https://app.warp.dev/download?package=dmg"

# ===== 설치 목록 =====

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

# ===== 런타임 변수 =====

TEE_LOG_PID=""
TEE_ERR_PID=""
LOG_FIFO=""
ERR_FIFO=""
FAILED_ITEMS=()

# ===== 시스템 유틸리티 =====

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
    [[ -f "$SUDOERS_FILE" ]] && sudo rm -f "$SUDOERS_FILE" 2>/dev/null
    exec 1>&3 2>&4 2>/dev/null || true
    exec 3>&- 4>&- 2>/dev/null || true
    sleep 0.5
    [[ -n "$TEE_LOG_PID" ]] && kill "$TEE_LOG_PID" 2>/dev/null
    [[ -n "$TEE_ERR_PID" ]] && kill "$TEE_ERR_PID" 2>/dev/null
    rm -f "$LOG_FIFO" "$ERR_FIFO" 2>/dev/null
    [[ -f "$ERR_FILE" && ! -s "$ERR_FILE" ]] && rm -f "$ERR_FILE"
}

setup_sudo() {
    sudo -v || exit 1
    echo "$(id -un) ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" >/dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    trap cleanup EXIT
}

# ===== 출력 유틸리티 =====

print_section() { echo -e "\n$1\n──────────────────────────────────────────"; }
print_ok()      { echo "  ✓ $1"; }
print_skip()    { echo "  ✓ $1 (이미 설치됨)"; }
print_warn()    { echo "  ⚠ $1"; }

# 배열 항목을 진행률과 함께 처리 (bash 3.2 호환)
run_with_progress() {
    local arr_name=$1 callback=$2
    eval "local items=(\"\${${arr_name}[@]}\")"
    local total=${#items[@]} i=0

    for item in "${items[@]}"; do
        ((i++))
        echo -n "  [$i/$total] "
        $callback "$item"
    done
}

# ===== 설치 헬퍼 =====

brew_install() {
    local type=$1 name=$2 pkg=$3
    if brew list --$type "$pkg" &>/dev/null; then
        echo "✓ $name (이미 설치됨)"
    else
        echo -n "⏳ $name 설치 중..."
        if brew install --$type "$pkg" &>/dev/null; then
            echo " 완료"
        else
            echo " 실패"
            FAILED_ITEMS+=("$name")
        fi
    fi
}

install_dmg_app() {
    local name=$1 url=$2 app_name=${3:-$1}
    local dmg_path="/tmp/$(echo "$name" | tr '[:upper:]' '[:lower:]').dmg"

    if [[ -d "/Applications/${app_name}.app" ]]; then
        print_skip "$name"
        return 0
    fi

    echo -n "  ⏳ $name 다운로드 중..."
    if ! curl -fsSL "$url" -o "$dmg_path"; then
        echo " 실패"
        FAILED_ITEMS+=("$name")
        return 1
    fi
    echo -n " 설치 중..."

    local mount_output mount_point
    if ! mount_output=$(hdiutil attach "$dmg_path" -nobrowse 2>&1); then
        echo " 실패 (마운트)"
        FAILED_ITEMS+=("$name")
        rm -f "$dmg_path"
        return 1
    fi
    mount_point=$(echo "$mount_output" | grep -o '/Volumes/[^"]*' | head -1)

    if [[ -d "${mount_point}/${app_name}.app" ]]; then
        cp -R "${mount_point}/${app_name}.app" /Applications/
        echo " 완료"
    else
        echo " 실패 (앱 없음)"
        FAILED_ITEMS+=("$name")
    fi

    hdiutil detach "$mount_point" &>/dev/null
    rm -f "$dmg_path"
}

# ===== 설치 함수 =====

install_homebrew() {
    print_section "🍺 Homebrew"

    if command -v brew &>/dev/null; then
        print_skip "Homebrew"
    else
        echo -n "  ⏳ Homebrew 설치 중..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
        grep -q 'brew shellenv' ~/.zprofile 2>/dev/null || \
            echo "eval \"\$(${HOMEBREW_PREFIX}/bin/brew shellenv)\"" >> ~/.zprofile
        eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
        echo " 완료"
    fi

    echo -n "  ↻ 업데이트 중..."
    brew update &>/dev/null
    echo " 완료"
}

install_cli_tools() {
    print_section "📦 CLI 도구"

    _install_cli() { brew_install formula "$1" "$1"; }
    run_with_progress CLI_TOOLS _install_cli
}

install_warp() {
    print_section "🚀 Warp"
    install_dmg_app "Warp" "$WARP_DMG_URL"
}

install_cask_apps() {
    print_section "📦 Cask 앱"

    _install_cask() {
        local name="${1%%:*}" pkg="${1##*:}"
        brew_install cask "$name" "$pkg"
    }
    run_with_progress CASK_APPS _install_cask
}

install_python() {
    print_section "🐍 Python"

    if uv python install &>/dev/null; then
        print_ok "Python (최신 버전)"
    else
        print_skip "Python"
    fi

    if uv tool install ruff &>/dev/null; then
        print_ok "ruff (uv)"
    else
        print_skip "ruff"
    fi
}

install_vscode_extensions() {
    print_section "🔌 VS Code 확장"

    local vscode="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

    if [[ ! -f "$vscode" ]]; then
        print_warn "VS Code 미설치 (건너뜀)"
        return
    fi

    # code 명령어 심볼릭 링크
    if [[ ! -L /usr/local/bin/code ]]; then
        sudo mkdir -p /usr/local/bin
        sudo ln -sf "$vscode" /usr/local/bin/code
        print_ok "code 명령어 설정"
    else
        print_skip "code 명령어"
    fi

    # 확장 설치
    local installed
    installed=$("$vscode" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    _install_ext() {
        local ext=$1 ext_lower
        ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        if echo "$installed" | grep -q "^${ext_lower}$"; then
            echo "✓ $ext (이미 설치됨)"
        elif "$vscode" --install-extension "$ext" &>/dev/null; then
            echo "✓ $ext"
        else
            echo "✗ $ext"
            FAILED_ITEMS+=("VS Code: $ext")
        fi
    }
    run_with_progress VSCODE_EXTENSIONS _install_ext
}

setup_shell() {
    print_section "⚙️  쉘 설정"

    # fzf 키바인딩
    local fzf_install="${HOMEBREW_PREFIX}/opt/fzf/install"
    if grep -q "fzf" ~/.zshrc 2>/dev/null; then
        print_skip "fzf 키바인딩"
    elif [[ -f "$fzf_install" ]]; then
        "$fzf_install" --all &>/dev/null
        print_ok "fzf 키바인딩"
    else
        print_warn "fzf 미설치 (건너뜀)"
    fi

    # alias 설정
    if grep -q "# Custom alias" ~/.zshrc 2>/dev/null; then
        print_skip "alias"
    else
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
        print_ok "alias 추가됨"
    fi
}

# ===== UI =====

print_header() {
    cat << EOF

══════════════════════════════════════════
  🚀 Mac 개발 환경 설정 스크립트
══════════════════════════════════════════
📝 로그: $LOG_FILE
📝 에러: $ERR_FILE
EOF
}

print_footer() {
    echo ""
    echo "══════════════════════════════════════════"

    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        echo "⚠️  설치 실패 항목:"
        printf "  • %s\n" "${FAILED_ITEMS[@]}"
        echo ""
    fi

    cat << 'EOF'
✅ 완료!

📋 설치 후 필요한 작업:
──────────────────────────────────────────
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
    setup_logging
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
    cleanup
    exec zsh -l
}

main
