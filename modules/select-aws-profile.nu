# Modern AWS profile selector using the improved aws-login system
#
# Dependencies:
#   * aws-login-fixed.nu (automatically sourced in config.nu)
#   * fzf (for interactive selection)
#
# Installation:
#   Already included in config.nu
#
# Usage:
#   select-aws-profile [--sso]
#
# This is now a wrapper around the improved aws-login system with interactive selection

# Interactive AWS profile selector with fzf
export def --env main [
    --sso   # Use SSO login for the selected profile
] {
    # Check if fzf is available
    if not (which fzf | is-not-empty) {
        print "❌ fzf is required for interactive profile selection"
        print "💡 Install fzf or use: aws-login <profile-name>"
        return
    }
    
    # Get available profiles using the new aws-profiles function
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
    
    # Use the new aws-login system
    if $sso {
        print $"🔐 Using SSO login for profile: (ansi cyan)($selected_profile)(ansi reset)"
        aws-login $selected_profile --sso
    } else {
        print $"🔐 Logging in with profile: (ansi cyan)($selected_profile)(ansi reset)"
        aws-login $selected_profile
    }
}
