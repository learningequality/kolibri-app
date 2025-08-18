; === Preprocessor Definitions: A single source of truth for configuration ===
#define AppName "Kolibri"
#define AppPublisher "Learning Equality"
#define AppPublisherURL "https://learningequality.org/"
#define AppExeName "KolibriApp.exe"
#define ServiceName AppName
#ifndef AppVersion
  #error "The AppVersion definition must be passed to the compiler via the command line, e.g., /DAppVersion=x.y.z"
#endif
#define SourceDir "dist\" + AppName + "-" + AppVersion
#define KolibriDataDir "{commonappdata}\kolibri"
#define NssmExePath "{app}\nssm\nssm.exe"
#define TaskkillExePath "{sys}\taskkill.exe"

; === GUID Constants ===
;
; Application ID: Unique identifier for this Kolibri application installation
; Generated using standard GUID generation, this is specific to our application
#define AppGuid "432F09E1-B036-4A2C-8F99-DAB7FA094507"
;
; WebView2 Runtime Client GUID: Microsoft's official identifier for WebView2 Runtime
; Source: https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution?tabs=dotnetcsharp
; WARNING: If Microsoft changes this GUID in future WebView2 versions, the IsWebView2Installed() function will fail to detect installations
#define WebView2RuntimeGuid "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

[Setup]
AppId={#AppGuid}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppPublisherURL}
DefaultDirName={autopf64}\{#AppName}
OutputDir=dist-installer
OutputBaseFilename=kolibri-setup-{#AppVersion}
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#AppExeName}
SetupLogging=yes
CloseApplicationsFilter={#AppExeName}
ShowLanguageDialog=yes

[Languages]
Name: "en"; MessagesFile: "{#SourcePath}\Installer_Languages\English.isl"
; Name: "ar"; MessagesFile: "{#SourcePath}\Installer_Languages\Arabic.isl"
; Name: "bg"; MessagesFile: "{#SourcePath}\Installer_Languages\Bulgarian.isl"
; Name: "bn"; MessagesFile: "{#SourcePath}\Installer_Languages\Bengali.isl"
; Name: "my"; MessagesFile: "{#SourcePath}\Installer_Languages\Burmese.isl"
; Name: "ny"; MessagesFile: "{#SourcePath}\Installer_Languages\Chewa.isl"
; Name: "zh_CN"; MessagesFile: "{#SourcePath}\Installer_Languages\Chinese_Simplified.isl"
Name: "de"; MessagesFile: "{#SourcePath}\Installer_Languages\German.isl"
; Name: "fa"; MessagesFile: "{#SourcePath}\Installer_Languages\Persian.isl"
; Name: "fr"; MessagesFile: "{#SourcePath}\Installer_Languages\French.isl"
; Name: "fv"; MessagesFile: "{#SourcePath}\Installer_Languages\Fulfulde_Mbororoore.isl"
; Name: "ka"; MessagesFile: "{#SourcePath}\Installer_Languages\Georgian.isl"
; Name: "gu_IN"; MessagesFile: "{#SourcePath}\Installer_Languages\Gujarati.isl"
; Name: "hi"; MessagesFile: "{#SourcePath}\Installer_Languages\Hindi.isl"
; Name: "it"; MessagesFile: "{#SourcePath}\Installer_Languages\Italian.isl"
; Name: "km"; MessagesFile: "{#SourcePath}\Installer_Languages\Khmer.isl"
; Name: "ko"; MessagesFile: "{#SourcePath}\Installer_Languages\Korean.isl"
; Name: "la"; MessagesFile: "{#SourcePath}\Installer_Languages\Spanish_Latin_America.isl"
; Name: "mr"; MessagesFile: "{#SourcePath}\Installer_Languages\Marathi.isl"
; Name: "ne_NP"; MessagesFile: "{#SourcePath}\Installer_Languages\Nepali.isl"
; Name: "pt_BR"; MessagesFile: "{#SourcePath}\Installer_Languages\Portuguese_Brazilian.isl"
; Name: "es_ES"; MessagesFile: "{#SourcePath}\Installer_Languages\Spanish.isl"
; Name: "sw_TZ"; MessagesFile: "{#SourcePath}\Installer_Languages\Swahili_Tanzania.isl"
; Name: "tl"; MessagesFile: "{#SourcePath}\Installer_Languages\Tagalog.isl"
; Name: "te"; MessagesFile: "{#SourcePath}\Installer_Languages\Telugu.isl"
; Name: "tr"; MessagesFile: "{#SourcePath}\Installer_Languages\Turkish.isl"
; Name: "ur_PK"; MessagesFile: "{#SourcePath}\Installer_Languages\Urdu_(Pakistan).isl"
; Name: "vi"; MessagesFile: "{#SourcePath}\Installer_Languages\Vietnamese.isl"
; Name: "yo"; MessagesFile: "{#SourcePath}\Installer_Languages\Yoruba.isl"

[Registry]
; This registry key is used to detect the installed version for upgrades/repairs.
Root: HKLM; Subkey: "Software\Kolibri"; ValueType: string; ValueName: "Version"; ValueData: "{#AppVersion}"; Flags: uninsdeletekey

[Tasks]
Name: "installservice"; Description: "{cm:InstallServiceTask}"; GroupDescription: "Installation Type:";
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";

[Dirs]
Name: "{#KolibriDataDir}"

[Files]
; WebView2 runtime installer, placed in {tmp} and deleted after installation
Source: "MicrosoftEdgeWebView2RuntimeInstallerX64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

Source: "{#SourceDir}\{#AppName}-{#AppVersion}.exe"; DestDir: "{app}"; DestName: "{#AppExeName}"; Flags: ignoreversion
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "{#AppName}-{#AppVersion}.exe"
Source: "nssm.exe"; DestDir: "{app}\nssm"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Run WebView2 installer only if runtime is not already installed
Filename: "{tmp}\MicrosoftEdgeWebView2RuntimeInstallerX64.exe"; \
    Parameters: "/silent /install"; \
    Flags: runhidden waituntilterminated; \
    Check: not IsWebView2Installed
; Launch app UI after installation completes
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall shellexec

[UninstallRun]
; Service uninstallation sequence - stops and removes service before file deletion
; 1. Stop the Kolibri service.
Filename: "net.exe"; Parameters: "stop {#ServiceName}"; Flags: runhidden waituntilterminated; RunOnceId: "stopservice"
; 2. Remove the Kolibri service definition.
Filename: "{#NssmExePath}"; Parameters: "remove {#ServiceName} confirm"; Flags: runhidden waituntilterminated; RunOnceId: "removeservice"
; 3. Stop the UI process
Filename: "{#TaskkillExePath}"; Parameters: "/F /IM {#AppExeName}"; Flags: runhidden waituntilterminated; RunOnceId: "killapp"

[Code]

// Constants to avoid magic numbers and repeated paths
const
  TASKKILL_ERR_NOT_FOUND = 128;
  ICACLS_EXE_PATH = '{sys}\icacls.exe';
  SC_EXE_PATH = '{sys}\sc.exe';

// Robust wrapper for executing external commands with error checking
procedure ExecChecked(const Filename, Params, WorkingDir: String; const Description: String);
var
   ResultCode: Integer;
begin
   Log(Format('Executing command: %s', [Description]));
   Log(Format('   -> File: %s', [Filename]));
   Log(Format('   -> Parameters: %s', [Params]));
   if not Exec(Filename, Params, WorkingDir, SW_HIDE, ewWaitUntilTerminated, ResultCode) then
   begin
      // if the process fails to launch
      Log(Format('ERROR: Failed to launch process for "%s". System Error: %s', [Description, SysErrorMessage(ResultCode)]));
      if not WizardSilent() then
         MsgBox(FmtMessage(CustomMessage('CriticalError'), [Description]), mbError, MB_OK);
      Abort;
   end;
   if ResultCode <> 0 then
   begin
      Log(Format('ERROR: Command "%s" failed with a non-zero exit code: %d.', [Description, ResultCode]));
      if not WizardSilent() then
         MsgBox(FmtMessage(CustomMessage('CommandError'), [Description, IntToStr(ResultCode)]), mbError, MB_OK);
      Abort;
   end
   else
   begin
      Log(Format('Command "%s" completed successfully.', [Description]));
   end;
end;

// Check for existing versions and handle upgrade/downgrade/repair scenarios
function InitializeSetup(): Boolean;
var
   InstalledVersionString, InstallerVersionString: string;
   InstalledVersionPacked, InstallerVersionPacked: Int64;
   VersionDiff: Integer;
begin
   Result := True;
   InstallerVersionString := '{#AppVersion}';

   // Read installed version from registry
   if not RegQueryStringValue(HKLM, 'Software\Kolibri', 'Version', InstalledVersionString) then
   begin
      Log('No previous installation detected. Proceeding with a fresh install.');
      Exit; // No previous installation, proceed with fresh install
   end;

   Log(Format('Found installed version: %s. This installer version: %s.', [InstalledVersionString, InstallerVersionString]));

   // Parse both installer and installed version strings for comparison
   if (not StrToVersion(InstallerVersionString, InstallerVersionPacked)) or (not StrToVersion(InstalledVersionString, InstalledVersionPacked)) then
   begin
      Log('ERROR: Could not parse version strings for comparison.');
      Log(Format('  -> Installer Version String: "%s"', [InstallerVersionString]));
      Log(Format('  -> Installed Version String: "%s"', [InstalledVersionString]));
      if not WizardSilent() then
         MsgBox(CustomMessage('VersionParseError'), mbError, MB_OK);
      Result := False;
      Exit;
   end;

   // Log packed version values for debugging
   Log(Format('Packed installer version: %d. Packed installed version: %d.', [InstallerVersionPacked, InstalledVersionPacked]));

   VersionDiff := ComparePackedVersion(InstallerVersionPacked, InstalledVersionPacked);

   if VersionDiff < 0 then
   begin
      Log(Format('Downgrade detected. Installed version %s is newer than installer version %s. Aborting.', [InstalledVersionString, InstallerVersionString]));
      if not WizardSilent() then
         MsgBox(FmtMessage(CustomMessage('NewerVersionInstalled'), [InstalledVersionString, InstallerVersionString]), mbInformation, MB_OK);
      Result := False;
   end
   else if VersionDiff = 0 then
   begin
      Log('Same version detected. Proposing a repair/reinstall.');
      if not WizardSilent() then
      begin
         if MsgBox(CustomMessage('SameVersionInstalled'), mbConfirmation, MB_YESNO) <> IDYES then
            Result := False;
      end;
   end
   else // VersionDiff > 0
   begin
      Log('Older version detected. Proposing an upgrade.');
      if not WizardSilent() then
      begin
         if MsgBox(FmtMessage(CustomMessage('OlderVersionInstalled'), [InstalledVersionString]), mbConfirmation, MB_YESNO) <> IDYES then
            Result := False;
      end;
   end;
end;

// Pre-installation cleanup to unlock files for upgrades
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Log('Setup is preparing to install. Attempting to stop the Kolibri service if it exists...');
  Exec(ExpandConstant(SC_EXE_PATH), 'stop "{#ServiceName}"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if ResultCode = 0 then
    Log('Service "{#ServiceName}" stopped successfully.')
  else
    Log(Format('Command "sc stop" finished with exit code %d. This is normal if the service was not running.', [ResultCode]));

  // Force-kill any running UI processes
  Exec(ExpandConstant('{#TaskkillExePath}'),
       '/F /IM "{#AppExeName}"',
       '',
       SW_HIDE, ewWaitUntilTerminated,
       ResultCode);

  if ResultCode = 0 then
    Log('Successfully killed Kolibri UI.')
  else if ResultCode = TASKKILL_ERR_NOT_FOUND then
    Log('No running Kolibri UI found (taskkill returned expected error code).')
  else
  begin
    Log(Format('Unexpected taskkill exit code: %d', [ResultCode]));
  end;

  Result := '';
end;

// Check if Windows service is installed
function IsServiceInstalled(const ServiceName: string): Boolean;
var
  ResultCode: Integer;
begin
  // Use 'sc.exe query' - non-zero exit code means service doesn't exist
  // Don't use ExecChecked since non-zero exit code is expected for missing services
  Exec(ExpandConstant(SC_EXE_PATH), 'query "' + ServiceName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
  if Result then
    Log(Format('Checked for service "%s". Exists: yes. (sc.exe query exit code: %d)', [ServiceName, ResultCode]))
  else
    Log(Format('Checked for service "%s". Exists: no. (sc.exe query exit code: %d)', [ServiceName, ResultCode]));
end;

// Configure service after file installation
procedure CurStepChanged(CurStep: TSetupStep);
var
  AppPath, AppDir, NssmPath, Params: String;
  ResultCode: Integer;
begin
  // Only act after file installation is complete
  if (CurStep = ssPostInstall) then
  begin
    // Pre-expand constants for clarity
    AppPath := ExpandConstant('{app}\{#AppExeName}');
    AppDir := ExpandConstant('{app}');
    NssmPath := ExpandConstant('{#NssmExePath}');

    // Check if user selected service installation
    if (WizardIsTaskSelected('installservice')) then
    begin
      Log('Post-install step: User selected to install/update the Kolibri service...');

      // Check if service exists to decide install vs update
      if IsServiceInstalled('{#ServiceName}') then
      begin
        // Update existing service
        Log('Service "{#ServiceName}" already exists. Updating configuration...');
        Params := 'set "{#ServiceName}" Application "' + AppPath + '"';
        ExecChecked(NssmPath, Params, '', 'Update Service Executable Path');

        Params := 'set "{#ServiceName}" AppParameters "--run-as-server"';
        ExecChecked(NssmPath, Params, '', 'Update Service Parameters');

        Params := 'set "{#ServiceName}" AppDirectory "' + AppDir + '"';
        ExecChecked(NssmPath, Params, '', 'Update Service Working Directory');
      end
      else
      begin
        // Install new service
        Log('Service "{#ServiceName}" not found. Performing fresh installation...');
        Params := 'install "{#ServiceName}" "' + AppPath + '" --run-as-server';
        ExecChecked(NssmPath, Params, '', 'Install {#ServiceName} Service');
      end;

      // Apply common service configuration
      Log('Applying common service configuration...');
      ExecChecked(NssmPath, 'set "{#ServiceName}" ObjectName "NT AUTHORITY\LocalService"', '', 'Set Service User to LocalService');

      // Grant Modify access to service account
      ExecChecked(ExpandConstant(ICACLS_EXE_PATH), '"' + ExpandConstant('{#KolibriDataDir}') + '" /grant "NT AUTHORITY\LocalService":(OI)(CI)M /T', '', 'Grant Permissions to Data Folder for Service');

      // Grant Modify access to Users for UI app state/logs
      ExecChecked(ExpandConstant(ICACLS_EXE_PATH), '"' + ExpandConstant('{#KolibriDataDir}') + '" /grant "Users":(OI)(CI)M /T', '', 'Grant Permissions to Data Folder for Users');

      ExecChecked(NssmPath, 'set "{#ServiceName}" Start SERVICE_AUTO_START', '', 'Set Service Start Type to Automatic');
      ExecChecked(ExpandConstant(SC_EXE_PATH), 'start "{#ServiceName}"', '', 'Start {#ServiceName} Service');
      ExecChecked(NssmPath, 'set "{#ServiceName}" Description "This service runs the Kolibri server in the background"', '', 'Set Service Description');
      Log('Service configuration completed successfully.');
    end
    else
    begin
      // Remove existing service if user unchecked service task
      Log('Service task was not selected. Checking for pre-existing service to remove.');
      if IsServiceInstalled('{#ServiceName}') then
      begin
        Log('Found existing service "{#ServiceName}". Stopping and removing it as requested by user.');

        // Stop service (okay if it fails - may already be stopped)
        Exec(ExpandConstant('{sys}\net.exe'), 'stop "{#ServiceName}"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        if ResultCode = 0 then
          Log('Service stopped successfully.')
        else
          Log(Format('net stop command finished with exit code %d. This is acceptable if the service was not running.', [ResultCode]));

        // Remove service definition (use ExecChecked - user should know if this fails)
        ExecChecked(NssmPath, 'remove "{#ServiceName}" confirm', '', 'Remove {#ServiceName} Service');
        Log('Service removed successfully.');
      end
      else
      begin
        Log('No pre-existing service found. No removal action needed.');
      end;
    end;
  end;
end;

// Check if WebView2 Runtime is installed to avoid unnecessary installer run
function IsWebView2Installed(): Boolean;
var
    Version: String;
begin
    if RegQueryStringValue(HKLM, 'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{#WebView2RuntimeGuid}', 'pv', Version) then
    begin
        Log('Found WebView2 Runtime version ' + Version + ' (system-wide).');
        Result := True;
    end
    else if RegQueryStringValue(HKCU, 'Software\Microsoft\EdgeUpdate\Clients\{#WebView2RuntimeGuid}', 'pv', Version) then
    begin
        Log('Found WebView2 Runtime version ' + Version + ' (per-user).');
        Result := True;
    end
    else
    begin
        Log('WebView2 Runtime not found. The installer will be run.');
        Result := False;
    end;
end;

var
  g_DeleteUserData: Boolean;

function InitializeUninstall(): Boolean;
begin
  // Default to NOT deleting user data unless the user explicitly agrees.
  g_DeleteUserData := False;

  if MsgBox(CustomMessage('ConfirmUninstallData'),
    mbConfirmation, MB_YESNO) = IDYES then
  begin
    g_DeleteUserData := True;
    Log('User has opted to delete all user data upon uninstallation.');
  end else
  begin
    Log('User has opted to keep user data upon uninstallation.');
  end;

  Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  // The CurUninstallStepChanged event fires at different stages of the uninstallation.
  // We only care about the step after all files have been removed.
  if (CurUninstallStep = usPostUninstall) then
  begin
    if g_DeleteUserData then
    begin
      Log('Executing post-uninstall step: removing user data directory.');
      if DelTree(ExpandConstant('{#KolibriDataDir}'), True, True, True) then
      begin
        Log('Successfully deleted user data directory: ' + ExpandConstant('{#KolibriDataDir}'));
      end
      else
      begin
        Log('WARNING: Failed to delete user data directory: ' + ExpandConstant('{#KolibriDataDir}') +
            '. It may be in use by another process, or permissions may have been altered.');
      end;
    end;
  end;
end;
