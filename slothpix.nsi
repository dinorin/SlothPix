; SlothPix NSIS Script - Clean Version
!include "MUI2.nsh"

!define APPNAME "SlothPix"
!define COMPANYNAME "SlothPix Team"
!define DESCRIPTION "AI-Powered Background Remover"
!define VERSION "1.0.0"
!define EXE_NAME "slothpix.exe"

; Icon configuration
!define MUI_ICON "assets\app_icon.ico"
!define MUI_UNICON "assets\app_icon.ico"

Name "${APPNAME}"
OutFile "SlothPix_Setup.exe"
InstallDir "$PROGRAMFILES64\SlothPix"
RequestExecutionLevel admin

; Modern UI Pages
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath "$INSTDIR"
    
    ; Copy executable
    File "target\release\${EXE_NAME}"
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; --- Registry for Context Menu (Win11 "Show more options" Fallback) ---
    ; 1. Đăng ký cho MỌI định dạng hình ảnh
    WriteRegStr HKCR "SystemFileAssociations\image\shell\SlothPix" "" "SlothPix: Remove Background"
    WriteRegStr HKCR "SystemFileAssociations\image\shell\SlothPix" "Icon" "$INSTDIR\${EXE_NAME}"
    WriteRegStr HKCR "SystemFileAssociations\image\shell\SlothPix\command" "" '"$INSTDIR\${EXE_NAME}" --path "%1"'
    
    ; 2. Đăng ký cứng cho các đuôi cụ thể để đè các app khác
    !macro RegisterMenu EXT
        WriteRegStr HKCR "SystemFileAssociations\${EXT}\shell\SlothPix" "" "SlothPix: Remove Background"
        WriteRegStr HKCR "SystemFileAssociations\${EXT}\shell\SlothPix" "Icon" "$INSTDIR\${EXE_NAME}"
        WriteRegStr HKCR "SystemFileAssociations\${EXT}\shell\SlothPix\command" "" '"$INSTDIR\${EXE_NAME}" --path "%1"'
    !macroend

    !insertmacro RegisterMenu ".jpg"
    !insertmacro RegisterMenu ".jpeg"
    !insertmacro RegisterMenu ".png"
    !insertmacro RegisterMenu ".webp"

    ; Add/Remove Programs integration
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlothPix" "DisplayName" "${APPNAME} - Background Remover"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlothPix" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlothPix" "DisplayIcon" "$INSTDIR\${EXE_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlothPix" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlothPix" "Publisher" "${COMPANYNAME}"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\${EXE_NAME}"
    Delete "$INSTDIR\uninstall.exe"
    RMDir "$INSTDIR"

    ; Xóa Registry
    DeleteRegKey HKCR "SystemFileAssociations\image\shell\SlothPix"
    
    !macro UnregisterMenu EXT
        DeleteRegKey HKCR "SystemFileAssociations\${EXT}\shell\SlothPix"
    !macroend

    !insertmacro UnregisterMenu ".jpg"
    !insertmacro UnregisterMenu ".jpeg"
    !insertmacro UnregisterMenu ".png"
    !insertmacro UnregisterMenu ".webp"

    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SlothPix"
SectionEnd
