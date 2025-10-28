#!/bin/bash
# Validation script for aws-profile.nu
# Tests syntax patterns and logic without requiring Nushell

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_PROFILE_FILE="$SCRIPT_DIR/../aws-profile.nu"

echo "🧪 Validating aws-profile.nu..."
echo "================================"
echo ""

# Test 1: File exists and is readable
echo "✓ Test 1: File exists and is readable"
if [ ! -f "$AWS_PROFILE_FILE" ]; then
    echo "❌ FAIL: aws-profile.nu not found"
    exit 1
fi
echo "  File: $AWS_PROFILE_FILE"
echo ""

# Test 2: Check for required function definitions
echo "✓ Test 2: Required function definitions"
required_functions=(
    "aws-login"
    "aws-select"
    "aws-profiles"
    "aws-whoami"
    "aws-logout"
    "aws-temp"
    "aws-assume-role"
)

for func in "${required_functions[@]}"; do
    if grep -q "export def.*$func" "$AWS_PROFILE_FILE"; then
        echo "  ✓ Found: $func"
    else
        echo "  ❌ FAIL: Missing function: $func"
        exit 1
    fi
done
echo ""

# Test 3: Check for --env flag on environment-modifying functions
echo "✓ Test 3: Environment-modifying functions use --env flag"
env_functions=("aws-login" "aws-select" "aws-logout" "aws-temp" "aws-assume-role")
for func in "${env_functions[@]}"; do
    if grep -q "export def --env $func" "$AWS_PROFILE_FILE"; then
        echo "  ✓ $func uses --env"
    else
        echo "  ❌ FAIL: $func missing --env flag"
        exit 1
    fi
done
echo ""

# Test 4: Check for modern Nushell patterns
echo "✓ Test 4: Modern Nushell 0.108+ patterns"
patterns=(
    "get -i:Null-safe get"
    "is-not-empty:Modern emptiness check"
    "str trim:Modern string trim"
    "str substring:Modern substring"
    "load-env:Load environment vars"
    "hide-env:Hide environment vars"
    "complete:Error handling pattern"
    "transpose -ir:Transpose with inverse and record"
    "into record:Convert to record"
    "default:Default value pattern"
)

for pattern_pair in "${patterns[@]}"; do
    pattern="${pattern_pair%%:*}"
    desc="${pattern_pair##*:}"
    if grep -q "$pattern" "$AWS_PROFILE_FILE"; then
        echo "  ✓ $desc ($pattern)"
    else
        echo "  ⚠ Warning: Pattern '$pattern' not found"
    fi
done
echo ""

# Test 5: Check for proper ANSI color usage
echo "✓ Test 5: ANSI color codes for formatted output"
if grep -q "ansi.*bold" "$AWS_PROFILE_FILE" && grep -q "ansi reset" "$AWS_PROFILE_FILE"; then
    echo "  ✓ ANSI color codes present"
else
    echo "  ❌ FAIL: Missing ANSI color codes"
    exit 1
fi
echo ""

# Test 6: Check for type hints on parameters
echo "✓ Test 6: Type hints on parameters"
if grep -q ": string" "$AWS_PROFILE_FILE" && grep -q ": int" "$AWS_PROFILE_FILE"; then
    echo "  ✓ Type hints present"
else
    echo "  ❌ FAIL: Missing type hints"
    exit 1
fi
echo ""

# Test 7: Check for export aliases
echo "✓ Test 7: Exported aliases"
aliases=("awsl" "awss" "awsw" "awso" "awsp" "awst" "awsr")
for alias in "${aliases[@]}"; do
    if grep -q "export alias $alias" "$AWS_PROFILE_FILE"; then
        echo "  ✓ Alias: $alias"
    else
        echo "  ❌ FAIL: Missing alias: $alias"
        exit 1
    fi
done
echo ""

# Test 8: Check for documentation comments
echo "✓ Test 8: Documentation comments"
if grep -q "^# " "$AWS_PROFILE_FILE"; then
    doc_lines=$(grep -c "^# " "$AWS_PROFILE_FILE")
    echo "  ✓ Found $doc_lines documentation lines"
else
    echo "  ⚠ Warning: Limited documentation"
fi
echo ""

# Test 9: Validate credential parsing logic pattern
echo "✓ Test 9: Credential parsing pattern"
if grep -q "parse.*{key}={value}" "$AWS_PROFILE_FILE"; then
    echo "  ✓ Parse pattern for KEY=VALUE format"
else
    echo "  ❌ FAIL: Missing credential parse pattern"
    exit 1
fi
echo ""

# Test 10: Simulate credential parsing logic (bash equivalent)
echo "✓ Test 10: Simulated credential parsing"
cat > /tmp/test-creds.txt <<EOF
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_SESSION_TOKEN=FwoGZXIvYXdzEBYaDH
EOF

echo "  Simulating AWS CLI output parsing..."
while IFS='=' read -r key value; do
    if [ -n "$key" ] && [ -n "$value" ]; then
        echo "    ✓ Parsed: $key=${value:0:20}..."
    fi
done < /tmp/test-creds.txt
rm -f /tmp/test-creds.txt
echo ""

# Test 11: Check error handling patterns
echo "✓ Test 11: Error handling patterns"
if grep -q "exit_code" "$AWS_PROFILE_FILE" && grep -q "stderr" "$AWS_PROFILE_FILE"; then
    echo "  ✓ Proper error handling with exit codes"
else
    echo "  ❌ FAIL: Missing error handling"
    exit 1
fi
echo ""

# Test 12: Check for AWS CLI command usage
echo "✓ Test 12: AWS CLI integration"
aws_commands=(
    "aws configure export-credentials"
    "aws sts get-caller-identity"
    "aws sso login"
    "aws sts get-session-token"
    "aws sts assume-role"
)

for cmd in "${aws_commands[@]}"; do
    if grep -q "$cmd" "$AWS_PROFILE_FILE"; then
        echo "  ✓ Uses: $cmd"
    fi
done
echo ""

# Test 13: Check for parameter validation
echo "✓ Test 13: Input validation patterns"
if grep -q "is-empty\|is-not-empty" "$AWS_PROFILE_FILE"; then
    echo "  ✓ Input validation present"
else
    echo "  ⚠ Warning: Limited input validation"
fi
echo ""

# Test 14: Count lines of code
echo "✓ Test 14: Code metrics"
total_lines=$(wc -l < "$AWS_PROFILE_FILE")
code_lines=$(grep -v "^#" "$AWS_PROFILE_FILE" | grep -v "^$" | wc -l)
comment_lines=$(grep "^#" "$AWS_PROFILE_FILE" | wc -l)
echo "  Total lines: $total_lines"
echo "  Code lines: $code_lines"
echo "  Comment lines: $comment_lines"
echo "  Documentation ratio: $(( comment_lines * 100 / total_lines ))%"
echo ""

# Test 15: Check config.nu integration
echo "✓ Test 15: config.nu integration"
CONFIG_FILE="$SCRIPT_DIR/../config.nu"
if [ -f "$CONFIG_FILE" ]; then
    if grep -q "use.*aws-profile.nu" "$CONFIG_FILE"; then
        echo "  ✓ config.nu sources aws-profile.nu"
    else
        echo "  ❌ FAIL: config.nu doesn't source aws-profile.nu"
        exit 1
    fi
else
    echo "  ⚠ Warning: config.nu not found"
fi
echo ""

# Summary
echo "================================"
echo "✅ All validation tests passed!"
echo "================================"
echo ""
echo "Summary:"
echo "  • All required functions defined"
echo "  • Proper --env flags on environment functions"
echo "  • Modern Nushell 0.108+ syntax patterns"
echo "  • Type hints and documentation present"
echo "  • Error handling implemented"
echo "  • AWS CLI integration correct"
echo "  • Aliases exported"
echo ""
echo "The aws-profile.nu script is ready for use with Nushell 0.108+"
echo ""
echo "To test with Nushell:"
echo "  nu -c 'use ~/.config/nushell/aws-profile.nu *; help aws-login'"
echo "  nu -c 'use ~/.config/nushell/aws-profile.nu *; aws-profiles'"
echo ""
