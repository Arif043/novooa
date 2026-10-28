import { spawnSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

export interface SshOptions {
  host: string;
  username: string;
  password?: string;
  keyFile?: string;
}

const SSH_BASE_OPTIONS = [
  '-o', 'StrictHostKeyChecking=no',
  '-o', 'UserKnownHostsFile=/dev/null',
  '-o', 'ConnectTimeout=10',
  '-o', 'BatchMode=yes',
];

const SSH_TIMEOUT_MS = 120_000;

/**
 * Findet den SSH-Schlüssel (~/.ssh/id_ed25519, id_rsa, etc.)
 */
function findSshKey(): string | null {
  const sshDir = path.join(os.homedir(), '.ssh');
  const keyNames = ['id_ed25519', 'id_rsa', 'id_ecdsa'];

  for (const name of keyNames) {
    const keyPath = path.join(sshDir, name);
    if (fs.existsSync(keyPath)) {
      return keyPath;
    }
  }
  return null;
}

/**
 * Expandiert ~ zu Home-Verzeichnis.
 */
function expandPath(filePath: string): string {
  return filePath.replace(/^~/, os.homedir());
}

/**
 * Löst die zu verwendende SSH-Schlüssel-Datei auf und validiert sie.
 */
function resolveKeyFile(options: SshOptions): string {
  const configured = options.keyFile ? expandPath(options.keyFile) : null;
  const keyFile = configured ?? findSshKey();

  if (!keyFile) {
    throw new Error(
      'SSH-Schlüssel nicht gefunden. Generiere einen mit: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""',
    );
  }
  if (!fs.existsSync(keyFile)) {
    throw new Error(`SSH-Schlüssel-Datei nicht gefunden: ${keyFile}`);
  }
  return keyFile;
}

/**
 * Kodiert ein PowerShell-Skript für `-EncodedCommand` (UTF-16LE, Base64).
 *
 * Das umgeht sämtliche Quoting-Probleme über die vielen Schichten
 * (lokale Shell, ssh-Argument, Windows sshd, PowerShell-Parser): Base64
 * enthält nur [A-Za-z0-9+/=], das ist in jeder Schicht unverändert sicher.
 */
function encodePowerShellCommand(script: string): string {
  return Buffer.from(script, 'utf16le').toString('base64');
}

/**
 * Führt ein PowerShell-Skript auf dem Remote-Windows-Rechner über SSH aus.
 * Nutzt Argument-Arrays (kein lokales Shell-Parsing) und `-EncodedCommand`
 * (kein Remote-Quoting-Problem).
 */
export async function executeSshCommand(
  options: SshOptions,
  script: string,
): Promise<string> {
  const encoded = encodePowerShellCommand(script);
  const host = `${options.username}@${options.host}`;
  const remoteArgs = [host, 'powershell', '-NoProfile', '-EncodedCommand', encoded];

  const { command, args } = options.password
    ? buildPasswordInvocation(options.password, remoteArgs)
    : buildKeyInvocation(options, remoteArgs);

  const result = spawnSync(command, args, {
    encoding: 'utf-8',
    timeout: SSH_TIMEOUT_MS,
  });

  if (result.error) {
    const err = result.error as NodeJS.ErrnoException;
    if (err.code === 'ENOENT') {
      throw new Error(
        `Befehl "${command}" nicht gefunden. ${command === 'sshpass' ? 'Installiere es mit: brew install sshpass' : 'Ist OpenSSH-Client installiert?'}`,
      );
    }
    throw new Error(`SSH-Befehl fehlgeschlagen: ${err.message}`);
  }

  if (result.status !== 0) {
    const stderr = (result.stderr ?? '').trim();
    const stdout = (result.stdout ?? '').trim();
    const detail = stderr || stdout || `Exit-Code ${result.status}`;
    if (detail.includes('Permission denied')) {
      throw new Error('SSH: Authentifizierung fehlgeschlagen (Schlüssel oder Passwort falsch)');
    }
    throw new Error(`SSH-Befehl fehlgeschlagen: ${detail}`);
  }

  return (result.stdout ?? '').trim();
}

function buildKeyInvocation(
  options: SshOptions,
  remoteArgs: string[],
): { command: string; args: string[] } {
  const keyFile = resolveKeyFile(options);
  return {
    command: 'ssh',
    args: ['-i', keyFile, ...SSH_BASE_OPTIONS, ...remoteArgs],
  };
}

function buildPasswordInvocation(
  password: string,
  remoteArgs: string[],
): { command: string; args: string[] } {
  return {
    command: 'sshpass',
    args: ['-p', password, 'ssh', ...SSH_BASE_OPTIONS, ...remoteArgs],
  };
}

/**
 * Prüft ob Host erreichbar ist via SSH.
 */
export async function testConnection(options: SshOptions): Promise<boolean> {
  try {
    const result = await executeSshCommand(options, `Write-Output 'OK'`);
    return result.includes('OK');
  } catch {
    return false;
  }
}

/**
 * Überprüft ob ein Pfad auf dem Remote-Rechner existiert.
 */
export async function repositoryExists(
  options: SshOptions,
  targetPath: string,
): Promise<boolean> {
  const script = `if (Test-Path "${targetPath}") { Write-Output 'exists' } else { Write-Output 'missing' }`;
  const result = await executeSshCommand(options, script);
  return result.includes('exists');
}

/**
 * Erstellt ein Verzeichnis rekursiv auf dem Remote-Rechner (idempotent).
 */
export async function ensureDirectory(
  options: SshOptions,
  directoryPath: string,
): Promise<void> {
  const script = `New-Item -ItemType Directory -Force -Path "${directoryPath}" | Out-Null; Write-Output 'ok'`;
  await executeSshCommand(options, script);
}

/**
 * Klont das Repository auf den Remote-Windows-Rechner, oder aktualisiert es,
 * falls es bereits existiert. Legt fehlende Elternverzeichnisse automatisch an.
 */
export async function cloneRepository(
  options: SshOptions,
  repoUrl: string,
  targetPath: string,
): Promise<void> {
  const parentDir = targetPath.substring(0, targetPath.lastIndexOf('\\'));
  if (parentDir) {
    await ensureDirectory(options, parentDir);
  }

  const script = `
if (Test-Path "${targetPath}") {
  Set-Location "${targetPath}"
  git pull
} else {
  git clone "${repoUrl}" "${targetPath}"
}
`;

  await executeSshCommand(options, script);
}

/**
 * Startet den Flutter Windows-Build auf dem Remote-Rechner.
 * Obfuskiert Dart-Symbole, damit das ausgelieferte Binary schwerer
 * rückzuentwickeln ist; die Symboltabellen bleiben für Stacktraces lokal.
 */
export async function buildFlutterWindows(
  options: SshOptions,
  repoPath: string,
  apiUrl: string,
): Promise<void> {
  const script = `
Set-Location "${repoPath}"
flutter build windows --dart-define=WORKSPACE_API_URL=http://${apiUrl}:8090 --release --obfuscate --split-debug-info=build\\symbols
`;

  await executeSshCommand(options, script);
}

function composeFilePath(repoPath: string): string {
  return `${repoPath}\\docker-compose.local.yaml`;
}

/**
 * Startet Docker Compose auf dem Remote-Rechner.
 */
export async function startDockerCompose(
  options: SshOptions,
  repoPath: string,
): Promise<void> {
  const script = `docker compose -f "${composeFilePath(repoPath)}" up --build --detach`;
  await executeSshCommand(options, script);
}

/**
 * Prüft den Docker Compose Status.
 */
export async function checkDockerStatus(options: SshOptions, repoPath: string): Promise<string> {
  const script = `docker compose -f "${composeFilePath(repoPath)}" ps`;
  return executeSshCommand(options, script);
}

/**
 * Zeigt die letzten Docker Compose Logs.
 */
export async function showDockerLogs(options: SshOptions, repoPath: string): Promise<string> {
  const script = `docker compose -f "${composeFilePath(repoPath)}" logs --tail=50`;
  return executeSshCommand(options, script);
}

/**
 * Stoppt Docker Compose.
 */
export async function stopDockerCompose(options: SshOptions, repoPath: string): Promise<void> {
  const script = `docker compose -f "${composeFilePath(repoPath)}" down`;
  await executeSshCommand(options, script);
}
