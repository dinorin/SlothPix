; Inno Setup Script cho SlothPix
#define MyAppName "SlothPix"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "SlothPix Team"
#define MyAppExeName "slothpix.exe"

[Setup]
AppId={{D3F1E2A3-B4C5-4D6E-8F90-1A2B3C4D5E6F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={commonpf}\{#MyAppName}
DisableDirPage=yes
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Bạn có thể gán icon cho file Setup tại đây:
; SetupIconFile=assets\setup_icon.ico
OutputDir=.
OutputBaseFilename=SlothPix_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Copy file exe từ thư mục build release của Rust
Source: "target\release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Registry]
; Đăng ký Menu chuột phải (Context Menu) cho các loại file ảnh qua SystemFileAssociations
; .jpg
Root: HKCR; Subkey: "SystemFileAssociations\.jpg\shell\SlothPix"; ValueType: string; ValueName: ""; ValueData: "✨ SlothPix: Xóa Nền"; Flags: uninsdeletekey
Root: HKCR; Subkey: "SystemFileAssociations\.jpg\shell\SlothPix\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" --path ""%1"""; Flags: uninsdeletekey
; .jpeg
Root: HKCR; Subkey: "SystemFileAssociations\.jpeg\shell\SlothPix"; ValueType: string; ValueName: ""; ValueData: "✨ SlothPix: Xóa Nền"; Flags: uninsdeletekey
Root: HKCR; Subkey: "SystemFileAssociations\.jpeg\shell\SlothPix\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" --path ""%1"""; Flags: uninsdeletekey
; .png
Root: HKCR; Subkey: "SystemFileAssociations\.png\shell\SlothPix"; ValueType: string; ValueName: ""; ValueData: "✨ SlothPix: Xóa Nền"; Flags: uninsdeletekey
Root: HKCR; Subkey: "SystemFileAssociations\.png\shell\SlothPix\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" --path ""%1"""; Flags: uninsdeletekey
; .webp
Root: HKCR; Subkey: "SystemFileAssociations\.webp\shell\SlothPix"; ValueType: string; ValueName: ""; ValueData: "✨ SlothPix: Xóa Nền"; Flags: uninsdeletekey
Root: HKCR; Subkey: "SystemFileAssociations\.webp\shell\SlothPix\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" --path ""%1"""; Flags: uninsdeletekey

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
