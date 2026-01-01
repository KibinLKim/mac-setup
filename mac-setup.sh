#!/bin/bash

# ============================================
# Mac 개발 환경 설정 스크립트
# ============================================

# 설정
CLI_TOOLS=(git gh eza bat ripgrep fzf jq yq lazygit node pnpm uv httpie tldr watch)
GUI_APPS=(
    "Warp:warp"
    "Visual Studio Code:visual-studio-code"
    "Docker:docker"
    "Google Chrome:google-chrome"
    "Rectangle:rectangle"
    "Slack:slack"
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
)

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
    if ! command -v brew &> /dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo "  ✓ Homebrew 설치 완료"
    else
        echo "  ✓ Homebrew (이미 설치됨)"
    fi
    echo ""
}

# CLI 도구 설치
install_cli_tools() {
    print_section "📦 CLI 도구 설치..."
    for tool in "${CLI_TOOLS[@]}"; do
        if brew install "$tool" &>/dev/null; then
            echo "  ✓ $tool"
        else
            echo "  ✓ $tool (이미 설치됨)"
        fi
    done
    echo ""
}

# GUI 앱 설치
install_gui_apps() {
    print_section "🖥️  GUI 앱 설치..."
    for item in "${GUI_APPS[@]}"; do
        local app="${item%%:*}"
        local cask="${item##*:}"
        if [ ! -d "/Applications/$app.app" ]; then
            if brew install --cask "$cask" &>/dev/null; then
                echo "  ✓ $app"
            else
                echo "  ✗ $app (설치 실패)"
            fi
        else
            echo "  ✓ $app (이미 설치됨)"
        fi
    done
    echo ""
}

# Claude Code 설치
install_claude_code() {
    print_section "🤖 Claude Code 설치..."
    if command -v claude &> /dev/null; then
        echo "  ✓ Claude Code (이미 설치됨)"
    else
        if curl -fsSL https://claude.ai/install.sh | bash &>/dev/null; then
            echo "  ✓ Claude Code"
        else
            echo "  ✗ Claude Code (설치 실패)"
        fi
    fi
    echo ""
}

# Python 설치
install_python() {
    print_section "🐍 Python 설치..."
    uv python install &>/dev/null && echo "  ✓ Python (최신 버전)" || echo "  ✓ Python (이미 설치됨)"
    uv tool install ruff &>/dev/null && echo "  ✓ ruff" || echo "  ✓ ruff (이미 설치됨)"
    echo ""
}

# VS Code 확장 프로그램 설치
install_vscode_extensions() {
    print_section "🔌 VS Code 확장 프로그램 설치..."
    local vscode="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        "$vscode" --install-extension "$ext" &>/dev/null
        echo "  ✓ $ext"
    done
    echo ""
}

# fzf 키바인딩 설정
setup_fzf() {
    print_section "⚙️  fzf 키바인딩 설정..."
    $(brew --prefix)/opt/fzf/install --all &>/dev/null
    echo "  ✓ fzf 키바인딩"
    echo ""
}

# 쉘 alias 설정
setup_aliases() {
    print_section "🎨 쉘 alias 설정..."
    if ! grep -q "# Custom alias" ~/.zshrc; then
        cat >> ~/.zshrc << 'EOF'

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
    echo "💡 VS Code 'code' 명령어 활성화:"
    echo "Cmd+Shift+P → Shell Command: Install"
    echo "══════════════════════════════════════════"
    echo ""
}

# 메인 함수
main() {
    print_header
    install_homebrew
    install_cli_tools
    install_gui_apps
    install_claude_code
    install_python
    install_vscode_extensions
    setup_fzf
    setup_aliases
    print_footer
}

# 스크립트 실행
main
