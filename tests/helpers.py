import os
import shutil
import unittest


def require_tool(name):
    """Return the tool's path, or skip the test; CI fails instead of skipping."""
    path = shutil.which(name)
    if path:
        return path
    if os.environ.get('CHECKS_REQUIRE_ALL'):
        raise AssertionError(f'{name} is required when CHECKS_REQUIRE_ALL is set')
    raise unittest.SkipTest(f'{name} is not installed')
