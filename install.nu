#!/usr/bin/env nu

# Nu-Config Installation Script
# Comprehensive Nushell configuration with multi-completer system

def main [] {
    print "🚀 Installing Nu-Config - Comprehensive Nushell Setup..."
    print "This will install all dependencies and configure your Nushell environment.\n"
    
    # Check if running on supported system
    let os = $nu.os-info.name
    if $os not-in ["linux", "macos"] {
        error make {msg: "❌ This script supports Linux and macOS only"}
    }
    
    log_info $"🖥️  Detected OS: ($os)"
    
    # Step 1: Install Homebrew
    install_homebrew
    
    # Step 2: Install core tools
    install_core_tools
    
    # Step 3: Install Node.js and npm tools
    install_nodejs_tools
    
    # Step 4: Install Rust and Cargo
    install_rust
    
    # Step 5: Install Nushell plugins
    install_nushell_plugins
    
    # Step 6: Setup configuration
    setup_configuration
    
    # Step 7: Register plugins
    register_plugins
    
    # Step 8: Initialize completion systems
    initialize_completers
    
    # Step 9: Setup additional tools
    setup_additional_tools
    
    print_completion_message
}

def install_homebrew [] {
    if not (which brew | is-not-empty) {
        log_info "🍺 Installing Homebrew..."
        try {
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Linux
            if $nu.os-info.name == "linux" {
                let shellenv = 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
                $shellenv | save --append ~/.bashrc
                $shellenv | save --append ~/.zshrc
                # Source for current session
                do { $env.PATH = ($env.PATH | prepend "/home/linuxbrew/.linuxbrew/bin") }
            }
            log_success "Homebrew installed successfully"
        } catch {
            log_error "Failed to install Homebrew"
            exit 1
        }
    } else {
        log_success "Homebrew already installed"
    }
}

def install_core_tools [] {
    log_info "📦 Installing core tools and completion engines..."
    
    let tools = [
        "nushell"      # Main shell
        "carapace"     # Universal completer  
        "fish"         # Fish shell for completions
        "jc"           # JSON converter
        "git"          # Version control
        "curl"         # HTTP client
        "zoxide"       # Directory jumper
        "starship"     # Cross-shell prompt
        "libgit2"      # Git library for plugins
    ]
    
    for tool in $tools {
        try {
            log_info $"Installing ($tool)..."
            ^brew install $tool
        } catch {
            log_warning $"Failed to install ($tool) - continuing anyway"
        }
    }
    
    log_success "Core tools installation completed"
}

def install_nodejs_tools [] {
    # Install Node.js if needed
    if not (which node | is-not-empty) {
        log_info "📗 Installing Node.js..."
        ^brew install node
    }
    
    # Install Inshellisense
    log_info "🤖 Installing Inshellisense AI completer..."
    try {
        ^npm install -g "@microsoft/inshellisense@0.0.1-rc.21"
        log_success "Inshellisense installed"
    } catch {
        log_warning "Inshellisense installation failed - AI completions won't be available"
    }
}

def install_rust [] {
    if not (which cargo | is-not-empty) {
        log_info "🦀 Installing Rust and Cargo..."
        try {
            bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
            # Add cargo to PATH for current session
            $env.PATH = ($env.PATH | prepend "~/.cargo/bin" | path expand)
            log_success "Rust and Cargo installed"
        } catch {
            log_error "Failed to install Rust"
            exit 1
        }
    } else {
        log_success "Rust and Cargo already installed"
    }
}

def install_nushell_plugins [] {
    log_info "🔌 Installing Nushell plugins..."
    
    let plugins = [
        "nu_plugin_highlight"    # Syntax highlighting
        "nu_plugin_hcl"         # HCL support
        "nu_plugin_query"       # Advanced querying
        "nu_plugin_polars"      # DataFrame operations
        "nu_plugin_formats"     # Additional file formats
        "nu_plugin_gstat"       # Git status
        "nu_plugin_inc"         # Version incrementing
    ]
    
    for plugin in $plugins {
        try {
            log_info $"Installing ($plugin)..."
            ^cargo install $plugin
            log_success $"($plugin) installed"
        } catch {
            log_warning $"($plugin) installation failed - plugin won't be available"
        }
    }
    
    log_success "Plugin installation completed"
}

def setup_configuration [] {
    # Backup existing config
    let config_dir = ($nu.default-config-dir | path expand)
    if ($config_dir | path exists) {
        let backup_dir = $"($config_dir).backup.$(date now | format date '%Y%m%d_%H%M%S')"
        log_warning $"📁 Backing up existing config to ($backup_dir)"
        try {
            mv $config_dir $backup_dir
        } catch {
            log_error "Failed to backup existing configuration"
            exit 1
        }
    }
    
    # Clone configuration
    log_info "📥 Cloning nu-config repository..."
    try {
        ^git clone "https://github.com/lprior-repo/nu-config.git" $config_dir
        log_success "Configuration cloned successfully"
    } catch {
        log_error "Failed to clone configuration repository"
        exit 1
    }
}

def register_plugins [] {
    log_info "🔗 Registering Nushell plugins..."
    
    let plugins = [
        "nu_plugin_highlight"
        "nu_plugin_hcl"  
        "nu_plugin_query"
        "nu_plugin_polars"
        "nu_plugin_formats"
    ]
    
    # Register working plugins
    for plugin in $plugins {
        let plugin_path = $"~/.cargo/bin/($plugin)"
        if ($plugin_path | path expand | path exists) {
            try {
                nu -c $"plugin add ($plugin_path)"
                log_success $"($plugin) registered"
            } catch {
                log_warning $"Failed to register ($plugin)"
            }
        } else {
            log_warning $"($plugin) not found at ($plugin_path)"
        }
    }
    
    # Try to register plugins with known issues
    let problematic_plugins = ["nu_plugin_gstat", "nu_plugin_inc"]
    for plugin in $problematic_plugins {
        let plugin_path = $"~/.cargo/bin/($plugin)"
        if ($plugin_path | path expand | path exists) {
            try {
                nu -c $"plugin add ($plugin_path)"
                log_success $"($plugin) registered"
            } catch {
                log_warning $"($plugin) registration failed - may have compatibility issues"
            }
        }
    }
}

def initialize_completers [] {
    log_info "⚡ Initializing completion systems..."
    
    # Setup Carapace
    try {
        mkdir ~/.cache/carapace
        ^carapace nushell | save --force ~/.cache/carapace/init.nu
        log_success "Carapace initialized"
    } catch {
        log_warning "Carapace initialization failed"
    }
    
    # Setup Starship
    if (which starship | is-not-empty) {
        try {
            mkdir ~/.cache/starship  
            ^starship init nu | save --force ~/.cache/starship/init.nu
            log_success "Starship prompt initialized"
        } catch {
            log_warning "Starship initialization failed"
        }
    } else {
        log_info "Install starship with 'brew install starship' for enhanced prompt"
    }
    
    # Setup Zoxide
    if (which zoxide | is-not-empty) {
        try {
            mkdir ~/.cache/zoxide
            ^zoxide init nushell | save --force ~/.cache/zoxide/init.nu
            log_success "Zoxide directory jumping initialized"
        } catch {
            log_warning "Zoxide initialization failed"
        }
    } else {
        log_warning "Zoxide not found - directory jumping won't be available"
    }
}

def setup_additional_tools [] {
    log_info "🛠️  Configuring additional tools..."
    
    # Create necessary cache directories
    mkdir ~/.cache
    mkdir ~/.cache/carapace
    mkdir ~/.cache/starship  
    mkdir ~/.cache/zoxide
    
    # Set up git if not configured
    try {
        let git_name = (^git config --global user.name | complete)
        if $git_name.exit_code != 0 {
            log_info "⚙️  Configure git with: git config --global user.name 'Your Name'"
            log_info "⚙️  Configure git with: git config --global user.email 'your.email@example.com'"
        }
    } catch {
        log_info "⚙️  Git configuration recommended for full functionality"
    }
    
    log_success "Additional tools configured"
}

def print_completion_message [] {
    print ""
    log_success "🎉 Nu-Config installation complete!"
    print ""
    print "┌─────────────────────────────────────────────────────────────┐"
    print "│                   🚀 INSTALLATION COMPLETE                  │"
    print "└─────────────────────────────────────────────────────────────┘"
    print ""
    print "✨ Your Nushell is now supercharged with:"
    print ""
    print "🔧 Multi-Completer System:"
    print "   • Carapace (universal completion engine)"
    print "   • Fish (excellent for git and development tools)"
    print "   • Inshellisense (AI-powered completions)"
    print ""
    print "🔌 Powerful Plugins:"
    print "   • Polars (DataFrame operations)"
    print "   • Query (SQL, JSON, XML, HTML)"
    print "   • Highlight (syntax highlighting)"
    print "   • Formats (EML, ICS, INI, plist, VCF)"
    print "   • HCL (HashiCorp Configuration Language)"
    print ""
    print "📝 Enhanced Features:"
    print "   • Git aliases and AWS tools"
    print "   • Fuzzy search capabilities"
    print "   • Interactive directory navigation"
    print "   • Custom completions for popular tools"
    print ""
    print "🎯 Next Steps:"
    print "   1. Start a new terminal session"
    print "   2. Run: nu"
    print "   3. Try tab completion with various commands"
    print "   4. Explore git aliases: git st, git co, git br"
    print "   5. Use 'plugin list' to see all active plugins"
    print ""
    print "📚 Documentation:"
    print $"   Config location: ($nu.default-config-dir)"
    print "   Repository: https://github.com/lprior-repo/nu-config"
    print "   Help: nu --help"
    print ""
    print "💡 Pro Tips:"
    print "   • Use 'z <directory>' for smart directory jumping"
    print "   • Try 'git st' instead of 'git status'"
    print "   • Press TAB for intelligent completions"
    print "   • Use 'help <command>' for built-in documentation"
    print ""
    log_success "Happy Nushelling! 🐚✨"
}

# Logging functions with colors
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