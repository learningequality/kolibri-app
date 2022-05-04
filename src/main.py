import builtins
import datetime
import logging
import os
import sys

from functools import partial

from config import KOLIBRI_PORT
from kolibri_tools.utils import initialize_plugins
from kolibri_tools.utils import start_kolibri_server


class LoggerWriter(object):
    def __init__(self, writer):
        self._writer = writer
        self._msg = ''

    def write(self, message):
        self._msg = self._msg + message
        while '\n' in self._msg:
            pos = self._msg.find('\n')
            self._writer(self._msg[:pos])
            self._msg = self._msg[pos+1:]

    def flush(self):
        if self._msg != '':
            self._writer(self._msg)
            self._msg = ''

# initialize logging before loading any third-party modules, as they may cause logging to get configured.
logging.basicConfig(level=logging.INFO)

# Set the root_dir to the path where assets and locale dirs are
if getattr(sys, 'frozen', False):
    # In the app bundle context sys.executable will be:
    #   On Windows: The Kolibri.exe path
    #   On macOS: Kolibri.app/Contents/MacOS/python
    if sys.platform == 'darwin':
        root_dir = os.path.abspath(os.path.join(os.path.dirname(sys.executable), '..', 'Resources'))
        extra_python_path = os.path.join(
            root_dir, 'lib',
            'python{}.{}'.format(sys.version_info.major, sys.version_info.minor))
    else:
        # This env var points to where PyInstaller extracted the sources in single file mode.
        if hasattr(sys, '_MEIPASS'):
            root_dir = sys._MEIPASS
        else:
            root_dir = os.path.abspath(os.path.dirname(sys.executable))
        extra_python_path = root_dir

    # Make sure we send all app output to logs as we have no console to view them on.
    sys.stdout = LoggerWriter(logging.debug)
    sys.stderr = LoggerWriter(logging.warning)
else:
    # In this case we use src/main.py
    extra_python_path = os.path.abspath(os.path.dirname(__file__))
    root_dir = os.path.abspath(os.path.join(extra_python_path, '..'))

assets_root_dir = os.path.join(root_dir, 'assets')
locale_root_dir = os.path.join(root_dir, 'locale')

sys.path.insert(0, extra_python_path)
sys.path.insert(0, os.path.join(extra_python_path, "kolibri", "dist"))

KOLIBRI_ROOT_URL = 'http://localhost:{}'.format(KOLIBRI_PORT)
os.environ["DJANGO_SETTINGS_MODULE"] = "kolibri.deployment.default.settings.base"


class Application:
    def _init_log(self):
        from kolibri.utils.logger import KolibriTimedRotatingFileHandler

        log_basename = "kolibri-app.txt"
        log_dir = os.path.join(os.environ['KOLIBRI_HOME'], 'logs')
        os.makedirs(log_dir, exist_ok=True)
        log_filename = os.path.join(log_dir, log_basename)
        root_logger = logging.getLogger()
        file_handler = KolibriTimedRotatingFileHandler(filename=log_filename, encoding='utf-8', when='midnight', backupCount=30)
        root_logger.addHandler(file_handler)

    def run(self):
        self.port = KOLIBRI_PORT
        self._init_log()

# Since the log files can contain multiple runs, make the first printout very visible to quickly show
# when a new run starts in the log files.
        logging.info("")
        logging.info("**************************************")
        logging.info("*  Kolibri Backend App Initializing  *")
        logging.info("**************************************")
        logging.info("")
        logging.info("Started at: {}".format(datetime.datetime.today()))

        # This is needed because in other case the extensions path is not
        # working correctly
        if os.environ.get('PYTHONPATH'):
            sys.path.append(os.environ['PYTHONPATH'])

        self.start_server()

    def start_server(self):
        os.environ["KOLIBRI_HTTP_PORT"] = str(self.port)

        logging.info("Preparing to start Kolibri server...")
        initialize_plugins()
        start_kolibri_server()


if __name__ == "__main__":
    app = Application()
    app.run()
