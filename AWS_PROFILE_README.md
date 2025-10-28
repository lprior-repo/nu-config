# AWS Profile Management for Nushell

A modern, Nushell 0.108+ compatible AWS credential management system with SSO support, temporary credentials, and role assumption.

## Features

- ✅ **Nushell 0.108+ Compatible** - Uses modern Nushell syntax and best practices
- 🔐 **Multiple Authentication Methods** - Standard profiles, SSO, temporary credentials, and role assumption
- 🎯 **Interactive Profile Selection** - fzf integration for easy profile switching
- 📊 **Credential Validation** - Automatic validation with AWS STS
- 🧹 **Clean Environment Management** - Proper credential cleanup and isolation
- 🚀 **Fast and Efficient** - Minimal overhead, uses native Nushell features

## Installation

The system is automatically loaded via `config.nu`. The main file is located at:
```
~/.config/nushell/aws-profile.nu
```

### Prerequisites

- Nushell 0.108 or later
- AWS CLI v2 (with `configure export-credentials` support)
- `fzf` (optional, for interactive profile selection)

## Quick Start

### Basic Login

```nushell
# Login to a profile
aws-login production

# Or use the alias
awsl production
```

### Interactive Selection

```nushell
# Choose from available profiles with fzf
aws-select

# Or use the alias
awss
```

### Check Current Session

```nushell
# Show detailed session info
aws-whoami

# Or use the alias
awsw
```

### Logout

```nushell
# Clear all AWS credentials
aws-logout

# Or use the alias
awso
```

## Commands Reference

### Core Commands

#### `aws-login [profile] [--sso] [--duration]`

Login to an AWS profile and export credentials to the environment.

**Parameters:**
- `profile` (required) - AWS profile name from `~/.aws/config`
- `--sso` (optional) - Perform SSO login before getting credentials
- `--duration` (optional) - Session duration in seconds (default: 3600)

**Examples:**
```nushell
# Standard login
aws-login production

# SSO login
aws-login my-sso-profile --sso

# Custom duration
aws-login staging --duration 7200
```

**Output:**
- Validates credentials with AWS STS
- Shows account ID and identity
- Displays access key preview and region

#### `aws-select [--sso]`

Interactively select and login to an AWS profile using fzf.

**Parameters:**
- `--sso` (optional) - Use SSO login for selected profile

**Examples:**
```nushell
# Interactive selection
aws-select

# Interactive selection with SSO
aws-select --sso
```

**Requirements:**
- `fzf` must be installed

#### `aws-profiles`

List all available AWS profiles from config and credentials files.

**Examples:**
```nushell
# List all profiles
aws-profiles

# Filter profiles
aws-profiles | where ($it | str contains "prod")

# Count profiles
aws-profiles | length
```

**Output:**
Returns a list of unique profile names sorted alphabetically.

#### `aws-whoami`

Display current AWS credential status and validate with AWS.

**Examples:**
```nushell
# Show current session
aws-whoami

# Check if logged in
if (aws-whoami | complete | get exit_code) == 0 { "Logged in" } else { "Not logged in" }
```

**Output:**
- Profile name
- Access key ID (partial)
- Region
- Credential type (temporary/long-term)
- Account ID
- User/Role ARN

#### `aws-logout`

Clear all AWS credentials from the current shell environment.

**Examples:**
```nushell
# Logout
aws-logout

# Logout and confirm
aws-logout; aws-whoami
```

**Environment Variables Cleared:**
- `AWS_PROFILE`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `AWS_REGION`
- `AWS_DEFAULT_REGION`

### Advanced Commands

#### `aws-temp [profile] [--duration] [--mfa]`

Get temporary AWS credentials via STS (for added security).

**Parameters:**
- `profile` (required) - Base AWS profile to use
- `--duration` (optional) - Session duration in seconds (default: 3600)
- `--mfa` (optional) - MFA token code

**Examples:**
```nushell
# Get temporary credentials
aws-temp production

# With custom duration
aws-temp dev --duration 7200

# With MFA
aws-temp production --mfa 123456
```

#### `aws-assume-role [role_arn] [--session-name] [--duration] [--profile]`

Assume an IAM role and export temporary credentials.

**Parameters:**
- `role_arn` (required) - ARN of the role to assume
- `--session-name` (optional) - Session name (default: "nushell-session")
- `--duration` (optional) - Session duration in seconds (default: 3600)
- `--profile` (optional) - AWS profile to use (default: "default")

**Examples:**
```nushell
# Assume a role
aws-assume-role arn:aws:iam::123456789012:role/MyRole

# With custom session name
aws-assume-role arn:aws:iam::123456789012:role/MyRole --session-name my-session

# With custom duration
aws-assume-role arn:aws:iam::123456789012:role/MyRole --duration 7200
```

## Aliases

Quick shortcuts for common operations:

| Alias | Command | Description |
|-------|---------|-------------|
| `awsl` | `aws-login` | Login to profile |
| `awss` | `aws-select` | Interactive selection |
| `awsw` | `aws-whoami` | Show session info |
| `awso` | `aws-logout` | Logout/clear credentials |
| `awsp` | `aws-profiles` | List profiles |
| `awst` | `aws-temp` | Get temporary credentials |
| `awsr` | `aws-assume-role` | Assume role |

### Legacy Compatibility

These aliases provide backward compatibility with older config.nu:

| Alias | New Command |
|-------|-------------|
| `aws-status` | `aws-whoami` |
| `aws-clear` | `aws-logout` |

## Workflows

### Typical Daily Workflow

```nushell
# Morning: Select and login
aws-select --sso

# Check status
awsw

# Use AWS CLI normally
aws s3 ls
aws ec2 describe-instances

# Switch profiles
awsl staging

# End of day: Cleanup
awso
```

### SSO Workflow

```nushell
# Initial SSO login
aws-login my-sso-profile --sso

# Credentials are cached, subsequent logins don't need --sso
aws-login my-sso-profile

# When SSO expires, login again with --sso
aws-login my-sso-profile --sso
```

### Multi-Account Workflow

```nushell
# Work with multiple accounts using separate terminal sessions
# Terminal 1: Production
aws-login prod

# Terminal 2: Staging
aws-login staging

# Terminal 3: Development
aws-login dev

# Or switch in same terminal
aws-login prod
# ... do work ...
aws-logout
aws-login staging
```

### Temporary Credentials Workflow

```nushell
# Get temporary credentials for added security
aws-temp production --duration 3600

# Use for short-lived tasks
aws s3 sync ./local s3://bucket/

# Credentials auto-expire after duration
```

## Nushell 0.108+ Best Practices

This script follows modern Nushell best practices:

### 1. Environment Variable Management

```nushell
# ✅ Good: Use --env flag for functions that modify environment
export def --env aws-login [profile: string] {
    load-env { AWS_PROFILE: $profile }
}

# ❌ Bad: Without --env, changes don't persist
def aws-login [profile: string] {
    $env.AWS_PROFILE = $profile  # Won't export to caller
}
```

### 2. Credential Parsing

```nushell
# ✅ Good: Modern parsing with pipeline
let creds = (
    $output
    | lines
    | where ($it | str trim | is-not-empty)
    | parse "{key}={value}"
    | transpose -ir
    | into record
)

# ❌ Bad: Manual parsing with loops
```

### 3. Null Safety

```nushell
# ✅ Good: Use get -i for optional values
if ($env | get -i AWS_PROFILE | is-not-empty) { ... }

# ✅ Good: Use default for fallbacks
print ($env | get -i AWS_REGION | default "us-east-1")

# ❌ Bad: Direct access without checks
print $env.AWS_REGION  # May error if not set
```

### 4. Error Handling

```nushell
# ✅ Good: Use complete for error handling
let result = (aws sts get-caller-identity | complete)
if $result.exit_code != 0 {
    print $"Error: ($result.stderr)"
    return
}

# ❌ Bad: No error handling
let result = (aws sts get-caller-identity)
```

### 5. String Operations

```nushell
# ✅ Good: Use modern string methods
if ($str | is-not-empty) { ... }
$str | str trim
$str | str substring 0..10

# ❌ Bad: Legacy patterns
if ($str | str length) > 0 { ... }
```

## Troubleshooting

### No profiles found

```nushell
# Configure AWS CLI first
aws configure --profile myprofile

# Or check existing profiles
cat ~/.aws/config
cat ~/.aws/credentials
```

### SSO login fails

```nushell
# Ensure AWS CLI v2 is installed
aws --version  # Should be 2.x

# Check SSO configuration
aws configure list-profiles
aws configure get sso_start_url --profile my-sso-profile
```

### Credentials not persisting

```nushell
# Make sure using --env functions
aws-login profile  # ✅ Good
source aws-profile.nu; aws-login profile  # ❌ Bad (function not using --env)
```

### Region not set

```nushell
# Set default region in AWS config
aws configure set region us-east-1 --profile myprofile

# Or set manually
$env.AWS_REGION = "us-east-1"
$env.AWS_DEFAULT_REGION = "us-east-1"
```

## Testing

The module includes a comprehensive pure-Nushell test suite with 20 test cases across 8 suites.

### Run All Tests

```nushell
# Run the complete test suite
nu tests/test-aws-profile.nu

# Expected output: All 20 tests passing
```

### Test Coverage

- ✅ Credential parsing from KEY=VALUE format
- ✅ Profile discovery from AWS config files
- ✅ String operations (trim, substring, contains)
- ✅ Record building and manipulation
- ✅ Null-safe operations with `get -i`
- ✅ Pipeline transformations
- ✅ Error handling with `complete`
- ✅ Nushell 0.108+ syntax validation

See `TEST_RESULTS.md` for detailed test documentation.

### Manual Testing

```nushell
# Test profile listing
aws-profiles

# Test login
aws-login default

# Verify environment variables
$env | where ($it.name | str starts-with "AWS")

# Test credential validation
aws sts get-caller-identity

# Test cleanup
aws-logout
$env | where ($it.name | str starts-with "AWS")  # Should be empty
```

## Migration from Old System

If you're migrating from the inline AWS functions in config.nu:

### Changes

1. **Function renames:**
   - `aws-status` → `aws-whoami` (alias provided for compatibility)
   - `aws-clear` → `aws-logout` (alias provided for compatibility)
   - `select-aws-profile` → `aws-select`

2. **New features:**
   - `aws-temp` - Get temporary STS credentials
   - `aws-assume-role` - Assume IAM roles
   - Better error handling and validation
   - More detailed output and status information

3. **Parameter changes:**
   - `aws-login` no longer has `--temp` flag (use `aws-temp` instead)
   - All duration parameters now accept integers (seconds)

### Migration Example

```nushell
# Old
aws-login production --temp
aws-status
aws-clear

# New (aliases work for compatibility)
aws-temp production
aws-status  # alias for aws-whoami
aws-clear   # alias for aws-logout

# Or use new names
aws-temp production
aws-whoami
aws-logout
```

## Contributing

### Style Guidelines

- Use `export def` for public functions
- Use `--env` flag for functions that modify environment
- Include type hints on parameters
- Add doc comments with examples
- Use `ansi` codes for colored output
- Handle errors gracefully with `complete`
- Validate inputs before processing

### Testing New Features

```nushell
# Reload after changes
source ~/.config/nushell/config.nu

# Or directly source the file
use ~/.config/nushell/aws-profile.nu *

# Test the new function
help my-new-function
my-new-function --help
```

## License

Part of the nu-config repository.

## Support

For issues or questions:
1. Check this README
2. Review the source code in `aws-profile.nu`
3. Check Nushell documentation: https://www.nushell.sh/
4. AWS CLI documentation: https://docs.aws.amazon.com/cli/

---

**Last Updated:** 2025-10-28
**Nushell Version:** 0.108+
**AWS CLI Version:** 2.x
