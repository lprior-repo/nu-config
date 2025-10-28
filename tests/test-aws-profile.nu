#!/usr/bin/env nu
# Unit tests for aws-profile.nu using Nushell standard library
# Run with: nu tests/test-aws-profile.nu

use std assert

# Import the module we're testing
use ../aws-profile.nu *

# =============================================================================
# Test Helper Functions
# =============================================================================

# Create mock AWS credential output
def create-mock-creds [] {
    "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_SESSION_TOKEN=FwoGZXIvYXdzEBYaExample
AWS_REGION=us-east-1
AWS_DEFAULT_REGION=us-east-1"
}

# Create mock AWS credentials file
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

# Create mock AWS config file
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

# =============================================================================
# Test Suite 1: Credential Parsing
# =============================================================================

# Test parsing KEY=VALUE format
def test-parse-credentials [] {
    print "Test: Parse credentials from KEY=VALUE format"

    let mock_output = (create-mock-creds)

    # Simulate the parsing logic from aws-login
    let parsed = (
        $mock_output
        | lines
        | where ($it | str trim | is-not-empty)
        | where ($it | str contains "=")
        | parse "{key}={value}"
        | transpose -ir
        | into record
    )

    # Assertions
    assert ($parsed | get AWS_ACCESS_KEY_ID) == "AKIAIOSFODNN7EXAMPLE" "Access key should match"
    assert ($parsed | get AWS_SECRET_ACCESS_KEY) == "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" "Secret key should match"
    assert ($parsed | get AWS_SESSION_TOKEN) == "FwoGZXIvYXdzEBYaExample" "Session token should match"
    assert ($parsed | get AWS_REGION) == "us-east-1" "Region should match"

    print "  ✓ PASSED"
}

# Test handling of empty lines
def test-parse-with-empty-lines [] {
    print "Test: Parse credentials with empty lines"

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

    print "  ✓ PASSED"
}

# Test handling of malformed input
def test-parse-malformed-input [] {
    print "Test: Handle malformed credential input"

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

    # Should only have the valid entries
    assert ($parsed | get AWS_ACCESS_KEY_ID) == "VALID123"
    assert ($parsed | get AWS_SECRET_ACCESS_KEY) == "SECRET456"

    print "  ✓ PASSED"
}

# =============================================================================
# Test Suite 2: Profile Discovery
# =============================================================================

# Test extracting profiles from credentials file
def test-extract-credentials-profiles [] {
    print "Test: Extract profiles from credentials file"

    let mock_creds = (create-mock-credentials-file)

    # Simulate the logic from aws-profiles
    let profiles = (
        $mock_creds
        | lines
        | where ($it | str starts-with "[")
        | where ($it | str ends-with "]")
        | each { |line|
            $line | str substring 1..-1 | str trim
        }
    )

    assert ($profiles | length) == 3 "Should find 3 profiles"
    assert ("default" in $profiles) "Should find default profile"
    assert ("production" in $profiles) "Should find production profile"
    assert ("staging" in $profiles) "Should find staging profile"

    print "  ✓ PASSED"
}

# Test extracting profiles from config file
def test-extract-config-profiles [] {
    print "Test: Extract profiles from config file"

    let mock_config = (create-mock-config-file)

    # Simulate the logic from aws-profiles
    let profiles = (
        $mock_config
        | lines
        | where ($it | str starts-with "[profile ")
        | where ($it | str ends-with "]")
        | each { |line|
            $line
            | str substring 9..-1  # Remove "[profile " prefix
            | str trim
        }
    )

    assert ($profiles | length) == 3 "Should find 3 profiles"
    assert ("development" in $profiles) "Should find development profile"
    assert ("production" in $profiles) "Should find production profile"
    assert ("test-profile" in $profiles) "Should find test-profile"

    print "  ✓ PASSED"
}

# Test merging and deduplicating profiles
def test-merge-profiles [] {
    print "Test: Merge and deduplicate profiles"

    let creds_profiles = ["default", "production", "staging"]
    let config_profiles = ["development", "production", "test-profile"]

    # Merge and deduplicate
    let all_profiles = ($creds_profiles | append $config_profiles | uniq | sort)

    assert ($all_profiles | length) == 5 "Should have 5 unique profiles"
    assert ($all_profiles) == ["default", "development", "production", "staging", "test-profile"] "Should be sorted"

    print "  ✓ PASSED"
}

# =============================================================================
# Test Suite 3: String Operations
# =============================================================================

# Test modern string operations
def test-string-operations [] {
    print "Test: Modern Nushell string operations"

    # Test str trim
    let trimmed = ("  test string  " | str trim)
    assert $trimmed == "test string" "str trim should remove whitespace"

    # Test str substring
    let substring = ("hello world" | str substring 0..5)
    assert $substring == "hello" "str substring should extract substring"

    # Test str contains
    let contains = ("hello world" | str contains "world")
    assert $contains == true "str contains should find substring"

    # Test str starts-with
    let starts = ("hello world" | str starts-with "hello")
    assert $starts == true "str starts-with should match prefix"

    # Test str ends-with
    let ends = ("hello world" | str ends-with "world")
    assert $ends == true "str ends-with should match suffix"

    print "  ✓ PASSED"
}

# Test is-empty and is-not-empty
def test-emptiness-checks [] {
    print "Test: Modern emptiness checks"

    assert ("" | is-empty) "Empty string should be empty"
    assert not ("text" | is-empty) "Non-empty string should not be empty"

    assert ("text" | is-not-empty) "Non-empty string should be not-empty"
    assert not ("" | is-not-empty) "Empty string should not be not-empty"

    assert ([] | is-empty) "Empty list should be empty"
    assert not ([1] | is-empty) "Non-empty list should not be empty"

    print "  ✓ PASSED"
}

# =============================================================================
# Test Suite 4: Record Operations
# =============================================================================

# Test building records from parsed data
def test-build-env-record [] {
    print "Test: Build environment variable record"

    let creds = {
        AWS_ACCESS_KEY_ID: "AKIATEST123"
        AWS_SECRET_ACCESS_KEY: "SECRETTEST456"
    }

    # Add additional fields
    let full_record = (
        $creds
        | insert AWS_PROFILE "test-profile"
        | insert AWS_REGION "us-east-1"
    )

    assert ($full_record | get AWS_PROFILE) == "test-profile"
    assert ($full_record | get AWS_REGION) == "us-east-1"
    assert ($full_record | get AWS_ACCESS_KEY_ID) == "AKIATEST123"

    print "  ✓ PASSED"
}

# Test conditional field addition
def test-conditional-field-addition [] {
    print "Test: Conditional field addition"

    let base_record = {
        AWS_PROFILE: "test"
        AWS_ACCESS_KEY_ID: "AKIATEST"
    }

    # Add session token if present (simulating SSO/temp credentials)
    let session_token = "SESSION123"

    let final_record = if ($session_token | is-not-empty) {
        $base_record | insert AWS_SESSION_TOKEN $session_token
    } else {
        $base_record
    }

    assert ($final_record | get -i AWS_SESSION_TOKEN) == "SESSION123"

    # Test without session token
    let no_session = ""
    let without_token = if ($no_session | is-not-empty) {
        $base_record | insert AWS_SESSION_TOKEN $no_session
    } else {
        $base_record
    }

    assert ($without_token | get -i AWS_SESSION_TOKEN | is-empty)

    print "  ✓ PASSED"
}

# =============================================================================
# Test Suite 5: Null-Safe Operations
# =============================================================================

# Test null-safe get
def test-null-safe-get [] {
    print "Test: Null-safe environment variable access"

    let record = {
        AWS_PROFILE: "production"
        AWS_REGION: "us-east-1"
    }

    # Safe get with fallback
    let region = ($record | get -i AWS_REGION | default "us-west-2")
    assert $region == "us-east-1" "Should use existing value"

    let missing = ($record | get -i MISSING_KEY | default "fallback")
    assert $missing == "fallback" "Should use default for missing key"

    print "  ✓ PASSED"
}

# Test optional field access
def test-optional-field-access [] {
    print "Test: Optional field access patterns"

    let with_token = {
        AWS_ACCESS_KEY_ID: "AKIA123"
        AWS_SESSION_TOKEN: "SESSION456"
    }

    let without_token = {
        AWS_ACCESS_KEY_ID: "AKIA789"
    }

    # Access optional field
    assert ($with_token | get -i AWS_SESSION_TOKEN | is-not-empty)
    assert ($without_token | get -i AWS_SESSION_TOKEN | is-empty)

    print "  ✓ PASSED"
}

# =============================================================================
# Test Suite 6: Pipeline and Data Transformation
# =============================================================================

# Test complex pipeline
def test-complex-pipeline [] {
    print "Test: Complex data transformation pipeline"

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

    assert ($result | length) == 4 "Should parse 4 valid entries"
    assert ($result | where key == "KEY1" | get 0.value) == "value1"

    print "  ✓ PASSED"
}

# Test transpose and into record
def test-transpose-into-record [] {
    print "Test: Transpose with inverse record conversion"

    let parsed = [
        {key: "AWS_PROFILE", value: "prod"}
        {key: "AWS_REGION", value: "us-east-1"}
    ]

    let record = ($parsed | transpose -ir | into record)

    assert ($record | describe) =~ "record" "Should be a record type"
    assert ($record | get AWS_PROFILE) == "prod"
    assert ($record | get AWS_REGION) == "us-east-1"

    print "  ✓ PASSED"
}

# =============================================================================
# Test Suite 7: Error Handling Patterns
# =============================================================================

# Test complete pattern
def test-complete-pattern [] {
    print "Test: Error handling with complete"

    # Simulate successful command
    let success_result = (echo "success" | complete)

    assert ($success_result.exit_code) == 0 "Successful command should have exit code 0"
    assert ($success_result.stdout | str trim) == "success"

    # Simulate failed command
    let fail_result = (bash -c "exit 1" | complete)

    assert ($fail_result.exit_code) == 1 "Failed command should have non-zero exit code"

    print "  ✓ PASSED"
}

# Test conditional execution based on exit code
def test-exit-code-checking [] {
    print "Test: Exit code conditional execution"

    let result = (echo "test" | complete)

    mut error_handled = false
    mut success_handled = false

    if $result.exit_code != 0 {
        $error_handled = true
    } else {
        $success_handled = true
    }

    assert $success_handled "Success path should execute"
    assert not $error_handled "Error path should not execute"

    print "  ✓ PASSED"
}

# =============================================================================
# Main Test Runner
# =============================================================================

def main [] {
    print "\n🧪 Running Nushell Unit Tests for aws-profile.nu"
    print "=" * 60
    print ""

    # Track results
    mut tests_passed = 0
    mut tests_failed = 0

    # Suite 1: Credential Parsing
    print "📦 Suite 1: Credential Parsing"
    print "-" * 60
    try {
        test-parse-credentials
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-parse-with-empty-lines
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-parse-malformed-input
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Suite 2: Profile Discovery
    print "📦 Suite 2: Profile Discovery"
    print "-" * 60
    try {
        test-extract-credentials-profiles
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-extract-config-profiles
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-merge-profiles
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Suite 3: String Operations
    print "📦 Suite 3: String Operations"
    print "-" * 60
    try {
        test-string-operations
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-emptiness-checks
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Suite 4: Record Operations
    print "📦 Suite 4: Record Operations"
    print "-" * 60
    try {
        test-build-env-record
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-conditional-field-addition
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Suite 5: Null-Safe Operations
    print "📦 Suite 5: Null-Safe Operations"
    print "-" * 60
    try {
        test-null-safe-get
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-optional-field-access
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Suite 6: Pipeline Operations
    print "📦 Suite 6: Pipeline and Data Transformation"
    print "-" * 60
    try {
        test-complex-pipeline
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-transpose-into-record
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Suite 7: Error Handling
    print "📦 Suite 7: Error Handling Patterns"
    print "-" * 60
    try {
        test-complete-pattern
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }

    try {
        test-exit-code-checking
        $tests_passed = $tests_passed + 1
    } catch {
        print "  ❌ FAILED"
        $tests_failed = $tests_failed + 1
    }
    print ""

    # Summary
    print "=" * 60
    print $"Test Results:"
    print $"  ✓ Passed: ($tests_passed)"
    print $"  ❌ Failed: ($tests_failed)"
    print $"  Total: ($tests_passed + $tests_failed)"
    print "=" * 60

    if $tests_failed == 0 {
        print "\n✅ ALL TESTS PASSED!\n"
        exit 0
    } else {
        print "\n❌ SOME TESTS FAILED\n"
        exit 1
    }
}
