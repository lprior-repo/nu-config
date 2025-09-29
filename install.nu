#!/usr/bin/env nu

# Nu-Config Installation Script
# Installs Nushell with comprehensive completion setup

def main [] {
    print "🚀 Installing Nu-Config..."
    
    # Check if running on supported system
    let os = $nu.os-info.name
    if $os not-in ["linux", "macos"] {
        error make {msg: "This script supports Linux and macOS only"}
    }
    
    # Install Homebrew if not present
    if not (which brew | is-not-empty) {
        log_info "Installing Homebrew..."
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
        
        # Add Homebrew to PATH for Linux
        if $os == "linux" {
            'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' | save --append ~/.bashrc
        }
        log_success "Homebrew installed"
    } else {
        log_success "Homebrew already installed"
    }
    
    # Install Nushell and dependencies
    log_info "Installing Nushell and completion engines..."
    ^brew install nushell carapace fish jc
    log_success "Core tools installed"
    
    # Install Node.js and npm if needed
    if not (which npm | is-not-empty) {
        log_info "Installing Node.js and npm..."
        ^brew install node
        log_success "Node.js and npm installed"
    }
    
    # Install Inshellisense
    log_info "Installing Inshellisense..."
    ^npm install -g "@microsoft/inshellisense@0.0.1-rc.21"
    log_success "Inshellisense installed"
    
    # Install Rust and Cargo if needed
    if not (which cargo | is-not-empty) {
        log_info "Installing Rust and Cargo..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        log_success "Rust and Cargo installed"
    }
    
    # Install Nushell plugins
    log_info "Installing Nushell plugins..."
    ^cargo install nu_plugin_highlight nu_plugin_hcl nu_plugin_query nu_plugin_polars nu_plugin_formats nu_plugin_gstat nu_plugin_inc
    log_success "Nushell plugins installed"
    
    # Backup existing Nushell config
    let config_dir = $nu.default-config-dir
    if ($config_dir | path exists) {
        log_warning "Backing up existing Nushell config"
        mv $config_dir $"($config_dir).backup"
    }
    
    # Clone the configuration
    log_info "Cloning nu-config repository..."
    ^git clone https://github.com/your-username/nu-config.git $config_dir
    log_success "Configuration cloned"
    
    # Register plugins with Nushell
    log_info "Registering Nushell plugins..."
    try {
        plugin add ~/.cargo/bin/nu_plugin_highlight
        plugin add ~/.cargo/bin/nu_plugin_hcl  
        plugin add ~/.cargo/bin/nu_plugin_query
        plugin add ~/.cargo/bin/nu_plugin_polars
        plugin add ~/.cargo/bin/nu_plugin_formats
        # Note: gstat and inc may have compatibility issues with some Nushell versions
        try { plugin add ~/.cargo/bin/nu_plugin_gstat } catch { log_warning "gstat plugin registration failed - version compatibility issue" }
        try { plugin add ~/.cargo/bin/nu_plugin_inc } catch { log_warning "inc plugin registration failed - version compatibility issue" }
        log_success "Core plugins registered"
    } catch {
        log_warning "Plugin registration failed - you may need to do this manually"
    }
    
    # Initialize carapace for Nushell
    log_info "Setting up Carapace for Nushell..."
    mkdir ~/.cache/carapace
    try {
        ^carapace nushell | save ~/.cache/carapace/init.nu
        log_success "Carapace configured"
    } catch {
        log_warning "Carapace setup failed"
    }
    
    # Initialize starship if available
    if (which starship | is-not-empty) {
        log_info "Setting up Starship prompt..."
        mkdir ~/.cache/starship
        ^starship init nu | save ~/.cache/starship/init.nu
        log_success "Starship configured"
    }
    
    # Initialize zoxide if available
    if (which zoxide | is-not-empty) {
        log_info "Setting up Zoxide..."
        mkdir ~/.cache/zoxide
        ^zoxide init nushell | save ~/.cache/zoxide/init.nu
        log_success "Zoxide configured"
    } else {
        log_warning "Zoxide not found - install with 'brew install zoxide' for directory jumping"
    }
    
    print ""
    log_success "🎉 Nu-Config installation complete!"
    print ""
    print "To start using your new configuration:"
    print "  1. Start a new terminal session"
    print "  2. Run: nu"
    print "  3. Enjoy enhanced completions and productivity features!"
    print ""
    print "Key features:"
    print "  • Multi-completer system (Carapace, Fish, Inshellisense)"
    print "  • Custom git aliases and AWS tools"
    print "  • Syntax highlighting and query plugins"
    print "  • Fuzzy search and directory navigation"
    print ""
    print $"For help and customization, see: ($config_dir)/README.md"
}

def log_info [message: string] {
    print $"(ansi blue)ℹ️  ($message)(ansi reset)"
}

def log_success [message: string] {
    print $"(ansi green)✅ ($message)(ansi reset)"
}

def log_warning [message: string] {
    print $"(ansi yellow)⚠️  ($message)(ansi reset)"
}

def log_error [message: string] {
    print $"(ansi red)❌ ($message)(ansi reset)"
}