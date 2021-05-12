import os


KOLIBRI_PORT = 5000
FLASK_PORT = 5226
HOME_TEMPLATE_PATH = 'assets/preseeded_kolibri_home'
DEFAULT_KOLIBRI_HOME = os.path.join(os.path.expanduser('~'), '.endless-key')


def get_content_fallback_dirs():
    # Add fallback content from endless key removable device

    from kolibri.core.discovery.utils.filesystem import enumerate_mounted_disk_partitions
    drives = enumerate_mounted_disk_partitions()
    key_drive = None
    for path, drive in drives.items():
        if drive.name == 'eoslive':
            key_drive = drive
            break

    if not key_drive:
        return None

    fallback_dirs = os.path.join(key_drive.datafolder, 'content')
    return fallback_dirs
