#!/bin/bash

# Nu-Config Installation Script
# Installs Nushell with comprehensive completion setup

set -e

echo "🚀 Installing Nu-Config..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on supported system
if [[ "$OSTYPE" != "linux-gnu"* ]] && [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script supports Linux and macOS only"
    exit 1
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
else
    log_success "Homebrew already installed"
fi

# Install Nushell and dependencies
log_info "Installing Nushell and completion engines..."
brew install nushell carapace fish jc
log_success "Core tools installed"

# Install Node.js and npm if needed
if ! command -v npm &> /dev/null; then
    log_info "Installing Node.js and npm..."
    brew install node
    log_success "Node.js and npm installed"
fi

# Install Inshellisense
log_info "Installing Inshellisense..."
npm install -g @microsoft/inshellisense@0.0.1-rc.21
log_success "Inshellisense installed"

# Install Rust and Cargo if needed
if ! command -v cargo &> /dev/null; then
    log_info "Installing Rust and Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    log_success "Rust and Cargo installed"
fi

# Install Nushell plugins
log_info "Installing Nushell plugins..."
cargo install nu_plugin_highlight nu_plugin_hcl nu_plugin_query
log_success "Nushell plugins installed"

# Backup existing Nushell config
if [ -d ~/.config/nushell ]; then
    log_warning "Backing up existing Nushell config to ~/.config/nushell.backup"
    mv ~/.config/nushell ~/.config/nushell.backup
fi

# Clone the configuration
log_info "Cloning nu-config repository..."
git clone https://github.com/your-username/nu-config.git ~/.config/nushell
log_success "Configuration cloned"

# Register plugins with Nushell
log_info "Registering Nushell plugins..."
nu -c "plugin add ~/.cargo/bin/nu_plugin_highlight; plugin add ~/.cargo/bin/nu_plugin_hcl; plugin add ~/.cargo/bin/nu_plugin_query" || log_warning "Plugin registration failed - you may need to do this manually"

# Initialize carapace for Nushell
log_info "Setting up Carapace for Nushell..."
mkdir -p ~/.cache/carapace
carapace nushell > ~/.cache/carapace/init.nu || log_warning "Carapace setup failed"

# Initialize starship if available
if command -v starship &> /dev/null; then
    log_info "Setting up Starship prompt..."
    mkdir -p ~/.cache/starship
    starship init nu > ~/.cache/starship/init.nu
    log_success "Starship configured"
fi

# Initialize zoxide if available
if command -v zoxide &> /dev/null; then
    log_info "Setting up Zoxide..."
    mkdir -p ~/.cache/zoxide
    zoxide init nushell > ~/.cache/zoxide/init.nu
    log_success "Zoxide configured"
else
    log_warning "Zoxide not found - install with 'brew install zoxide' for directory jumping"
fi

echo
log_success "🎉 Nu-Config installation complete!"
echo
echo "To start using your new configuration:"
echo "  1. Start a new terminal session"
echo "  2. Run: nu"
echo "  3. Enjoy enhanced completions and productivity features!"
echo
echo "Key features:"
echo "  • Multi-completer system (Carapace, Fish, Inshellisense)"
echo "  • Custom git aliases and AWS tools"
echo "  • Syntax highlighting and query plugins"
echo "  • Fuzzy search and directory navigation"
echo
echo "For help and customization, see: ~/.config/nushell/README.md"