; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#include "./scripts/common.iss"

[Setup]
AppName=LinkerMod
AppVersion=0.0.1
UninstallDisplayIcon={app}\LinkerMod.exe

#if BUILD_TYPE == 'PRODUCTION'
	WizardImageFile=C:\Users\SE2Dev\Pictures\dface_512x512.bmp
	WizardSmallImageFile=C:\Users\SE2Dev\Pictures\dface_512x512.bmp
#endif


[Icons]
Name: "{commondesktop}\Game Mod";	Filename: "{#BinDir}\BlackOps.exe"
; Name: "{group}\LinkerMod\Game_Mod"; Filename: "{#BinDir}\BlackOps.exe"

Name: "{commondesktop}\Launcher";	Filename: "{#BinDir}\Launcher.exe"
Name: "{commondesktop}\Radiant";	Filename: "{#BinDir}\CoDBORadiant.exe"

[Components]
Name: "GameMod";	Description: "Game Mod";	\
					Types: full compact custom;	\
					Flags: fixed

; exlusive flag makes them radio buttons
Name: "LinkerMod"; 			Description: "Mod Tools"; Types: full custom
Name: "LinkerMod\Utils";	Description: "Asset Utility";	Types: full;	Flags:
Name: "LinkerMod\Mapping";	Description: "Radiant Mod";		Types: full;	Flags:
Name: "LinkerMod\Assets";	Description: "Additional Assets"; Types: full;	Flags: fixed

[Tasks]
Name: extract;	Description: "Extract Assets";	\
				Components: LinkerMod\Utils;
Name: extract\iwd; 	Description: "Extract I&WDs"; 			\
					Components: LinkerMod\Utils;
Name: extract\iwd\img; 	Description: "Extract &Images"; 	\
						Components: LinkerMod\Utils;
Name: extract\iwd\snd; 	Description: "Extract &Sounds"; 	\
						Components: LinkerMod\Utils;
Name: extract\iwd\raw;	Description: "Extract &Rawfiles"; 	\
						Components: LinkerMod\Utils;

Name: extract\ffs; 		Description: "Extract &FastFiles"; 		\
						Components: LinkerMod\Utils;
Name: extract\ffs\snd; 	Description: "Extract &Sounds"; 		\
						Components: LinkerMod\Utils;
Name: extract\ffs\raw; 	Description: "Extract &Rawfiles"; 		\
						Components: LinkerMod\Utils;
Name: extract\ffs\ents; Description: "Extract &Entity Maps"; 	\
						Components: LinkerMod\Utils;

[Files]
; Source: "README.md"; DestDir: "{app}"; Flags: isreadme

;
; Actual LinkerMod binaries
;
Source: "build\Release\proxy.dll";			DestDir: "{#BinDir}";
Source: "build\Release\game_mod.dll";		DestDir: "{#BinDir}"; Components: GameMod
Source: "build\Release\linker_pc.dll";		DestDir: "{#BinDir}"; Components: LinkerMod
Source: "build\Release\asset_util.exe";		DestDir: "{#BinDir}"; Components: LinkerMod\Utils
Source: "build\Release\cod2map.dll";		DestDir: "{#BinDir}"; Components: LinkerMod\Mapping
Source: "build\Release\cod2rad.dll";		DestDir: "{#BinDir}"; Components: LinkerMod\Mapping
Source: "build\Release\radiant_mod.dll";	DestDir: "{#BinDir}"; Components: LinkerMod\Mapping

;
; Mod Tools asset files
;

; Utility scripts
Source: "components\scripts\*";		DestDir: "{#BinDir}\scripts";	\
									Components: LinkerMod\Utils; 	\
									Flags: recursesubdirs;

#if BUILD_TYPE == 'PRODUCTION'
; Custom / missing assets
Source: "components\resource\*";	DestDir: "{app}";		\
									Components: LinkerMod;	\
									Flags: recursesubdirs;
#endif

; Test automatic shit
; Source: "{code:GetAutoFiles}"; DestDir: "{#BinDir}\debug}";	Components: Debug; Flags: external recursesubdirs createallsubdirs


[Run]
Filename: "{#BinDir}\asset_util.exe";	StatusMsg: "Extracting IWD assets... {#PleaseWait}";		\
										Parameters: "extract-iwd {code:ExtractIWD_ResolveParams}";	\
										WorkingDir:	"{#BinDir}";									\
										Tasks: extract\iwd;
;										Flags: runhidden;											\

Filename: "{#BinDir}\asset_util.exe";	StatusMsg: "Extracting fastfile assets... {#PleaseWait}";	\
										Parameters: "extract-ff {code:ExtractFF_ResolveParams}";	\
										WorkingDir:	"{#BinDir}";									\
										Tasks: extract\ffs\snd extract\ffs\raw

Filename: "{#BinDir}\asset_util.exe";	StatusMsg: "Extracting entity prefabs... {#PleaseWait}";	\
										Parameters: "ents --overwrite --dummyBrushes *";			\
										WorkingDir:	"{#BinDir}";									\
										Tasks: extract\ffs\ents

;										Flags: runhidden;							\
; Filename: "{app}\README.TXT"; Description: "View the README file"; Flags: postinstall shellexec skipifsilent

#if BUILD_TYPE == 'PRODUCTION'
Filename: "{#BinDir}\launcher.exe";		Description: "Launch mod tools";					\
										Flags: postinstall nowait skipifsilent unchecked;
#endif


[Code]
//
// Installer Entrypoint
//
procedure InitializeWizard;
begin
	// We don't need to do anything special here
	PE_AddNamedImport(WizardDirValue + '\bin\zee.exe', 'KERNEL32.dll', 'GetFullPathNameA');
	PE_AddNamedImport(WizardDirValue + '\bin\zee.exe', 'KERNEL32.dll', 'acorn');
end;

//
// Called when the user hits the "Next" button
//
function NextButtonClick(curPageID:integer): boolean;
begin
	// Automatically handle installation path validation
	Result := Com_ValidateInstallPath(curPageID);
end;

//
// Check if a given task is enabled - if it is, we append the mappedValue
// to argString and return argString
//
function AddRunArgument(var argString: string; taskName: string; mappedValue: string): string;
begin
	if IsTaskSelected(taskName) then
		argString := argString + ' ' + mappedValue;
	Result := argString;
end;

//
// Resolve the asset_util parameters for IWD asset extraction
//
function ExtractIWD_ResolveParams(param: String): string;
begin
	Result := ' --overwrite --includeLocalized';

	AddRunArgument(Result, 'extract\iwd\img', '--images');
	AddRunArgument(Result, 'extract\iwd\snd', '--sounds');
	AddRunArgument(Result, 'extract\iwd\raw', '--rawfiles');

	MsgBox('IWD PARAMS: ' + Result, mbError, MB_YESNO);
end;

//
// Resolve the asset_util parameters for fastfile asset extraction
// TODO: Make this auto skip if sound & rawfiles are both empty
//
function ExtractFF_ResolveParams(param: String): string;
begin
	Result := ' --overwrite --includeLocalized';

	AddRunArgument(Result, 'extract\ffs\snd', '--sounds');
	AddRunArgument(Result, 'extract\ffs\raw', '--rawfiles');

	MsgBox('FF PARAMS: ' + Result, mbError, MB_YESNO);
end;
