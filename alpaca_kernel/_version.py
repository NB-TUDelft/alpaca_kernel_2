"""
store the current version info of the server.
"""
import re
import os
from typing import List

# Read version from VERSION file
def _get_version():
    here = os.path.dirname(os.path.abspath(__file__))
    version_file = os.path.join(here, "..", "VERSION")
    with open(version_file, "r", encoding="utf-8") as f:
        return f.read().strip()

# Version string must appear intact for hatch versioning
__version__ = _get_version()

# Build up version_info tuple for backwards compatibility
pattern = r"(?P<major>\d+).(?P<minor>\d+).(?P<patch>\d+)(?P<rest>.*)"
match = re.match(pattern, __version__)
assert match is not None
parts: List[object] = [int(match[part]) for part in ["major", "minor", "patch"]]
if match["rest"]:
    parts.append(match["rest"])
version_info = tuple(parts)

kernel_protocol_version_info = (5, 3)
kernel_protocol_version = "{}.{}".format(*kernel_protocol_version_info)
