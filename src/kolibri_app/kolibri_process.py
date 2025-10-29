"""Unified Kolibri Process Implementation

This module provides a unified KolibriProcess class that directly inherits from
KolibriProcessBus, consolidating initialization logic that was previously duplicated
across platform-specific implementations.

The class handles:
- Kolibri initialization with optional plugin enablement
- Share file capability registration
- Platform-specific plugin management via composition

Platform-specific behavior is achieved by adding different plugins to the same
base process class, rather than having separate wrapper classes per platform.
"""

from kolibri.main import enable_plugin
from kolibri.main import initialize
from kolibri.plugins.app.utils import interface
from kolibri.plugins.app.utils import SHARE_FILE
from kolibri.utils.conf import OPTIONS
from kolibri.utils.server import KolibriProcessBus

from kolibri_app.logger import logging

# File sharing integration - intentionally disabled to mirror original implementation
share_file = None


class KolibriProcess(KolibriProcessBus):
    """
    Unified Kolibri server process that directly inherits from KolibriProcessBus.

    This class consolidates the initialization logic previously duplicated across
    Windows and POSIX implementations, reducing code duplication and providing
    a single source of truth for Kolibri server setup.

    Platform-specific behavior is achieved by adding different plugins after
    construction, rather than through inheritance or wrapper classes.
    """

    def __init__(self, port=None, zip_port=None, enable_app_plugin=False):
        """
        Initialize the Kolibri server process.

        Args:
            port: HTTP port for the Kolibri server (defaults to OPTIONS config)
            zip_port: Port for ZIP content serving (defaults to OPTIONS config)
            enable_app_plugin: If True, enables kolibri.plugins.app before initialization.
                             Required for subprocess mode (Windows), not needed when running
                             in same process as main app (POSIX) since app already enables it.
        """
        # Initialize Kolibri before calling parent constructor
        self._initialize_kolibri(enable_app_plugin)

        # Use configured ports if not specified
        if port is None:
            port = OPTIONS["Deployment"]["HTTP_PORT"]
        if zip_port is None:
            zip_port = OPTIONS["Deployment"]["ZIP_CONTENT_PORT"]

        # Call parent constructor to set up the process bus
        super().__init__(port=port, zip_port=zip_port)

        logging.info(f"KolibriProcess initialized on port {port}")

    def _initialize_kolibri(self, enable_app_plugin):
        """
        Initialize Kolibri with required configuration.

        This handles plugin enablement and core initialization. The enable_app_plugin
        parameter allows controlling whether the app plugin is enabled, which is
        necessary for subprocess mode but redundant when running in the same process
        as the main application.

        Args:
            enable_app_plugin: Whether to enable kolibri.plugins.app before initialization
        """
        logging.info("Initializing Kolibri...")

        if enable_app_plugin:
            enable_plugin("kolibri.plugins.app")

        initialize()

        # File sharing integration - intentionally disabled to mirror original implementation
        # This check will always be False since share_file is None
        if callable(share_file):
            interface.register_capabilities(**{SHARE_FILE: share_file})
