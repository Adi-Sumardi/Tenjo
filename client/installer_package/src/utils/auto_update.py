"""
Tenjo Client Auto-Update Module (Stealth Edition)
Installer package copy mirroring the primary client implementation.
"""

from ...src.utils.auto_update import (  # type: ignore
    ClientUpdater,
    check_and_update_if_needed,
    version_info_timestamp,
)
