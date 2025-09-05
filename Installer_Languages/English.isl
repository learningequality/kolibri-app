; English messages for Kolibri Installer
#include "compiler:Default.isl"

[LangOptions]
LanguageName=English
LanguageID=$0409
LanguageCodePage=1252

[CustomMessages]
InstallServiceTask=Run Kolibri automatically when the computer starts

NewerVersionInstalled=A newer version of {#AppName} (%1) is already installed. This installer contains version %2, which is older. The setup will now exit.
SameVersionInstalled=This version of {#AppName} is already installed. Do you want to repair the installation by reinstalling it?
OlderVersionInstalled=An older version of {#AppName} (%1) was detected. Do you want to upgrade to version {#AppVersion}?

ConfirmUninstallData=Do you want to completely remove all Kolibri user data? This includes all downloaded content, user accounts, and progress, and cannot be undone.

CriticalError=A critical error occurred while trying to run a setup command: %1. The installation cannot continue.
CommandError=A command required for setup failed to execute correctly: %1. Error Code: %2. The installation cannot continue.
VersionParseError=Could not compare versions due to an invalid version format. Please uninstall the previous version manually and try again.
