#!/usr/bin/env python3
"""
DexHub Profile Schema Validator v1.0

Validates profile.yaml against profile-schema-v1.0.yaml

Usage:
    python tests/validate_profile_schema.py <profile-path>
    python tests/validate_profile_schema.py myDex/.dex/config/profile.yaml

Exit Codes:
    0 = Valid profile
    1 = Invalid profile (validation errors)
    2 = File not found or parse error

Author: Claude Code + Arash Zamani
Date: 2025-11-16
"""

import sys
import os
import yaml
from pathlib import Path
from typing import Dict, List, Any, Tuple, Optional
from datetime import datetime


class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


class ProfileValidator:
    """Validates DexHub profile.yaml against schema"""

    def __init__(self, schema_path: str = ".dexCore/_dev/schemas/profile-schema-v1.0.yaml"):
        self.schema_path = schema_path
        self.schema = None
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def load_schema(self) -> bool:
        """Load schema definition"""
        try:
            with open(self.schema_path, 'r', encoding='utf-8') as f:
                self.schema = yaml.safe_load(f)
            return True
        except FileNotFoundError:
            print(f"{Colors.RED}✗ Schema file not found: {self.schema_path}{Colors.RESET}")
            return False
        except yaml.YAMLError as e:
            print(f"{Colors.RED}✗ Schema YAML parse error: {e}{Colors.RESET}")
            return False

    def load_profile(self, profile_path: str) -> Optional[Dict[str, Any]]:
        """Load profile.yaml"""
        try:
            with open(profile_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            print(f"{Colors.RED}✗ Profile file not found: {profile_path}{Colors.RESET}")
            return None
        except yaml.YAMLError as e:
            print(f"{Colors.RED}✗ Profile YAML parse error: {e}{Colors.RESET}")
            return None

    def validate_required_field(self, profile: Dict, path: str, field_name: str, field_schema: Dict) -> bool:
        """Validate a required field exists"""
        parts = path.split('.')
        current = profile

        for part in parts:
            if not isinstance(current, dict) or part not in current:
                self.errors.append(f"Missing required field: {path}")
                return False
            current = current[part]

        return True

    def validate_enum(self, value: Any, allowed_values: List[str], path: str) -> bool:
        """Validate enum value is in allowed list"""
        if value not in allowed_values:
            self.errors.append(
                f"Invalid enum value at {path}: '{value}' "
                f"(allowed: {', '.join(allowed_values)})"
            )
            return False
        return True

    def validate_array(self, value: Any, field_schema: Dict, path: str) -> bool:
        """Validate array constraints"""
        if not isinstance(value, list):
            self.errors.append(f"Field {path} must be an array, got {type(value).__name__}")
            return False

        # Min items
        min_items = field_schema.get('min_items')
        if min_items is not None and len(value) < min_items:
            self.errors.append(f"Array {path} must have at least {min_items} items, has {len(value)}")
            return False

        # Max items
        max_items = field_schema.get('max_items')
        if max_items is not None and len(value) > max_items:
            self.errors.append(f"Array {path} must have at most {max_items} items, has {len(value)}")
            return False

        return True

    def validate_string(self, value: Any, field_schema: Dict, path: str) -> bool:
        """Validate string constraints"""
        if not isinstance(value, str):
            self.errors.append(f"Field {path} must be a string, got {type(value).__name__}")
            return False

        # Min length
        min_length = field_schema.get('validation', {}).get('min_length')
        if min_length is not None and len(value) < min_length:
            self.errors.append(f"String {path} must be at least {min_length} characters, has {len(value)}")
            return False

        # Max length
        max_length = field_schema.get('validation', {}).get('max_length')
        if max_length is not None and len(value) > max_length:
            self.errors.append(f"String {path} must be at most {max_length} characters, has {len(value)}")
            return False

        return True

    def validate_boolean(self, value: Any, path: str) -> bool:
        """Validate boolean type"""
        if not isinstance(value, bool):
            self.errors.append(f"Field {path} must be a boolean, got {type(value).__name__}")
            return False
        return True

    def get_nested_value(self, data: Dict, path: str) -> Any:
        """Get value from nested dict using dot notation"""
        parts = path.split('.')
        current = data

        for part in parts:
            if not isinstance(current, dict) or part not in current:
                return None
            current = current[part]

        return current

    def validate_field(self, profile: Dict, path: str, field_schema: Dict) -> bool:
        """Validate a single field"""
        value = self.get_nested_value(profile, path)

        # Check required
        if field_schema.get('required', False):
            if value is None:
                self.errors.append(f"Missing required field: {path}")
                return False

        # If optional and missing, skip validation
        if value is None:
            return True

        # Type validation
        field_type = field_schema.get('type')

        if field_type == 'enum':
            allowed_values = field_schema.get('values', [])
            return self.validate_enum(value, allowed_values, path)

        elif field_type == 'array':
            return self.validate_array(value, field_schema, path)

        elif field_type == 'string':
            return self.validate_string(value, field_schema, path)

        elif field_type == 'boolean':
            return self.validate_boolean(value, path)

        elif field_type == 'object':
            # Validate nested fields
            if not isinstance(value, dict):
                self.errors.append(f"Field {path} must be an object, got {type(value).__name__}")
                return False

            # Recursively validate object fields
            nested_fields = field_schema.get('fields', {})
            all_valid = True
            for field_name, nested_schema in nested_fields.items():
                nested_path = f"{path}.{field_name}"
                if not self.validate_field(profile, nested_path, nested_schema):
                    all_valid = False

            return all_valid

        return True

    def validate_profile(self, profile: Dict) -> bool:
        """Validate entire profile against schema"""
        self.errors = []
        self.warnings = []

        if not self.schema:
            print(f"{Colors.RED}✗ Schema not loaded{Colors.RESET}")
            return False

        # Validate schema version
        profile_version = profile.get('version')
        schema_version = self.schema.get('schema_version')

        if profile_version != schema_version:
            self.warnings.append(
                f"Profile version '{profile_version}' does not match schema version '{schema_version}'"
            )

        # Validate all fields defined in schema
        fields = self.schema.get('fields', {})
        all_valid = True

        for field_name, field_schema in fields.items():
            if not self.validate_field(profile, field_name, field_schema):
                all_valid = False

        return all_valid and len(self.errors) == 0

    def print_results(self, is_valid: bool, profile_path: str):
        """Print validation results"""
        print()
        print(f"{Colors.BOLD}{'='*70}{Colors.RESET}")
        print(f"{Colors.BOLD}Profile Schema Validation Report{Colors.RESET}")
        print(f"{Colors.BOLD}{'='*70}{Colors.RESET}")
        print()
        print(f"Profile: {Colors.CYAN}{profile_path}{Colors.RESET}")
        print(f"Schema:  {Colors.CYAN}{self.schema_path}{Colors.RESET}")
        print(f"Schema Version: {Colors.CYAN}{self.schema.get('schema_version', 'unknown')}{Colors.RESET}")
        print()

        if is_valid and len(self.warnings) == 0:
            print(f"{Colors.GREEN}{Colors.BOLD}✓ VALID{Colors.RESET} - Profile passes all validation checks")
            print()
            return

        # Print warnings
        if self.warnings:
            print(f"{Colors.YELLOW}{Colors.BOLD}WARNINGS ({len(self.warnings)}):{Colors.RESET}")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {Colors.YELLOW}{warning}{Colors.RESET}")
            print()

        # Print errors
        if self.errors:
            print(f"{Colors.RED}{Colors.BOLD}ERRORS ({len(self.errors)}):{Colors.RESET}")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {Colors.RED}{error}{Colors.RESET}")
            print()

        # Final status
        if is_valid:
            print(f"{Colors.GREEN}{Colors.BOLD}✓ VALID{Colors.RESET} - Profile passes validation (with warnings)")
        else:
            print(f"{Colors.RED}{Colors.BOLD}✗ INVALID{Colors.RESET} - Profile failed validation")

        print()
        print(f"{Colors.BOLD}{'='*70}{Colors.RESET}")
        print()


def main():
    """Main entry point"""
    # Parse arguments
    if len(sys.argv) != 2:
        print(f"{Colors.YELLOW}Usage: {sys.argv[0]} <profile-path>{Colors.RESET}")
        print(f"{Colors.YELLOW}Example: {sys.argv[0]} myDex/.dex/config/profile.yaml{Colors.RESET}")
        sys.exit(2)

    profile_path = sys.argv[1]

    # Find schema relative to script location or cwd
    script_dir = Path(__file__).parent.parent
    schema_path = script_dir / ".dexCore/_dev/schemas/profile-schema-v1.0.yaml"

    if not schema_path.exists():
        # Try relative to current directory
        schema_path = Path(".dexCore/_dev/schemas/profile-schema-v1.0.yaml")

    if not schema_path.exists():
        print(f"{Colors.RED}✗ Schema file not found at expected location{Colors.RESET}")
        print(f"  Tried: {schema_path}")
        sys.exit(2)

    # Validate
    validator = ProfileValidator(str(schema_path))

    if not validator.load_schema():
        sys.exit(2)

    profile = validator.load_profile(profile_path)
    if profile is None:
        sys.exit(2)

    is_valid = validator.validate_profile(profile)
    validator.print_results(is_valid, profile_path)

    # Exit with appropriate code
    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
