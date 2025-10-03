#!/usr/bin/env nu
# Complete AWS Authentication System for Nushell
# 
# This script provides comprehensive AWS authentication functionality including:
# - Regular profile login
# - AWS SSO authentication  
# - Temporary credential generation
# - Interactive profile selection with fzf
# - Credential management (status, clearing)
# - Profile listing and discovery
#
# All functions use --env to properly export credentials to the calling shell
#
# Usage:
#   aws-login [profile] [--sso] [--temp]     # Main login function
#   aws-profiles                             # List available profiles
#   aws-status                               # Show current credential status
#   aws-clear                                # Clear all AWS credentials
#   select-aws-profile [--sso]               # Interactive profile selection
#   awsl                                     # Short alias for aws-login

# =============================================================================
# CORE AWS AUTHENTICATION FUNCTIONS
# =============================================================================

# Main AWS login function with SSO and temporary credential support
export def --env aws-login [
    profile: string = "default"  # AWS profile to use
    --sso                        # Use AWS SSO login
    --temp                       # Get temporary credentials
] {
    print $"🔐 AWS Login for profile: (ansi cyan)($profile)(ansi reset)"
    
    # Handle SSO login first if requested
    if $sso {
        print "Starting SSO login..."
        let sso_result = (aws sso login --profile $profile | complete)
        if $sso_result.exit_code != 0 {
            print $"❌ SSO login failed: ($sso_result.stderr)"
            return
        }
        print "✅ SSO login completed"
    }
    
    # Get credentials using AWS CLI
    let creds_result = if $temp {
        print "Getting temporary credentials..."
        aws sts get-session-token --profile $profile --duration-seconds 3600 | complete
    } else {
        print "Exporting existing credentials..."
        aws configure export-credentials --profile $profile --format env-no-export | complete
    }
    
    if $creds_result.exit_code != 0 {
        print $"❌ Failed to get credentials: ($creds_result.stderr)"
        return
    }
    
    if $temp {
        # Parse temporary credentials from STS response
        let temp_creds = ($creds_result.stdout | from json | get Credentials)
        load-env {
            AWS_ACCESS_KEY_ID: $temp_creds.AccessKeyId
            AWS_SECRET_ACCESS_KEY: $temp_creds.SecretAccessKey  
            AWS_SESSION_TOKEN: $temp_creds.SessionToken
            AWS_PROFILE: $profile
        }
        print $"✅ Temporary credentials loaded (expires: ($temp_creds.Expiration))"
    } else {
        # Parse regular credentials from export-credentials
        let cred_pairs = ($creds_result.stdout
        | lines
        | where ($it | str trim | str length) > 0
        | where ($it | str contains "=")
        | each { |line|
            let parts = ($line | str trim | split row "=" | take 2)
            if ($parts | length) == 2 {
                { key: ($parts | get 0 | str trim), value: ($parts | get 1 | str trim) }
            }
        }
        | compact)
        
        # Convert to record for load-env and add profile
        mut env_record = ($cred_pairs | reduce -f {} { |item, acc| $acc | insert $item.key $item.value })
        $env_record = ($env_record | insert "AWS_PROFILE" $profile)
        load-env $env_record
        
        print $"✅ Credentials exported for profile: (ansi green)($profile)(ansi reset)"
    }
    
    # Show current status
    print $"   Access Key: (ansi yellow)($env.AWS_ACCESS_KEY_ID? | default 'not set' | str substring 0..8)...(ansi reset)"
    print $"   Region: (ansi cyan)($env.AWS_DEFAULT_REGION? | default $env.AWS_REGION? | default 'not set')(ansi reset)"
    
    # Test credentials
    let test_result = (aws sts get-caller-identity | complete)
    if $test_result.exit_code == 0 {
        let identity = ($test_result.stdout | from json)
        print $"   Account: (ansi green)($identity.Account)(ansi reset)"
        print $"   User/Role: (ansi green)($identity.Arn | split row '/' | last)(ansi reset)"
    } else {
        print $"   Status: (ansi red)⚠️ Could not validate credentials(ansi reset)"
    }
}

# =============================================================================
# INTERACTIVE PROFILE SELECTION
# =============================================================================

# Interactive AWS profile selector with fzf integration
export def --env select-aws-profile [
    --sso   # Use SSO login for the selected profile
] {
    # Check if fzf is available
    if not (which fzf | is-not-empty) {
        print "❌ fzf is required for interactive profile selection"
        print "💡 Install fzf or use: aws-login <profile-name>"
        return
    }
    
    # Get available profiles
    let profiles = (aws-profiles)
    
    if ($profiles | is-empty) {
        print "❌ No AWS profiles found"
        print "💡 Configure profiles with: aws configure"
        return
    }
    
    # Use fzf to select a profile
    let selected_profile = ($profiles | str join "\n" | fzf --prompt "Select AWS Profile: ")
    
    if ($selected_profile | str trim | str length) == 0 {
        print "❌ No profile selected"
        return
    }
    
    # Use the aws-login system
    if $sso {
        print $"🔐 Using SSO login for profile: (ansi cyan)($selected_profile)(ansi reset)"
        aws-login $selected_profile --sso
    } else {
        print $"🔐 Logging in with profile: (ansi cyan)($selected_profile)(ansi reset)"
        aws-login $selected_profile
    }
}

# =============================================================================
# CREDENTIAL MANAGEMENT FUNCTIONS
# =============================================================================

# Clear all AWS credentials from environment
export def --env aws-clear [] {
    let aws_vars = ["AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_SESSION_TOKEN" "AWS_PROFILE" "AWS_DEFAULT_REGION" "AWS_REGION"]
    
    for var in $aws_vars {
        if ($var in ($env | columns)) {
            hide-env $var
        }
    }
    
    print "🧹 AWS credentials cleared"
}

# Show current AWS credential status
export def aws-status [] {
    print "📊 Current AWS Status:"
    print $"   Profile: (ansi green)($env.AWS_PROFILE? | default 'not set')(ansi reset)"
    print $"   Access Key: (ansi cyan)($env.AWS_ACCESS_KEY_ID? | default 'not set' | str substring 0..8)...(ansi reset)"
    print $"   Region: (ansi cyan)($env.AWS_DEFAULT_REGION? | default $env.AWS_REGION? | default 'not set')(ansi reset)"
    
    let test_result = (aws sts get-caller-identity | complete)
    if $test_result.exit_code == 0 {
        let identity = ($test_result.stdout | from json)
        print $"   Account: (ansi green)($identity.Account)(ansi reset)"
        print $"   User: (ansi green)($identity.Arn | split row '/' | last)(ansi reset)"
        print $"   Status: (ansi green)✓ Valid(ansi reset)"
    } else {
        print $"   Status: (ansi red)✗ Invalid or not set(ansi reset)"
    }
}

# List all available AWS profiles from credentials and config files
export def aws-profiles [] {
    let creds_file = "~/.aws/credentials" | path expand
    let config_file = "~/.aws/config" | path expand
    
    mut profiles = []
    
    if ($creds_file | path exists) {
        let cred_profiles = (open $creds_file 
            | lines 
            | where ($it | str starts-with "[") and ($it | str ends-with "]")
            | each { |line| $line | str replace -r '^\[(.+)\]$' '${1}' })
        $profiles = ($profiles | append $cred_profiles)
    }
    
    if ($config_file | path exists) {
        let conf_profiles = (open $config_file 
            | lines
            | where ($it | str starts-with "[profile ") and ($it | str ends-with "]")
            | each { |line| $line | str replace -r '^\[profile (.+)\]$' '${1}' })
        $profiles = ($profiles | append $conf_profiles)
    }
    
    $profiles | uniq | sort
}

# =============================================================================
# CONVENIENCE ALIASES
# =============================================================================

# Short alias for aws-login
export alias awsl = aws-login

# Alias for interactive selection
export alias aws-select = select-aws-profile