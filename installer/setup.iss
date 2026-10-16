; ==========================================================
; Script de Inno Setup: POS Plug & Play (Mantenible)
; ==========================================================

#define MyAppName "POS Plug & Play"
#define MyAppVersion "1.0"
#define MyAppPublisher "Mi Empresa"
#define MyAppURL "https://www.example.com/"
#define MyAppExeName "pos.exe"

; Parámetros centralizados para fácil mantenimiento
#define ServiceName "MiPosCoreDatabaseEngine"
#define DBFolderName "MiPosCore"
#define CustomDBPort "5438"

[Setup]
AppId={{57147EAF-FFD4-43B3-92B9-2FF9AE411F22}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=D:\Flutter\pos\installer_output
OutputBaseFilename=POS_Setup_v1.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=yes
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Types]
Name: "server"; Description: "Servidor Principal (Instala Base de Datos y Motor local)"
Name: "terminal"; Description: "Terminal / Caja (Solo la Aplicación Cliente)"

[Components]
Name: "app"; Description: "Aplicación Principal (POS)"; Types: server terminal; Flags: fixed
Name: "database"; Description: "Motor de Base de Datos PostgreSQL y Servicios"; Types: server

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "D:\Flutter\pos\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: app; Excludes: "server\pgdata\*,pgAdmin 4\*"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--role=server"; Components: database; Tasks: desktopicon
Name: "{autodesktop}\{#MyAppName} (Terminal)"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--role=terminal"; Components: not database; Tasks: desktopicon

[Run]
; 0. Limpieza previa del servicio de manera limpia
Filename: "sc"; Parameters: "delete {#ServiceName}"; Components: database; Flags: runhidden; StatusMsg: "Limpiando registros anteriores..."

; 1. Inicializa el clúster en ProgramData
Filename: "{app}\server\postgresqlbin\postgresql-18.6-5-windows-x64\pgsql\bin\initdb.exe"; Parameters: "-D ""{commonappdata}\{#DBFolderName}\pgdata"" -U postgres -A trust --encoding=UTF8"; Components: database; Flags: runhidden; StatusMsg: "Inicializando clúster de base de datos..."

; 2. Configura el puerto personalizado inyectándolo directamente en el archivo postgresql.conf
Filename: "cmd.exe"; Parameters: "/c echo port = {#CustomDBPort} >> ""{commonappdata}\{#DBFolderName}\pgdata\postgresql.conf"""; Components: database; Flags: runhidden; StatusMsg: "Asignando puerto de red personalizado..."

; 3. Otorga permisos de control total limpios a servicios y usuarios locales
Filename: "icacls"; Parameters: "{commonappdata}\{#DBFolderName} /grant ""NT AUTHORITY\NETWORK SERVICE:(OI)(CI)F"" /grant ""*S-1-5-32-545:(OI)(CI)F"" /T"; Components: database; Flags: runhidden; StatusMsg: "Aplicando permisos de seguridad en directorios..."

; 4. Registra el servicio de Windows
Filename: "{app}\server\postgresqlbin\postgresql-18.6-5-windows-x64\pgsql\bin\pg_ctl.exe"; Parameters: "register -N ""{#ServiceName}"" -D ""{commonappdata}\{#DBFolderName}\pgdata"" -U ""NT AUTHORITY\NetworkService"" -w"; Components: database; Flags: runhidden; StatusMsg: "Registrando servicio de base de datos..."

; 5. Configura el servicio para arranque automático
Filename: "sc"; Parameters: "config {#ServiceName} obj= ""NT AUTHORITY\NetworkService"" start= auto"; Components: database; Flags: runhidden; StatusMsg: "Configurando privilegios y arranque automático..."

; 6. Inicia el servicio
Filename: "net"; Parameters: "start {#ServiceName}"; Components: database; Flags: runhidden; StatusMsg: "Iniciando motor de base de datos..."

; 7. Lanza la app al terminar
Filename: "{app}\{#MyAppExeName}"; Parameters: "--role=server"; Components: database; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}} (Servidor)"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "net"; Parameters: "stop {#ServiceName}"; Flags: runhidden; RunOnceId: "StopService"
Filename: "sc"; Parameters: "delete {#ServiceName}"; Flags: runhidden; RunOnceId: "DeleteService"

[InstallDelete]
Type: filesandordirs; Name: "{commonappdata}\{#DBFolderName}"

[Code]
var
  ServerIpPage: TInputQueryWizardPage;

procedure InitializeWizard();
begin
  // Creamos la página para capturar la IP del servidor de forma interactiva
  ServerIpPage := CreateInputQueryPage(wpSelectTasks,
    'Configuración de Red del Servidor', 
    'Indique la dirección IP del equipo servidor principal',
    'Por favor, introduzca la dirección IP estática del servidor en su red local:');
  
  ServerIpPage.Add('Dirección IP del Servidor:', False);
  ServerIpPage.Values[0] := ''; // Prefijo guía no bloqueante
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  // Si el usuario eligió el tipo "Servidor" (está seleccionado el componente database), omitimos la pantalla de IP
  if (PageID = ServerIpPage.ID) and WizardIsComponentSelected('database') then
    Result := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  // Validar que no se deje la IP vacía si estamos en la pantalla de la terminal
  if (CurPageID = ServerIpPage.ID) and not WizardIsComponentSelected('database') then
  begin
    if Trim(ServerIpPage.Values[0]) = '' then
    begin
      MsgBox('Debe ingresar una dirección IP válida para que la terminal se conecte con el servidor.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure WriteConfigFile(IsServerMode: Boolean);
var
  ConfigPath: String;
  Content: String;
  HostValue: String;
begin
  // Si es servidor, va en ProgramData; si es terminal, se guarda localmente junto al ejecutable o ruta requerida
  if IsServerMode then
  begin
    ConfigPath := ExpandConstant('{commonappdata}\{#DBFolderName}\db_config.json');
    ForceDirectories(ExtractFileDir(ConfigPath));
    HostValue := 'localhost';
  end
  else
  begin
    ConfigPath := ExpandConstant('{app}\db_config.json');
    HostValue := Trim(ServerIpPage.Values[0]); // Captura exactamente la IP introducida por el usuario
  end;

  Content := '{' + #13#10 +
             '  "db_host": "' + HostValue + '",' + #13#10 +
             '  "db_port": {#CustomDBPort},' + #13#10 +
             '  "db_name": "mipos_db",' + #13#10 +
             '  "db_user": "postgres",' + #13#10 +
             '  "is_server": ' + IntToStr(Ord(IsServerMode)) + #13#10 +
             '}';

  SaveStringToFile(ConfigPath, Content, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Evalúa si se eligió el componente servidor o es una terminal pura
    WriteConfigFile(WizardIsComponentSelected('database'));
  end;
end;