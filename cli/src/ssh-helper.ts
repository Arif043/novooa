import { execSync } from 'child_process';
import chalk from 'chalk';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

export interface SshOptions {
  host: string;
  username: string;
  password?: string;
  keyFile?: string;
}

/**
 * Findet den SSH-Schlüssel (~/.ssh/id_rsa, id_ed25519, etc.)
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
 * Expandiert ~ zu Home-Verzeichnis
 */
function expandPath(filePath: string): string {
  return filePath.replace('~', os.homedir());
}

/**
 * Führt einen PowerShell-Befehl auf dem Remote-Windows-Rechner aus.
 * Nutzt SSH mit Schlüssel-Authentifizierung (bevorzugt) oder Passwort.
 */
export async function executeSshCommand(
  options: SshOptions,
  command: string,
): Promise<string> {
  try {
    // Mit sshpass für Passwort-Auth
    if (options.password) {
      return executeSshWithPassword(options, command);
    }

    // Normale SSH (mit Schlüssel)
    const sshCommand = buildSshCommand(options, command);
    const output = execSync(sshCommand, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
      timeout: 60000,
    });
    return output.trim();
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`SSH-Befehl fehlgeschlagen: ${error.message}`);
    }
    throw error;
  }
}

/**
 * SSH-Befehl mit Passwort-Authentifizierung via sshpass
 */
function executeSshWithPassword(options: SshOptions, command: string): string {
  const host = `${options.username}@${options.host}`;

  // PowerShell-Befehl escapen
  const escapedCmd = command
    .replace(/"/g, '\\"')
    .replace(/\$/g, '\\$')
    .replace(/`/g, '\\`');

  // sshpass -p password ssh ...
  const sshCommand = `sshpass -p "${options.password}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ${host} "powershell -NoProfile -Command \\"${escapedCmd}\\""`;

  try {
    const output = execSync(sshCommand, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
      timeout: 60000,
    });
    return output.trim();
  } catch (error) {
    if (error instanceof Error) {
      const msg = error.message;
      if (msg.includes('Permission denied')) {
        throw new Error('SSH: Passwort falsch oder Benutzer nicht korrekt');
      }
      if (msg.includes('not found')) {
        throw new Error(
          'sshpass nicht installiert. Installiere es oder nutze SSH-Schlüssel.\n  Mac: brew install sshpass\n  Linux: apt-get install sshpass',
        );
      }
      throw new Error(`SSH-Befehl fehlgeschlagen: ${msg}`);
    }
    throw error;
  }
}

/**
 * Baut den SSH-Befehl zusammen (für Schlüssel-Auth).
 */
function buildSshCommand(options: SshOptions, command: string): string {
  const host = `${options.username}@${options.host}`;

  // SSH-Schlüssel auswählen
  let keyFile: string | undefined = options.keyFile;
  if (!keyFile) {
    const found = findSshKey();
    if (found) {
      keyFile = found;
    }
  }
  if (keyFile) {
    keyFile = expandPath(keyFile);
  }

  if (!keyFile) {
    throw new Error(
      'SSH-Schlüssel nicht gefunden. Generiere einen mit: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""',
    );
  }

  // Prüfe ob Schlüssel-Datei existiert
  if (!fs.existsSync(keyFile)) {
    throw new Error(`SSH-Schlüssel-Datei nicht gefunden: ${keyFile}`);
  }

  // PowerShell-Befehl escapen für SSH
  // Wichtig: Backslashes müssen escaped sein für SSH/Shell
  const escapedCmd = command
    .replace(/\\/g, '\\\\') // Backslashes first!
    .replace(/"/g, '\\"')
    .replace(/\$/g, '\\$')
    .replace(/`/g, '\\`');

  // SSH mit Schlüssel
  return `ssh -i "${keyFile}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o BatchMode=yes ${host} "powershell -NoProfile -Command \\"${escapedCmd}\\""`;
}

/**
 * Prüft ob Host erreichbar ist via SSH.
 * Nutzt cmd statt PowerShell für bessere Kompatibilität.
 */
export async function testConnection(options: SshOptions): Promise<boolean> {
  try {
    await executeSshCommand(options, 'cmd /c echo OK');
    return true;
  } catch {
    return false;
  }
}

/**
 * Überprüft ob Repository auf Remote existiert.
 */
export async function repositoryExists(
  options: SshOptions,
  targetPath: string,
): Promise<boolean> {
  try {
    await executeSshCommand(options, `Test-Path "${targetPath}" -PathType Container`);
    return true;
  } catch {
    return false;
  }
}

/**
 * Klont Repository auf Remote-Windows-Rechner.
 */
export async function cloneRepository(
  options: SshOptions,
  repoUrl: string,
  targetPath: string,
): Promise<void> {
  const parentDir = targetPath.split('\\').slice(0, -1).join('\\');
  const repoName = targetPath.split('\\').pop();

  // Zuerst Verzeichnis anlegen
  try {
    await executeSshCommand(
      options,
      `mkdir -Force "${parentDir}" | Out-Null`,
    );
  } catch {
    throw new Error(`Konnte nicht auf ${parentDir} zugreifen. Prüfe Berechtigungen!`);
  }

  // Dann klonen oder aktualisieren
  const cmd = `
if (Test-Path "${targetPath}") {
  cd "${targetPath}"; git pull
} else {
  cd "${parentDir}"; git clone "${repoUrl}" "${repoName}"
}
`;

  try {
    await executeSshCommand(options, cmd);
  } catch (error) {
    throw new Error(`Repository-Klonen fehlgeschlagen: ${error}`);
  }
}

/**
 * Startet Flutter Build auf Remote Windows.
 */
export async function buildFlutterWindows(
  options: SshOptions,
  repoPath: string,
  apiUrl: string,
): Promise<void> {
  const buildCmd = `cd "${repoPath}"; flutter build windows --dart-define=NOVOOA_RUNTIME=standalone --dart-define=WORKSPACE_API_URL=http://${apiUrl}:8090 --release`;

  await executeSshCommand(options, buildCmd);
}

/**
 * Startet Docker Compose auf Remote Windows.
 */
export async function startDockerCompose(
  options: SshOptions,
  repoPath: string,
): Promise<void> {
  const cmd = `cd "${repoPath}"; docker compose -f docker-compose.local.yaml up --build --detach`;

  await executeSshCommand(options, cmd);
}

/**
 * Prüft Docker Compose Status.
 */
export async function checkDockerStatus(options: SshOptions, repoPath: string): Promise<string> {
  const cmd = `cd "${repoPath}"; docker compose -f docker-compose.local.yaml ps`;

  return await executeSshCommand(options, cmd);
}

/**
 * Zeigt Docker Compose Logs.
 */
export async function showDockerLogs(options: SshOptions, repoPath: string): Promise<string> {
  const cmd = `cd "${repoPath}"; docker compose -f docker-compose.local.yaml logs --tail=50`;

  return await executeSshCommand(options, cmd);
}

/**
 * Stoppt Docker Compose.
 */
export async function stopDockerCompose(options: SshOptions, repoPath: string): Promise<void> {
  const cmd = `cd "${repoPath}"; docker compose -f docker-compose.local.yaml down`;

  await executeSshCommand(options, cmd);
}
