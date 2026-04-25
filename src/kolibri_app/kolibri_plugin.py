import getpass
import hmac

from kolibri.core.device.hooks import GetOSUserHook
from kolibri.plugins import KolibriPluginBase
from kolibri.plugins.hooks import register_hook


class KolibriApp(KolibriPluginBase):
    kolibri_option_defaults = "options_defaults"


@register_hook
class KolibriAppGetOSUserHook(GetOSUserHook):
    # Shared secret between the wxPython host process and this hook, set
    # once per app launch by server_process_windows. Without the comparison,
    # any localhost client holding the (separate) device app key would be
    # auto-logged in as the desktop OS user.
    expected_auth_token = None

    def get_os_user(self, auth_token):
        expected = self.expected_auth_token
        if (
            expected is None
            or not auth_token
            or not hmac.compare_digest(auth_token, expected)
        ):
            return (None, False)

        try:
            username = getpass.getuser()
        except OSError:
            return (None, False)
        return (username, True)
