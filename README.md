# Nu-Config

A comprehensive Nushell configuration with multiple intelligent completion engines, custom modules, and enhanced productivity features.

## Features

### 🚀 Multi-Completer System
- **Carapace** - Universal command-line completion (default/fallback)
- **Fish** - Excellent for git, nu, and development tools  
- **Inshellisense** - AI-powered completions for modern tools (docker, kubectl, terraform, ansible)
- **Custom Completions** - AWS, bat, gh, git, make, npm, rg, uv, zellij, zoxide

### 📦 Modules & Aliases
- **Git aliases** - Convenient git shortcuts from nu_scripts
- **AWS profile selector** - Easy AWS profile management
- **Fuzzy search** - Enhanced fuzzy searching capabilities
- **JC integration** - JSON conversion for command outputs
- **Zoxide menu** - Interactive directory selection

### 🔌 Plugins
- **nu_plugin_highlight** - Syntax highlighting for various file formats
- **nu_plugin_hcl** - HCL (HashiCorp Configuration Language) support
- **nu_plugin_query** - Advanced querying capabilities for JSON, XML, HTML, SQL
- **nu_plugin_polars** - Extremely fast columnar operations using DataFrames
- **nu_plugin_formats** - Support for EML, ICS, INI, plist, and VCF formats
- **nu_plugin_gstat** - Git repository status as structured data
- **nu_plugin_inc** - Increment values and versions (e.g., semver)

### 🎨 UI Enhancements
- Dark theme with syntax highlighting
- Custom menus for completion and history
- Vi-mode editing with custom keybindings

## Installation

### Prerequisites
- [Nushell](https://www.nushell.sh/) (latest version)
- [Homebrew](https://brew.sh/) (for package management)

### Quick Install
```bash
curl -sSL https://raw.githubusercontent.com/your-username/nu-config/main/install.sh | bash
```

### Manual Installation

1. **Install Required Software:**
   ```bash
   # Install Nushell
   brew install nushell
   
   # Install completion engines
   brew install carapace fish jc
   npm install -g @microsoft/inshellisense@0.0.1-rc.21
   
   # Install Nushell plugins
   cargo install nu_plugin_highlight nu_plugin_hcl nu_plugin_query nu_plugin_polars nu_plugin_formats nu_plugin_gstat nu_plugin_inc
   ```

2. **Clone and Setup Config:**
   ```bash
   git clone https://github.com/your-username/nu-config.git ~/.config/nushell
   
   # Register plugins  
   nu -c "plugin add ~/.cargo/bin/nu_plugin_highlight; plugin add ~/.cargo/bin/nu_plugin_hcl; plugin add ~/.cargo/bin/nu_plugin_query; plugin add ~/.cargo/bin/nu_plugin_polars; plugin add ~/.cargo/bin/nu_plugin_formats"
   ```

3. **Start Nushell:**
   ```bash
   nu
   ```

## Configuration Structure

```
~/.config/nushell/
├── config.nu              # Main configuration file
├── env.nu                 # Environment variables
├── git-aliases.nu         # Git command aliases
├── zoxide-menu.nu         # Zoxide interactive menu
├── completions/           # Custom completion scripts
│   ├── aws-completions.nu
│   ├── git-completions.nu
│   └── ... (more)
└── modules/               # Nushell modules
    ├── fuzzy-1.nu
    ├── fuzzy-2.nu
    ├── select-aws-profile.nu
    └── jc.nu
```

## Completer Router Logic

The configuration automatically chooses the best completer for each command:

- `git`, `nu`, `asdf` → **Fish completer** (excellent git integration)
- `docker`, `kubectl`, `terraform`, `ansible` → **Inshellisense** (AI-powered)
- `__zoxide_z`, `__zoxide_zi` → **Zoxide completer** (directory navigation)
- Everything else → **Carapace** (universal fallback)

## Key Features

### Smart Error Handling
- Automatic fallback to Carapace if other completers fail
- Try-catch blocks prevent crashes
- Graceful degradation ensures completions always work

### Custom Commands
- `aws-login` - AWS authentication helper
- `aws-profiles` - List available AWS profiles
- Fuzzy search functions for enhanced navigation

### Enhanced Git Experience
- Comprehensive git aliases
- Fish-powered git completions for branches and commits
- Integrated with existing git workflows

## Customization

### Adding New Completers
Edit the `external_completer` function in `config.nu`:

```nushell
match $spans.0 {
    'your-command' => $your_custom_completer
    _ => $carapace_completer
} | do $in $spans
```

### Adding New Modules
1. Place module files in `modules/` directory
2. Add `use ~/.config/nushell/modules/your-module.nu *` to `config.nu`

## Troubleshooting

### Completions Not Working
1. Verify all completers are installed: `which carapace fish inshellisense`
2. Check Nushell config syntax: `nu -c "echo 'Config OK'"`
3. Restart Nushell session

### Plugin Issues
1. Re-register plugins: `nu -c "plugin add ~/.cargo/bin/nu_plugin_*"`
2. Check plugin status: `plugin list`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a fresh Nushell installation
5. Submit a pull request

## License

MIT License - feel free to use and modify as needed.

## Credits

- [Nushell](https://www.nushell.sh/) - The amazing shell this config is built for
- [nu_scripts](https://github.com/nushell/nu_scripts) - Source of many modules and completions
- [Carapace](https://github.com/carapace-sh/carapace-bin) - Universal completion engine
- [Fish Shell](https://fishshell.com/) - Excellent completion system
- [Inshellisense](https://github.com/microsoft/inshellisense) - AI-powered completions