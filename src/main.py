import datetime
import gettext
import logging
import os
import pew
import shutil
import subprocess
import sys

from config import KOLIBRI_PORT
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

pew.set_app_name("Kolibri")

KOLIBRI_ROOT_URL = 'http://localhost:{}'.format(KOLIBRI_PORT)
os.environ["DJANGO_SETTINGS_MODULE"] = "kolibri.deployment.default.settings.base"

app_data_dir = pew.get_app_files_dir()
os.makedirs(app_data_dir, exist_ok=True)

if not 'KOLIBRI_HOME' in os.environ:
    kolibri_home = os.path.join(os.path.expanduser("~"), ".endless-key")

    if sys.platform == 'darwin':
        # In macOS we must look for the folder that's along side Kolibri.app
        portable_dirs = [os.path.abspath(os.path.join(root_dir, '../../..'))]
    else:
        portable_dirs = [root_dir, os.path.abspath(os.path.join(root_dir, '..'))]

    for adir in portable_dirs:
        kolibri_data_dir = os.path.join(adir, 'KOLIBRI_DATA')
        kolibri_dir = os.path.join(adir, '.kolibri')
        if os.path.isdir(kolibri_data_dir):
            db_file = os.path.join(kolibri_data_dir, 'db.sqlite3')
            if os.path.exists(db_file):
                kolibri_home = kolibri_data_dir
                break
        if os.path.isdir(kolibri_dir):
            kolibri_home = kolibri_dir
            break

    os.environ["KOLIBRI_HOME"] = kolibri_home

languages = None
if sys.platform == 'darwin':
    langs_str = subprocess.check_output('defaults read .GlobalPreferences AppleLanguages | tr -d [:space:]', shell=True).strip()
    languages_base = langs_str[1:-1].decode('utf-8').replace('"', '').replace('-', '_').split(',')
    logging.info("languages= {}".format(languages))
    languages = []
    for lang in languages_base:
        if os.path.exists(os.path.join(locale_root_dir, lang)):
            languages.append(lang)
        elif '_' in lang:
            # make sure we check for base languages in addition to specific dialects.
            languages.append(lang.split('_')[0])

locale_info = {}
try:
    t = gettext.translation('macapp', locale_root_dir, languages=languages, fallback=False)
    locale_info = t.info()
    # We have not been able to reproduce, but we have seen this happen in user tracebacks, so
    # trigger the exception handling fallback if locale_info doesn't have a language key.
    if not 'language' in locale_info:
        raise Exception("Received invalid language_info dict.")
    _ = t.gettext

except Exception as e:
    # Fallback to English and if we fail to find any language catalogs.
    locale_info['language'] = 'en_US'
    def _(text):
        return text
    logging.warning("Error retrieving language: {}".format(repr(e)))

logging.info("Locale info = {}".format(locale_info))


class Application:
    def run(self):
        self.port = KOLIBRI_PORT

        HOME_TEMPLATE_PATH = 'assets/preseeded_kolibri_home'

        from kolibri_tools.utils import get_key_kolibri_data
        kolibri_data = get_key_kolibri_data()
        if kolibri_data:
            logging.info(f'Using Endless Key: {kolibri_data}')
            fallback_dirs = os.path.join(kolibri_data, 'content')
            os.environ["KOLIBRI_CONTENT_FALLBACK_DIRS"] = fallback_dirs
            template = os.path.join(kolibri_data, 'preseeded_kolibri_home')
            if os.path.isdir(template):
                HOME_TEMPLATE_PATH = template
            extensions = os.path.join(kolibri_data, 'extensions')
            if os.path.isdir(extensions):
                logging.info(f'Extending PYTHONPATH: {extensions}')
                sys.path.append(extensions)
        else:
            logging.warning('Endless Key data not found')

# move in a templated Kolibri data directory, including pre-migrated DB, to speed up startup
        HOME_PATH = os.environ["KOLIBRI_HOME"]
        if not os.path.exists(HOME_PATH) and os.path.exists(HOME_TEMPLATE_PATH):
            shutil.copytree(HOME_TEMPLATE_PATH, HOME_PATH)


        from kolibri.utils.logger import KolibriTimedRotatingFileHandler

        log_basename = "kolibri-app.txt"
        log_dir = os.path.join(os.environ['KOLIBRI_HOME'], 'logs')
        os.makedirs(log_dir, exist_ok=True)
        log_filename = os.path.join(log_dir, log_basename)
        root_logger = logging.getLogger()
        file_handler = KolibriTimedRotatingFileHandler(filename=log_filename, encoding='utf-8', when='midnight', backupCount=30)
        root_logger.addHandler(file_handler)

# Since the log files can contain multiple runs, make the first printout very visible to quickly show
# when a new run starts in the log files.
        logging.info("")
        logging.info("**********************************")
        logging.info("*  Kolibri Mac App Initializing  *")
        logging.info("**********************************")
        logging.info("")
        logging.info("Started at: {}".format(datetime.datetime.today()))
        self.start_server()

    def start_server(self):
        os.environ["KOLIBRI_HTTP_PORT"] = str(self.port)

        logging.info("Preparing to start Kolibri server...")
        start_kolibri_server()


if __name__ == "__main__":
    app = Application()
    app.run()
