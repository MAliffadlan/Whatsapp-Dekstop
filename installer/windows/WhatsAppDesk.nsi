; WhatsApp Desk — Windows installer (NSIS, per-user, no admin required).
;
; Design: installs WhatsAppDesk.exe to %LOCALAPPDATA%\WhatsApp Desk so the
; in-app self-updater can replace the binary without elevation.
; Build from repo root:  makensis /DVERSION=1.5.9.2 installer\windows\WhatsAppDesk.nsi
; Output: WhatsApp-Desk-Windows-x64-Setup.exe (repo root).

!define APPNAME "WhatsApp Desk"
!define APPID "WhatsAppDesk"
!define APPEXE "WhatsAppDesk.exe"
!define PUBLISHER "WhatsApp Desk Contributors"
!define APPURL "https://github.com/vianziro/Whatsapp-Dekstop"

!ifndef VERSION
!define VERSION "1.5.9.2"
!endif

Name "${APPNAME} ${VERSION}"
; NOTE: relative paths are resolved against this script's directory
; (installer/windows), so ../.. points at the repo root on every host.
OutFile "../../WhatsApp-Desk-Windows-x64-Setup.exe"
InstallDir "$LOCALAPPDATA\${APPNAME}"
InstallDirRegKey HKCU "Software\${APPID}" "InstallDir"
RequestExecutionLevel user
ShowInstDetails show
ShowUninstDetails show

!include "MUI2.nsh"
!define MUI_ABORTWARNING
!define MUI_ICON "../../icon.ico"
!define MUI_UNICON "../../icon.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APPEXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Jalankan ${APPNAME} sekarang"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Indonesian"

Section "${APPNAME}" SEC_APP
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "../../${APPEXE}"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Registry: install location + Programs and Features entry (HKCU = per-user).
  WriteRegStr HKCU "Software\${APPID}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\${APPID}" "Version" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "URLInfoAbout" "${APPURL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "DisplayIcon" "$INSTDIR\${APPEXE}"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}" \
    "NoRepair" 1

  ; Shortcuts: Start Menu (always) + Desktop.
  SetShellVarContext current
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\${APPEXE}" "" \
    "$INSTDIR\${APPEXE}" 0
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${APPEXE}" "" \
    "$INSTDIR\${APPEXE}" 0
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$INSTDIR\${APPEXE}"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"
  Delete "$DESKTOP\${APPNAME}.lnk"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}"
  DeleteRegKey HKCU "Software\${APPID}"
SectionEnd
