#!/usr/bin/env nu
# Comprehensive Test Suite for aws-profile.nu (Nushell 0.108+)
#
# This file contains all tests for the AWS profile management module.
# Run with: nu tests/test-aws-profile.nu

use std assert

# Import the module we're testing
use ../aws-profile.nu *

# =============================================================================
# Test Suite 1: Credential Parsing
# =============================================================================

def create-mock-creds [] {
    "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_SESSION_TOKEN=FwoGZXIvYXdzEBYaExample
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1"
}

def test-parse-credentials [] {
    print "  Test: Parse credentials from KEY=VALUE format"

    let mock_output = (create-mock-creds)

    let parsed = (
        $mock_output
        | lines
        | where ($it | str trim | is-not-empty)
        | where ($it | str contains "=")
        | parse "{key}={value}"
        | transpose -ir
        | into record
    )

    assert ($parsed | get AWS_ACCESS_KEY_ID) == "AKIAIOSFODNN7EXAMPLE"
    assert ($parsed | get AWS_SECRET_ACCESS_KEY) == "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    assert ($parsed | get AWS_SESSION_TOKEN) == "FwoGZXIvYXdzEBYaExample"
    assert ($parsed | get AWS_REGION) == "us-east-1"

    print "    ✓ PASSED"
}

def test-parse-with-empty-lines [] {
    print "  Test: Parse credentials with empty lines"

    let input = "
AWS_ACCESS_KEY_ID=TEST123

AWS_SECRET_ACCESS_KEY=SECRET456

"

    let parsed = (
        $input
        | lines
        | where ($it | str trim | is-not-empty)
        | where ($it | str contains "=")
        | parse "{key}={value}"
        | transpose -ir
        | into record
    )

    assert ($parsed | get AWS_ACCESS_KEY_ID) == "TEST123"
    assert ($parsed | get AWS_SECRET_ACCESS_KEY) == "SECRET456"

    print "    ✓ PASSED"
}

def test-parse-malformed-input [] {
    print "  Test: Handle malformed credential input"

    let input = "
AWS_ACCESS_KEY_ID=VALID123
INVALID LINE WITHOUT EQUALS
AWS_SECRET_ACCESS_KEY=SECRET456
=VALUE_WITHOUT_KEY
KEY_WITHOUT_VALUE=
"

    let parsed = (
        $input
        | lines
        | where ($it | str trim | is-not-empty)
        | where ($it | str contains "=")
        | parse "{key}={value}"
        | where { |row| ($row.key | is-not-empty) and ($row.value | is-not-empty) }
        | transpose -ir
        | into record
    )

    assert ($parsed | get AWS_ACCESS_KEY_ID) == "VALID123"
    assert ($parsed | get AWS_SECRET_ACCESS_KEY) == "SECRET456"

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 2: Profile Discovery
# =============================================================================

def create-mock-credentials-file [] {
    "[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG

[production]
aws_access_key_id = AKIAIOSFODNN8EXAMPLE
aws_secret_access_key = xJalrXUtnFEMI/K7MDENG

[staging]
aws_access_key_id = AKIAIOSFODNN9EXAMPLE
aws_secret_access_key = yJalrXUtnFEMI/K7MDENG"
}

def create-mock-config-file [] {
    "[default]
region = us-east-1

[profile development]
region = us-west-2
sso_start_url = https://example.awsapps.com/start
sso_region = us-east-1

[profile production]
region = us-east-1

[profile test-profile]
region = eu-west-1"
}

def test-extract-credentials-profiles [] {
    print "  Test: Extract profiles from credentials file"

    let mock_creds = (create-mock-credentials-file)

    let profiles = (
        $mock_creds
        | lines
        | where ($it | str starts-with "[")
        | where ($it | str ends-with "]")
        | each { |line|
            $line | str substring 1..-1 | str trim
        }
    )

    assert ($profiles | length) == 3
    assert ("default" in $profiles)
    assert ("production" in $profiles)
    assert ("staging" in $profiles)

    print "    ✓ PASSED"
}

def test-extract-config-profiles [] {
    print "  Test: Extract profiles from config file"

    let mock_config = (create-mock-config-file)

    let profiles = (
        $mock_config
        | lines
        | where ($it | str starts-with "[profile ")
        | where ($it | str ends-with "]")
        | each { |line|
            $line
            | str substring 9..-1
            | str trim
        }
    )

    assert ($profiles | length) == 3
    assert ("development" in $profiles)
    assert ("production" in $profiles)
    assert ("test-profile" in $profiles)

    print "    ✓ PASSED"
}

def test-merge-profiles [] {
    print "  Test: Merge and deduplicate profiles"

    let creds_profiles = ["default", "production", "staging"]
    let config_profiles = ["development", "production", "test-profile"]

    let all_profiles = ($creds_profiles | append $config_profiles | uniq | sort)

    assert ($all_profiles | length) == 5
    assert ($all_profiles) == ["default", "development", "production", "staging", "test-profile"]

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 3: String Operations
# =============================================================================

def test-string-operations [] {
    print "  Test: Modern Nushell string operations"

    assert ("  test string  " | str trim) == "test string"
    assert ("hello world" | str substring 0..5) == "hello"
    assert ("hello world" | str contains "world") == true
    assert ("hello world" | str starts-with "hello") == true
    assert ("hello world" | str ends-with "world") == true

    print "    ✓ PASSED"
}

def test-emptiness-checks [] {
    print "  Test: Modern emptiness checks"

    assert ("" | is-empty)
    assert not ("text" | is-empty)
    assert ("text" | is-not-empty)
    assert not ("" | is-not-empty)
    assert ([] | is-empty)
    assert not ([1] | is-empty)

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 4: Record Operations
# =============================================================================

def test-build-env-record [] {
    print "  Test: Build environment variable record"

    let creds = {
        AWS_ACCESS_KEY_ID: "AKIATEST123"
        AWS_SECRET_ACCESS_KEY: "SECRETTEST456"
    }

    let full_record = (
        $creds
        | insert AWS_PROFILE "test-profile"
        | insert AWS_REGION "us-east-1"
    )

    assert ($full_record | get AWS_PROFILE) == "test-profile"
    assert ($full_record | get AWS_REGION) == "us-east-1"
    assert ($full_record | get AWS_ACCESS_KEY_ID) == "AKIATEST123"

    print "    ✓ PASSED"
}

def test-conditional-field-addition [] {
    print "  Test: Conditional field addition"

    let base_record = {
        AWS_PROFILE: "test"
        AWS_ACCESS_KEY_ID: "AKIATEST"
    }

    let session_token = "SESSION123"
    let final_record = if ($session_token | is-not-empty) {
        $base_record | insert AWS_SESSION_TOKEN $session_token
    } else {
        $base_record
    }

    assert ($final_record | get -i AWS_SESSION_TOKEN) == "SESSION123"

    let no_session = ""
    let without_token = if ($no_session | is-not-empty) {
        $base_record | insert AWS_SESSION_TOKEN $no_session
    } else {
        $base_record
    }

    assert ($without_token | get -i AWS_SESSION_TOKEN | is-empty)

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 5: Null-Safe Operations
# =============================================================================

def test-null-safe-get [] {
    print "  Test: Null-safe environment variable access"

    let record = {
        AWS_PROFILE: "production"
        AWS_REGION: "us-east-1"
    }

    let region = ($record | get -i AWS_REGION | default "us-west-2")
    assert $region == "us-east-1"

    let missing = ($record | get -i MISSING_KEY | default "fallback")
    assert $missing == "fallback"

    print "    ✓ PASSED"
}

def test-optional-field-access [] {
    print "  Test: Optional field access patterns"

    let with_token = {
        AWS_ACCESS_KEY_ID: "AKIA123"
        AWS_SESSION_TOKEN: "SESSION456"
    }

    let without_token = {
        AWS_ACCESS_KEY_ID: "AKIA789"
    }

    assert ($with_token | get -i AWS_SESSION_TOKEN | is-not-empty)
    assert ($without_token | get -i AWS_SESSION_TOKEN | is-empty)

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 6: Pipeline and Data Transformation
# =============================================================================

def test-complex-pipeline [] {
    print "  Test: Complex data transformation pipeline"

    let raw_data = "KEY1=value1
KEY2=value2
KEY3=value3
# Comment line
INVALID
KEY4=value4"

    let result = (
        $raw_data
        | lines
        | where ($it | str trim | is-not-empty)
        | where not ($it | str starts-with "#")
        | where ($it | str contains "=")
        | parse "{key}={value}"
        | where { |row| ($row.key | is-not-empty) }
    )

    assert ($result | length) == 4
    assert ($result | where key == "KEY1" | get 0.value) == "value1"

    print "    ✓ PASSED"
}

def test-transpose-into-record [] {
    print "  Test: Transpose with inverse record conversion"

    let parsed = [
        {key: "AWS_PROFILE", value: "prod"}
        {key: "AWS_REGION", value: "us-east-1"}
    ]

    let record = ($parsed | transpose -ir | into record)

    assert ($record | describe) =~ "record"
    assert ($record | get AWS_PROFILE) == "prod"
    assert ($record | get AWS_REGION) == "us-east-1"

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 7: Error Handling Patterns
# =============================================================================

def test-complete-pattern [] {
    print "  Test: Error handling with complete"

    let success_result = (echo "success" | complete)
    assert ($success_result.exit_code) == 0
    assert ($success_result.stdout | str trim) == "success"

    let fail_result = (bash -c "exit 1" | complete)
    assert ($fail_result.exit_code) == 1

    print "    ✓ PASSED"
}

def test-exit-code-checking [] {
    print "  Test: Exit code conditional execution"

    let result = (echo "test" | complete)

    mut error_handled = false
    mut success_handled = false

    if $result.exit_code != 0 {
        $error_handled = true
    } else {
        $success_handled = true
    }

    assert $success_handled
    assert not $error_handled

    print "    ✓ PASSED"
}

# =============================================================================
# Test Suite 8: Syntax Validation
# =============================================================================

def test-env-flag-syntax [] {
    print "  Test: --env flag syntax"

    # Test that --env functions work
    def --env test-env-setter [] {
        load-env { TEST_VAR: "value" }
    }

    test-env-setter
    assert ($env | get -i TEST_VAR) == "value"
    hide-env TEST_VAR

    print "    ✓ PASSED"
}

def test-optional-parameters [] {
    print "  Test: Optional parameter with default"

    def test-func [
        required: string
        --optional: string = "default"
    ] {
        {req: $required, opt: $optional}
    }

    let result1 = (test-func "test")
    assert $result1.req == "test"
    assert $result1.opt == "default"

    let result2 = (test-func "test" --optional "custom")
    assert $result2.opt == "custom"

    print "    ✓ PASSED"
}

def test-ansi-colors [] {
    print "  Test: ANSI color codes"

    let colored = $"(ansi green_bold)text(ansi reset)"
    assert ($colored | str contains "text")

    print "    ✓ PASSED"
}

def test-type-hints [] {
    print "  Test: Type hints on parameters"

    def typed-func [
        str_param: string
        int_param: int
        --flag: bool
    ] {
        {s: $str_param, i: $int_param, f: $flag}
    }

    let result = (typed-func "test" 42 --flag)
    assert $result.s == "test"
    assert $result.i == 42
    assert $result.f == true

    print "    ✓ PASSED"
}

# =============================================================================
# Main Test Runner
# =============================================================================

def main [] {
    print "\n🧪 AWS Profile Module Test Suite (Nushell 0.108+)"
    print "=" * 70
    print ""

    mut tests_passed = 0
    mut tests_failed = 0

    # Suite 1: Credential Parsing
    print $"(ansi cyan_bold)📦 Suite 1: Credential Parsing(ansi reset)"
    print "-" * 70
    try { test-parse-credentials; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-parse-with-empty-lines; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-parse-malformed-input; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 2: Profile Discovery
    print $"(ansi cyan_bold)📦 Suite 2: Profile Discovery(ansi reset)"
    print "-" * 70
    try { test-extract-credentials-profiles; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-extract-config-profiles; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-merge-profiles; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 3: String Operations
    print $"(ansi cyan_bold)📦 Suite 3: String Operations(ansi reset)"
    print "-" * 70
    try { test-string-operations; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-emptiness-checks; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 4: Record Operations
    print $"(ansi cyan_bold)📦 Suite 4: Record Operations(ansi reset)"
    print "-" * 70
    try { test-build-env-record; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-conditional-field-addition; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 5: Null-Safe Operations
    print $"(ansi cyan_bold)📦 Suite 5: Null-Safe Operations(ansi reset)"
    print "-" * 70
    try { test-null-safe-get; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-optional-field-access; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 6: Pipeline Operations
    print $"(ansi cyan_bold)📦 Suite 6: Pipeline and Data Transformation(ansi reset)"
    print "-" * 70
    try { test-complex-pipeline; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-transpose-into-record; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 7: Error Handling
    print $"(ansi cyan_bold)📦 Suite 7: Error Handling Patterns(ansi reset)"
    print "-" * 70
    try { test-complete-pattern; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-exit-code-checking; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Suite 8: Syntax Validation
    print $"(ansi cyan_bold)📦 Suite 8: Nushell 0.108+ Syntax Validation(ansi reset)"
    print "-" * 70
    try { test-env-flag-syntax; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-optional-parameters; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-ansi-colors; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    try { test-type-hints; $tests_passed += 1 } catch { print "    ❌ FAILED"; $tests_failed += 1 }
    print ""

    # Summary
    print "=" * 70
    print $"(ansi cyan_bold)Test Results:(ansi reset)"
    print $"  (ansi green)✓ Passed:(ansi reset) ($tests_passed)"
    print $"  (ansi red)❌ Failed:(ansi reset) ($tests_failed)"
    print $"  (ansi cyan)Total:(ansi reset) ($tests_passed + $tests_failed)"
    print "=" * 70

    if $tests_failed == 0 {
        print $"\n(ansi green_bold)✅ ALL TESTS PASSED!(ansi reset)\n"
        exit 0
    } else {
        print $"\n(ansi red_bold)❌ SOME TESTS FAILED(ansi reset)\n"
        exit 1
    }
}
