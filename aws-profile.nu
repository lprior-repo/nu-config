# AWS Profile Management for Nushell 0.108+
#
# A comprehensive AWS profile and credential management system optimized for Nushell
# Supports regular profiles, SSO, and temporary credentials

# =============================================================================
# Core AWS Login Function
# =============================================================================

# Login to an AWS profile and export credentials to the environment
#
# Examples:
#   aws-login production
#   aws-login dev --sso
#   aws-login staging --duration 7200
export def --env aws-login [
    profile: string           # AWS profile name from ~/.aws/config
    --sso                     # Perform SSO login before getting credentials
    --duration: int = 3600    # Session duration in seconds (default: 1 hour)
] {
    print $"🔐 AWS Login: (ansi cyan_bold)($profile)(ansi reset)"

    # Step 1: SSO Login if requested
    if $sso {
        print "  → Initiating SSO login..."
        let sso_result = (aws sso login --profile $profile | complete)

        if $sso_result.exit_code != 0 {
            print $"(ansi red_bold)❌ SSO login failed(ansi reset)"
            print $"  Error: ($sso_result.stderr)"
            return
        }
        print $"(ansi green)  ✓ SSO login successful(ansi reset)"
    }

    # Step 2: Export credentials
    print "  → Exporting credentials..."
    let creds_result = (
        aws configure export-credentials
            --profile $profile
            --format env-no-export
        | complete
    )

    if $creds_result.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to export credentials(ansi reset)"
        print $"  Error: ($creds_result.stderr)"
        print $"\n(ansi yellow)💡 Tip(ansi reset): Make sure the profile '($profile)' exists in ~/.aws/config"
        return
    }

    # Step 3: Parse and set credentials
    let creds = (
        $creds_result.stdout
        | lines
        | where ($it | str trim | is-not-empty)
        | where ($it | str contains "=")
        | parse "{key}={value}"
        | transpose -ir
        | into record
    )

    # Validate we got credentials
    if ($creds | get -i AWS_ACCESS_KEY_ID | is-empty) {
        print $"(ansi red_bold)❌ No credentials found for profile(ansi reset)"
        return
    }

    # Build environment record
    let env_vars = {
        AWS_PROFILE: $profile
        AWS_ACCESS_KEY_ID: $creds.AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY: $creds.AWS_SECRET_ACCESS_KEY
    }

    # Add session token if present (for SSO or temporary credentials)
    let env_vars = if ($creds | get -i AWS_SESSION_TOKEN | is-not-empty) {
        $env_vars | insert AWS_SESSION_TOKEN $creds.AWS_SESSION_TOKEN
    } else {
        $env_vars
    }

    # Get and set region
    let region = (aws configure get region --profile $profile | complete)
    let env_vars = if $region.exit_code == 0 and ($region.stdout | str trim | is-not-empty) {
        let region_value = ($region.stdout | str trim)
        $env_vars
        | insert AWS_REGION $region_value
        | insert AWS_DEFAULT_REGION $region_value
    } else {
        $env_vars
    }

    # Load all environment variables at once
    load-env $env_vars

    # Step 4: Verify and display status
    print $"(ansi green_bold)✓ Credentials loaded successfully(ansi reset)"
    print $"  Profile: (ansi cyan)($profile)(ansi reset)"
    print $"  Access Key: (ansi yellow)($env.AWS_ACCESS_KEY_ID | str substring 0..12)...(ansi reset)"

    if ($env | get -i AWS_REGION | is-not-empty) {
        print $"  Region: (ansi cyan)($env.AWS_REGION)(ansi reset)"
    }

    # Validate with AWS STS
    print "\n  → Validating credentials..."
    let identity_result = (aws sts get-caller-identity | complete)

    if $identity_result.exit_code == 0 {
        let identity = ($identity_result.stdout | from json)
        print $"(ansi green_bold)✓ Credentials validated(ansi reset)"
        print $"  Account: (ansi green)($identity.Account)(ansi reset)"
        print $"  Identity: (ansi green)($identity.Arn | split row '/' | last)(ansi reset)"
    } else {
        print $"(ansi yellow)⚠ Could not validate credentials(ansi reset)"
        print $"  This may be temporary - try using AWS CLI commands"
    }
}

# =============================================================================
# Interactive Profile Selection
# =============================================================================

# Interactively select and login to an AWS profile using fzf
#
# Examples:
#   aws-select
#   aws-select --sso
export def --env aws-select [
    --sso  # Use SSO login for selected profile
] {
    # Check for fzf
    if (which fzf | is-empty) {
        print $"(ansi red_bold)❌ fzf is required(ansi reset)"
        print $"(ansi yellow)💡 Install: brew install fzf(ansi reset)  (or use your package manager)"
        return
    }

    # Get profiles
    let profiles = (aws-profiles)

    if ($profiles | is-empty) {
        print $"(ansi red_bold)❌ No AWS profiles found(ansi reset)"
        print $"(ansi yellow)💡 Configure: aws configure --profile <name>(ansi reset)"
        return
    }

    print $"📋 Found ($profiles | length) AWS profiles"

    # Interactive selection
    let selected = (
        $profiles
        | str join "\n"
        | fzf --height 40% --border --prompt "Select AWS Profile: " --preview-window hidden
        | str trim
    )

    if ($selected | is-empty) {
        print "❌ No profile selected"
        return
    }

    # Login with selected profile
    if $sso {
        aws-login $selected --sso
    } else {
        aws-login $selected
    }
}

# =============================================================================
# Profile Listing
# =============================================================================

# List all available AWS profiles from config and credentials files
#
# Examples:
#   aws-profiles
#   aws-profiles | where ($it | str contains "prod")
export def aws-profiles [] {
    let creds_file = ("~/.aws/credentials" | path expand)
    let config_file = ("~/.aws/config" | path expand)

    mut profiles = []

    # Parse credentials file
    if ($creds_file | path exists) {
        let cred_profiles = (
            open $creds_file
            | lines
            | where ($it | str starts-with "[")
            | where ($it | str ends-with "]")
            | each { |line|
                $line | str substring 1..-1 | str trim
            }
        )
        $profiles = ($profiles | append $cred_profiles)
    }

    # Parse config file
    if ($config_file | path exists) {
        let config_profiles = (
            open $config_file
            | lines
            | where ($it | str starts-with "[profile ")
            | where ($it | str ends-with "]")
            | each { |line|
                $line
                | str substring 9..-1  # Remove "[profile " prefix
                | str trim
            }
        )
        $profiles = ($profiles | append $config_profiles)
    }

    # Return unique, sorted list
    $profiles | uniq | sort
}

# =============================================================================
# Status and Information
# =============================================================================

# Display current AWS credential status and validate with AWS
#
# Examples:
#   aws-whoami
export def aws-whoami [] {
    print $"(ansi cyan_bold)📊 AWS Session Status(ansi reset)\n"

    # Check if we have credentials loaded
    let has_creds = ($env | get -i AWS_ACCESS_KEY_ID | is-not-empty)

    if not $has_creds {
        print $"(ansi yellow)⚠ No AWS credentials loaded(ansi reset)"
        print $"\n(ansi cyan)💡 Available commands:(ansi reset)"
        print "  • aws-login <profile>    - Login to a profile"
        print "  • aws-select             - Interactive profile selection"
        print "  • aws-profiles           - List available profiles"
        return
    }

    # Display loaded credentials
    print $"Profile:     (ansi green)($env | get -i AWS_PROFILE | default 'not set')(ansi reset)"
    print $"Access Key:  (ansi yellow)($env.AWS_ACCESS_KEY_ID | str substring 0..12)...(ansi reset)"
    print $"Region:      (ansi cyan)($env | get -i AWS_REGION | default $env | get -i AWS_DEFAULT_REGION | default 'not set')(ansi reset)"

    # Check for session token (indicates temporary/SSO credentials)
    if ($env | get -i AWS_SESSION_TOKEN | is-not-empty) {
        print $"Type:        (ansi magenta)Temporary/SSO credentials(ansi reset)"
    } else {
        print $"Type:        (ansi magenta)Long-term credentials(ansi reset)"
    }

    # Validate with AWS
    print $"\n(ansi cyan_bold)🔍 Validating with AWS...(ansi reset)"
    let identity_result = (aws sts get-caller-identity | complete)

    if $identity_result.exit_code == 0 {
        let identity = ($identity_result.stdout | from json)
        print $"(ansi green_bold)✓ Valid credentials(ansi reset)"
        print $"Account:     (ansi green)($identity.Account)(ansi reset)"
        print $"User ID:     (ansi green)($identity.UserId)(ansi reset)"
        print $"ARN:         (ansi green)($identity.Arn)(ansi reset)"
    } else {
        print $"(ansi red_bold)✗ Invalid or expired credentials(ansi reset)"
        print $"Error: ($identity_result.stderr | str trim)"
    }
}

# =============================================================================
# Credential Cleanup
# =============================================================================

# Clear all AWS credentials from the current shell environment
#
# Examples:
#   aws-logout
export def --env aws-logout [] {
    let aws_env_vars = [
        "AWS_PROFILE"
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
        "AWS_SESSION_TOKEN"
        "AWS_REGION"
        "AWS_DEFAULT_REGION"
    ]

    mut cleared = 0
    for var in $aws_env_vars {
        if ($env | get -i $var | is-not-empty) {
            hide-env $var
            $cleared = $cleared + 1
        }
    }

    if $cleared > 0 {
        print $"(ansi green_bold)✓ AWS credentials cleared(ansi reset) (($cleared) variables removed)"
    } else {
        print $"(ansi yellow)⚠ No AWS credentials were set(ansi reset)"
    }
}

# =============================================================================
# Advanced: Temporary Credentials via STS
# =============================================================================

# Get temporary AWS credentials via STS (useful for added security)
#
# Examples:
#   aws-temp production
#   aws-temp dev --duration 7200
export def --env aws-temp [
    profile: string           # Base AWS profile to use
    --duration: int = 3600    # Session duration in seconds
    --mfa: string             # MFA token code (if MFA is required)
] {
    print $"🔐 Getting temporary credentials for: (ansi cyan_bold)($profile)(ansi reset)"

    # Build STS command
    mut sts_args = [
        "sts" "get-session-token"
        "--profile" $profile
        "--duration-seconds" ($duration | into string)
    ]

    # Add MFA if provided
    if ($mfa | is-not-empty) {
        # Get MFA device ARN from AWS
        let mfa_devices_result = (aws iam list-mfa-devices --profile $profile | complete)
        if $mfa_devices_result.exit_code == 0 {
            let mfa_devices = ($mfa_devices_result.stdout | from json | get MFADevices)
            if ($mfa_devices | length) > 0 {
                let mfa_arn = ($mfa_devices | first | get SerialNumber)
                $sts_args = ($sts_args | append ["--serial-number" $mfa_arn "--token-code" $mfa])
            }
        }
    }

    # Get temporary credentials
    let temp_creds_result = (aws ...$sts_args | complete)

    if $temp_creds_result.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to get temporary credentials(ansi reset)"
        print $"Error: ($temp_creds_result.stderr)"
        return
    }

    let temp_creds = ($temp_creds_result.stdout | from json | get Credentials)

    # Set environment variables
    load-env {
        AWS_PROFILE: $profile
        AWS_ACCESS_KEY_ID: $temp_creds.AccessKeyId
        AWS_SECRET_ACCESS_KEY: $temp_creds.SecretAccessKey
        AWS_SESSION_TOKEN: $temp_creds.SessionToken
    }

    print $"(ansi green_bold)✓ Temporary credentials loaded(ansi reset)"
    print $"  Expires: (ansi yellow)($temp_creds.Expiration)(ansi reset)"
    print $"  Access Key: (ansi yellow)($temp_creds.AccessKeyId | str substring 0..12)...(ansi reset)"
}

# =============================================================================
# Utility: Assume Role
# =============================================================================

# Assume an IAM role and export temporary credentials
#
# Examples:
#   aws-assume-role arn:aws:iam::123456789012:role/MyRole
#   aws-assume-role arn:aws:iam::123456789012:role/MyRole --session-name my-session
export def --env aws-assume-role [
    role_arn: string          # ARN of the role to assume
    --session-name: string = "nushell-session"  # Session name
    --duration: int = 3600    # Session duration in seconds
    --profile: string = "default"  # AWS profile to use for assuming role
] {
    print $"🎭 Assuming role: (ansi cyan_bold)($role_arn)(ansi reset)"

    let assume_result = (
        aws sts assume-role
            --role-arn $role_arn
            --role-session-name $session_name
            --duration-seconds $duration
            --profile $profile
        | complete
    )

    if $assume_result.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to assume role(ansi reset)"
        print $"Error: ($assume_result.stderr)"
        return
    }

    let role_creds = ($assume_result.stdout | from json | get Credentials)

    load-env {
        AWS_ACCESS_KEY_ID: $role_creds.AccessKeyId
        AWS_SECRET_ACCESS_KEY: $role_creds.SecretAccessKey
        AWS_SESSION_TOKEN: $role_creds.SessionToken
        AWS_ASSUMED_ROLE: $role_arn
    }

    print $"(ansi green_bold)✓ Role assumed successfully(ansi reset)"
    print $"  Expires: (ansi yellow)($role_creds.Expiration)(ansi reset)"

    # Validate
    aws-whoami
}

# =============================================================================
# Aliases for Convenience
# =============================================================================

# Quick aliases for common operations
export alias awsl = aws-login
export alias awss = aws-select
export alias awsw = aws-whoami
export alias awso = aws-logout
export alias awsp = aws-profiles
export alias awst = aws-temp
export alias awsr = aws-assume-role
