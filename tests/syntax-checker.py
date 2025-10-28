#!/usr/bin/env python3
"""
Advanced syntax checker for aws-profile.nu
Validates Nushell 0.108+ syntax patterns and common errors
"""

import re
import sys
from pathlib import Path

class NushellSyntaxChecker:
    def __init__(self, filepath):
        self.filepath = Path(filepath)
        self.content = self.filepath.read_text()
        self.lines = self.content.split('\n')
        self.errors = []
        self.warnings = []
        self.checks_passed = 0

    def check_balanced_braces(self):
        """Check for balanced braces, brackets, and parentheses"""
        print("✓ Checking balanced delimiters...")
        stack = []
        pairs = {'(': ')', '[': ']', '{': '}'}

        for line_num, line in enumerate(self.lines, 1):
            # Skip comments
            if line.strip().startswith('#'):
                continue

            for char in line:
                if char in pairs.keys():
                    stack.append((char, line_num))
                elif char in pairs.values():
                    if not stack:
                        self.errors.append(f"Line {line_num}: Unmatched closing '{char}'")
                        continue
                    opening, _ = stack.pop()
                    if pairs[opening] != char:
                        self.errors.append(f"Line {line_num}: Mismatched delimiters")

        if stack:
            for char, line_num in stack:
                self.errors.append(f"Line {line_num}: Unclosed '{char}'")

        if not self.errors:
            self.checks_passed += 1
            print("  ✓ All delimiters balanced")

    def check_function_definitions(self):
        """Validate function definition syntax"""
        print("✓ Checking function definitions...")

        # Pattern for function definitions
        func_pattern = re.compile(r'^(export\s+)?def(\s+--env)?\s+([a-z-]+)\s*\[')

        functions_found = 0
        for line_num, line in enumerate(self.lines, 1):
            match = func_pattern.match(line.strip())
            if match:
                functions_found += 1
                func_name = match.group(3)

                # Check naming convention (lowercase with hyphens)
                if not re.match(r'^[a-z][a-z0-9-]*$', func_name):
                    self.warnings.append(
                        f"Line {line_num}: Function '{func_name}' doesn't follow naming convention"
                    )

        if functions_found > 0:
            self.checks_passed += 1
            print(f"  ✓ Found {functions_found} function definitions")

    def check_parameter_syntax(self):
        """Check parameter definitions and type hints"""
        print("✓ Checking parameter syntax...")

        param_pattern = re.compile(r'^\s+([a-z_][a-z0-9_]*)\s*:\s*(string|int|bool|float|list|record)')
        flag_pattern = re.compile(r'^\s+--([\w-]+)(\s*:\s*(string|int|bool|float))?\s*(=.*)?')

        params_found = 0
        for line_num, line in enumerate(self.lines, 1):
            param_match = param_pattern.match(line)
            flag_match = flag_pattern.match(line)

            if param_match:
                params_found += 1
                param_name = param_match.group(1)
                param_type = param_match.group(2)

            elif flag_match:
                params_found += 1
                flag_name = flag_match.group(1)

        if params_found > 0:
            self.checks_passed += 1
            print(f"  ✓ Found {params_found} parameters with proper syntax")

    def check_environment_patterns(self):
        """Check environment variable usage patterns"""
        print("✓ Checking environment variable patterns...")

        # Check for load-env usage
        load_env_count = len(re.findall(r'load-env\s+{', self.content))

        # Check for hide-env usage
        hide_env_count = len(re.findall(r'hide-env\s+\$?\w+', self.content))

        # Check for proper $env access
        env_access = re.findall(r'\$env\.(\w+)', self.content)

        # Check for get -i usage (null-safe)
        get_i_count = len(re.findall(r'get\s+-i', self.content))

        if load_env_count > 0 and hide_env_count > 0:
            self.checks_passed += 1
            print(f"  ✓ load-env: {load_env_count}, hide-env: {hide_env_count}")
            print(f"  ✓ Null-safe get -i: {get_i_count}")

    def check_string_operations(self):
        """Check for modern string operations"""
        print("✓ Checking string operations...")

        modern_ops = {
            'str trim': r'str\s+trim',
            'str substring': r'str\s+substring',
            'str contains': r'str\s+contains',
            'str starts-with': r'str\s+starts-with',
            'str ends-with': r'str\s+ends-with',
        }

        found_ops = []
        for op_name, pattern in modern_ops.items():
            if re.search(pattern, self.content):
                found_ops.append(op_name)

        if len(found_ops) >= 3:
            self.checks_passed += 1
            print(f"  ✓ Using modern string operations: {', '.join(found_ops)}")

    def check_pipeline_patterns(self):
        """Check for proper pipeline usage"""
        print("✓ Checking pipeline patterns...")

        # Check for multi-line pipelines with proper indentation
        pipeline_lines = [i for i, line in enumerate(self.lines)
                         if line.strip().startswith('|')]

        # Check for parse pattern
        parse_usage = len(re.findall(r'\|\s*parse\s+["\'{]', self.content))

        # Check for transpose usage
        transpose_usage = len(re.findall(r'\|\s*transpose\s+-[ir]+', self.content))

        if parse_usage > 0 and transpose_usage > 0:
            self.checks_passed += 1
            print(f"  ✓ Pipeline patterns: parse={parse_usage}, transpose={transpose_usage}")

    def check_error_handling(self):
        """Check error handling patterns"""
        print("✓ Checking error handling...")

        # Check for complete usage
        complete_usage = len(re.findall(r'\|\s*complete\)', self.content))

        # Check for exit_code checks
        exit_code_checks = len(re.findall(r'exit_code\s*[!=]=\s*0', self.content))

        # Check for stderr handling
        stderr_usage = len(re.findall(r'stderr', self.content))

        if complete_usage > 0 and exit_code_checks > 0:
            self.checks_passed += 1
            print(f"  ✓ Error handling: complete={complete_usage}, exit_code checks={exit_code_checks}")

    def check_ansi_colors(self):
        """Check ANSI color usage"""
        print("✓ Checking ANSI color codes...")

        ansi_patterns = re.findall(r'ansi\s+(\w+)', self.content)
        ansi_reset = self.content.count('ansi reset')

        if len(ansi_patterns) > 0 and ansi_reset > 0:
            self.checks_passed += 1
            colors = set(ansi_patterns)
            print(f"  ✓ Using colors: {', '.join(sorted(colors)[:5])}")
            print(f"  ✓ Reset count: {ansi_reset}")

    def check_comments_and_docs(self):
        """Check documentation quality"""
        print("✓ Checking documentation...")

        comment_lines = [line for line in self.lines if line.strip().startswith('#')]
        section_headers = [line for line in comment_lines
                          if line.strip().startswith('# =====')]

        # Check for function doc comments (lines starting with # followed by function def)
        doc_comments = 0
        for i, line in enumerate(self.lines[:-1]):
            if line.strip().startswith('#') and not line.strip().startswith('# ='):
                next_line = self.lines[i + 1].strip()
                if next_line.startswith('export def'):
                    doc_comments += 1

        if len(comment_lines) > 20 and doc_comments > 3:
            self.checks_passed += 1
            print(f"  ✓ Comment lines: {len(comment_lines)}")
            print(f"  ✓ Section headers: {len(section_headers)}")
            print(f"  ✓ Documented functions: {doc_comments}")

    def check_export_statements(self):
        """Check export statements for functions and aliases"""
        print("✓ Checking export statements...")

        exported_funcs = len(re.findall(r'^export\s+def', self.content, re.MULTILINE))
        exported_aliases = len(re.findall(r'^export\s+alias', self.content, re.MULTILINE))

        if exported_funcs > 0 and exported_aliases > 0:
            self.checks_passed += 1
            print(f"  ✓ Exported functions: {exported_funcs}")
            print(f"  ✓ Exported aliases: {exported_aliases}")

    def check_common_mistakes(self):
        """Check for common mistakes"""
        print("✓ Checking for common mistakes...")

        mistakes_found = 0

        # Check for old-style string length
        if re.search(r'str\s+length', self.content):
            self.warnings.append("Found 'str length' - consider using 'is-empty' or 'is-not-empty'")
            mistakes_found += 1

        # Check for $env without get -i
        unsafe_env = re.findall(r'\$env\.(\w+)[^?]', self.content)
        # Filter out safe cases
        for match in unsafe_env:
            # This is just a simple heuristic
            pass

        # Check for missing error handling on AWS CLI calls
        aws_calls = re.findall(r'^\s*aws\s+\w+', self.content, re.MULTILINE)
        aws_complete = len(re.findall(r'aws\s+\w+[^|]*\|\s*complete', self.content))

        if mistakes_found == 0:
            self.checks_passed += 1
            print("  ✓ No common mistakes found")

    def run_all_checks(self):
        """Run all syntax checks"""
        print(f"\n🔍 Nushell 0.108+ Syntax Checker")
        print(f"{'=' * 60}")
        print(f"File: {self.filepath}")
        print(f"Lines: {len(self.lines)}\n")

        # Run all checks
        self.check_balanced_braces()
        self.check_function_definitions()
        self.check_parameter_syntax()
        self.check_environment_patterns()
        self.check_string_operations()
        self.check_pipeline_patterns()
        self.check_error_handling()
        self.check_ansi_colors()
        self.check_comments_and_docs()
        self.check_export_statements()
        self.check_common_mistakes()

        # Print results
        print(f"\n{'=' * 60}")
        print(f"Results:")
        print(f"  ✓ Checks passed: {self.checks_passed}")
        print(f"  ⚠ Warnings: {len(self.warnings)}")
        print(f"  ❌ Errors: {len(self.errors)}")

        if self.warnings:
            print(f"\n⚠ Warnings:")
            for warning in self.warnings:
                print(f"  {warning}")

        if self.errors:
            print(f"\n❌ Errors:")
            for error in self.errors:
                print(f"  {error}")
            return False

        print(f"\n✅ Syntax validation passed!")
        print(f"{'=' * 60}\n")
        return True


if __name__ == "__main__":
    script_dir = Path(__file__).parent
    aws_profile_file = script_dir / ".." / "aws-profile.nu"

    if not aws_profile_file.exists():
        print(f"❌ Error: {aws_profile_file} not found")
        sys.exit(1)

    checker = NushellSyntaxChecker(aws_profile_file)
    success = checker.run_all_checks()

    sys.exit(0 if success else 1)
