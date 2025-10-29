from threading import Thread

from magicbus.plugins import SimplePlugin

from kolibri_app.kolibri_process import KolibriProcess
from kolibri_app.logger import logging


class AppPlugin(SimplePlugin):
    """
    MagicBus plugin for POSIX platforms that handles the SERVING event.

    This plugin subscribes to the Kolibri server's SERVING event and invokes
    a callback when the server is ready, allowing the UI to load Kolibri.
    """

    def __init__(self, bus, callback):
        super().__init__(bus)
        self.callback = callback
        # Subscribe to SERVING event (not part of plugin.subscribe())
        self.bus.subscribe("SERVING", self.SERVING)

    def SERVING(self, port):
        """Handle the SERVING event by invoking the callback with port info."""
        self.callback(port, root_url=None)


class PosixServerManager:
    """
    Manages the Kolibri server for non-Windows platforms (macOS, Linux)
    by running it in a separate thread within the same process.
    """

    def __init__(self, app):
        self.app = app
        self.kolibri_process = None
        self.server_thread = None

    def start(self):
        if self.server_thread:
            return

        logging.info("Preparing to start Kolibri server thread")
        self.server_thread = Thread(target=self._run_kolibri_server)
        self.server_thread.daemon = True
        self.server_thread.start()

    def _run_kolibri_server(self):
        """
        Runs the Kolibri server in a separate thread.

        Creates a KolibriProcess with the AppPlugin for direct callback
        communication. Since this runs in the same process as the main app,
        enable_app_plugin is False (the plugin is already enabled by the main app).
        """
        # Create the unified Kolibri process
        # enable_app_plugin=False since we're in the same process as main app
        self.kolibri_process = KolibriProcess(enable_app_plugin=False)

        # Add POSIX-specific plugin for direct callback communication
        app_plugin = AppPlugin(self.kolibri_process, self.app.load_kolibri)
        app_plugin.subscribe()

        # Start serving, this blocks until shutdown
        self.kolibri_process.run()

    def shutdown(self):
        if self.kolibri_process is not None:
            self.kolibri_process.transition("EXITED")
