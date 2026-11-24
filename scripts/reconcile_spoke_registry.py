#!/usr/bin/env python3
"""Remove spoke registry entries whose resource groups no longer exist."""

import json
import sys


def reconcile(registry, groups):
    if not isinstance(registry, dict):
        raise ValueError("Registry must be a JSON object")
    if not isinstance(groups, list) or any(not isinstance(name, str) or not name for name in groups):
        raise ValueError("Resource group listing must be a JSON array of names")
    if any(not isinstance(name, str) or not name for name in registry):
        raise ValueError("Registry contains an invalid spoke name")

    existing = {name.casefold() for name in groups}
    return {
        spoke: index
        for spoke, index in registry.items()
        if f"RG-Spoke-{spoke}-SBX".casefold() in existing
    }


def main():
    if len(sys.argv) != 4:
        print("Usage: reconcile_spoke_registry.py REGISTRY GROUPS OUTPUT", file=sys.stderr)
        return 2
    try:
        with open(sys.argv[1], encoding="utf-8") as registry_file:
            registry = json.load(registry_file)
        with open(sys.argv[2], encoding="utf-8") as groups_file:
            groups = json.load(groups_file)
        result = reconcile(registry, groups)
        with open(sys.argv[3], "w", encoding="utf-8") as output_file:
            json.dump(result, output_file, indent=2, ensure_ascii=False)
            output_file.write("\n")
        removed = set(registry) - set(result)
        print(f"Registry reconciliation: {len(removed)} stale spoke(s), {len(result)} retained.")
        for spoke in sorted(removed):
            print(f"  Removed stale spoke: {spoke}")
    except (OSError, ValueError, TypeError) as error:
        print(f"Registry reconciliation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
