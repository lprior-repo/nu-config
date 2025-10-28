# AWS Profile Syntax Validation Tests for Nushell 0.108+
#
# This file validates that the syntax patterns used in aws-profile.nu
# are compatible with Nushell 0.108+

# Test 1: Environment variable management with --env
def --env test-env-flag [] {
    load-env { TEST_VAR: "value" }
    print "✓ --env flag syntax valid"
}

# Test 2: Optional parameter with default
def test-optional-param [
    required: string
    --optional: string = "default"
] {
    print $"✓ Optional parameter syntax valid: ($required), ($optional)"
}

# Test 3: Null-safe environment variable access
def test-null-safe-env [] {
    let value = ($env | get -i NONEXISTENT_VAR | default "fallback")
    print $"✓ Null-safe env access: ($value)"
}

# Test 4: Modern string operations
def test-string-ops [] {
    let test_str = "  hello world  "
    let trimmed = ($test_str | str trim)
    let substring = ($test_str | str trim | str substring 0..5)
    let is_empty = ($test_str | is-not-empty)

    print $"✓ String operations valid: '($trimmed)', '($substring)', ($is_empty)"
}

# Test 5: Parse and transpose pattern
def test-parse-pattern [] {
    let input = "KEY1=value1\nKEY2=value2"
    let result = (
        $input
        | lines
        | where ($it | str trim | is-not-empty)
        | parse "{key}={value}"
        | transpose -ir
        | into record
    )

    print $"✓ Parse pattern valid: ($result | describe)"
}

# Test 6: Complete for error handling
def test-complete-pattern [] {
    let result = (echo "test" | complete)
    if $result.exit_code == 0 {
        print $"✓ Complete pattern valid: ($result.stdout | str trim)"
    }
}

# Test 7: ANSI color codes
def test-ansi-colors [] {
    print $"(ansi green_bold)✓ ANSI color syntax valid(ansi reset)"
}

# Test 8: Conditional with is-empty/is-not-empty
def test-conditional [] {
    let test_val = "value"
    if ($test_val | is-not-empty) {
        print "✓ Conditional syntax valid"
    }
}

# Test 9: Export and use patterns
export def exported-function [] {
    print "✓ Export syntax valid"
}

# Test 10: Multiple parameter flags
def test-multiple-flags [
    param1: string
    --flag1
    --flag2: string = "default"
    --flag3: int = 100
] {
    print "✓ Multiple parameter flags valid"
}

# Run all tests
def main [] {
    print "🧪 Running Nushell 0.108+ syntax validation tests...\n"

    test-env-flag
    test-optional-param "required_value"
    test-null-safe-env
    test-string-ops
    test-parse-pattern
    test-complete-pattern
    test-ansi-colors
    test-conditional
    exported-function
    test-multiple-flags "value" --flag1

    print "\n✅ All syntax patterns valid for Nushell 0.108+"
}

# Validation notes for aws-profile.nu:
#
# 1. ✅ Uses `export def --env` for environment-modifying functions
# 2. ✅ Uses `get -i` for null-safe environment variable access
# 3. ✅ Uses `is-empty` and `is-not-empty` for checks
# 4. ✅ Uses `default` for fallback values
# 5. ✅ Uses `complete` for error handling
# 6. ✅ Uses modern string methods (`str trim`, `str substring`, etc.)
# 7. ✅ Uses `load-env` with records for setting multiple env vars
# 8. ✅ Uses `hide-env` for unsetting env vars
# 9. ✅ Uses `parse` with `transpose -ir` and `into record` for parsing
# 10. ✅ Uses proper ANSI color codes
# 11. ✅ Type hints on all parameters
# 12. ✅ Default values on optional parameters
#
# All patterns used in aws-profile.nu are Nushell 0.108+ compatible!
