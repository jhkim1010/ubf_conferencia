; Mana — Windows 설치 파일(Inno Setup) 스크립트
; CI(GitHub Actions, windows 러너)에서 flutter build windows 후 컴파일됩니다.
;   iscc /DSourceDir=<Release폴더> /DMyAppVersion=1.0.0 mana.iss
; 결과: 이 스크립트 폴더에 mana-setup.exe 생성

#ifndef SourceDir
  ; 로컬 테스트 기본값 (CI에서는 /DSourceDir 로 덮어씀)
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName "Mana"
#define MyAppPublisher "UBF"
#define MyAppExeName "ubf_app.exe"

[Setup]
; 업그레이드 식별용 고정 GUID (버전 올라가도 유지)
AppId={{7C2F9A64-3E1B-4D58-9F0A-2B6C4E8D1A73}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=mana-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Release 폴더 전체(exe + DLL + data)를 설치 폴더로
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
