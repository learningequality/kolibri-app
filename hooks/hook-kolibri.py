import glob
import os

from PyInstaller.utils.hooks import collect_data_files
from PyInstaller.utils.hooks import collect_submodules
from PyInstaller.utils.hooks import eval_statement
from PyInstaller.utils.hooks import get_module_file_attribute

settings = eval_statement(
    """
    from django.conf import settings
    from kolibri.main import initialize
    from kolibri.main import enable_plugin
    enable_plugin("kolibri.plugins.app")
    initialize(skip_update=True)
    settings_output = {}

    def _remove_class(class_name):
        return '.'.join(class_name.split('.')[0:-1])

    installed_apps = []
    for app in settings.INSTALLED_APPS:
        if isinstance(app, str):
            app = app.split(".apps")[0]
            installed_apps.append(app)
        else:
            installed_apps.append(app.module.__name__)
    settings_output["installed_apps"] = installed_apps

    settings_output["middleware"] = [_remove_class(x) for x in settings.MIDDLEWARE]

    templates = []

    for template in settings.TEMPLATES:
        templates.append(_remove_class(template["BACKEND"]))
        templates.extend([_remove_class(x) for x in template["OPTIONS"]["context_processors"]])

    settings_output["templates"] = templates

    logging = []

    for formatter in settings.LOGGING["formatters"].values():
        if "()" in formatter:
            logging.append(_remove_class(formatter["()"]))

    for handler in settings.LOGGING["handlers"].values():
        if "class" in handler:
            logging.append(_remove_class(handler["class"]))

    settings_output["logging"] = logging

    settings_output["urlconf"] = [settings.ROOT_URLCONF]

    databases = []

    for value in settings.DATABASES.values():
        databases.append(value["ENGINE"])

    databases.extend([_remove_class(x) for x in settings.DATABASE_ROUTERS])

    settings_output["databases"] = databases

    caches = []

    for value in settings.CACHES.values():
        caches.append(_remove_class(value["BACKEND"]))

    settings_output["caches"] = caches

    print(settings_output)
    """
)

exclude_django_submodules = [
    "django.contrib.gis",
    "django.contrib.redirects",
    "django.conf.app_template",
    "django.conf.project_template",
    "django.db.backends.postgresql_psycopg2",
    "django.db.backends.postgresql",
    "django.db.backends.mysql",
    "django.db.backends.oracle",
    "django.contrib.postgres",
]


def submodule_filter(name):
    if name.startswith("kolibri.plugins.demo_server"):
        return False
    if name.startswith("pycountry."):
        return False
    if any(name.startswith(subm) for subm in exclude_django_submodules):
        return False
    if "test" in name:
        return False
    if "redis" in name:
        return False
    return True


module_locales = ["rest_framework", "django_filters", "mptt"]
django_locales = [
    "admindocs",
    "auth",
    "sites",
    "contenttypes",
    "flatpages",
    "sessions",
    "humanize",
    "admin",
]


def datas_filter(item):
    if item[0].endswith(".js.map"):
        return False
    if "locale" in item[0]:
        if any(x in item[0] for x in module_locales):
            return False
        if "django" in item[0] and any(x in item[0] for x in django_locales):
            return False
    return True


hiddenimports = collect_submodules("kolibri", submodule_filter)

datas = []

migration_modules = [
    "django.conf.app_template.migrations",
    "django.contrib.admin.migrations",
    "django.contrib.auth.migrations",
    "django.contrib.contenttypes.migrations",
    "django.contrib.flatpages.migrations",
    "django.contrib.redirects.migrations",
    "django.contrib.sessions.migrations",
    "django.contrib.sites.migrations",
] + [module + ".migrations" for module in settings["installed_apps"]]

# Copy migration files.
for mod in migration_modules:
    mod_name, bundle_name = mod.split(".", 1)
    mod_dir = os.path.dirname(get_module_file_attribute(mod_name))
    bundle_dir = bundle_name.replace(".", os.sep)
    pattern = os.path.join(mod_dir, bundle_dir, "*.py")
    files = glob.glob(pattern)
    for f in files:
        datas.append((f, os.path.join(mod_name, bundle_dir)))

settings_imports = []

for value in settings.values():
    settings_imports += value

for mod in settings_imports:
    hiddenimports += collect_submodules(mod, submodule_filter)

for subm in hiddenimports:
    datas += collect_data_files(subm)

datas = list(set(filter(datas_filter, datas)))

hiddenimports += [
    "http.cookies",
    "html.parser",
]