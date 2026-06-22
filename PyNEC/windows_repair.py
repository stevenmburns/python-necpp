"""delvewheel repair wrapper for the Windows PyNEC wheel.

cibuildwheel does not evaluate ``$(...)`` command substitution in
``repair-wheel-command`` on Windows, so compute the scipy-openblas DLL
directory here in Python and hand it to delvewheel via ``--add-path`` to vendor
``scipy_openblas.dll`` into the wheel.

Usage (from pyproject's repair-wheel-command): ``python windows_repair.py <wheel> <dest_dir>``
"""

import subprocess
import sys

import scipy_openblas32

wheel, dest_dir = sys.argv[1], sys.argv[2]
subprocess.run(
    [
        "delvewheel",
        "repair",
        "--add-path",
        scipy_openblas32.get_lib_dir(),
        "-w",
        dest_dir,
        wheel,
    ],
    check=True,
)
