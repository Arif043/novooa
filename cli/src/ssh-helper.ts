import { execSync } from 'child_process';
import chalk from 'chalk';

export interface SshOptions {
  host: string;
  username: string;
  password?: string;
}

/**
 * Führt einen PowerShell-Befehl auf dem Remote-Windows-Rechner aus.
 * Nutzt OpenSSH (muss auf Windows installiert sein).
 */
export async function executeSshCommand(
  options: SshOptions,
  command: string,
): Promise<string> {
  const sshCommand = buildSshCommand(options, command);

  try {
    const output = execSync(sshCommand, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
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
 * Baut den SSH-Befehl zusammen. Nutzt SSH_PASSWORD env var falls vorhanden.
 */
function buildSshCommand(options: SshOptions, command: string): string {
  const host = `${options.username}@${options.host}`;

  // PowerShell-Befehl escapen für SSH
  const escapedCmd = command.replace(/"/g, '\\"');

  // SSH mit forciertem Passwordauth und stdout redirection
  return `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${host} "powershell -NoProfile -Command \\"${escapedCmd}\\""`;
}

/**
 * Prüft ob Host erreichbar ist via SSH.
 */
export async function testConnection(options: SshOptions): Promise<boolean> {
  try {
    await executeSshCommand(options, 'Write-Host "OK"');
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
  const mkdirCmd = `mkdir -Force ${targetPath.split('\\').slice(0, -1).join('\\')} | Out-Null`;
  const gitCloneCmd = `cd ${targetPath.split('\\').slice(0, -1).join('\\')} && git clone ${repoUrl} ${targetPath.split('\\').pop()}`;

  // Zuerst Verzeichnis anlegen
  try {
    await executeSshCommand(options, mkdirCmd);
  } catch {
    // Ignorieren falls Verzeichnis existiert
  }

  // Dann klonen (oder aktualisieren falls vorhanden)
  await executeSshCommand(
    options,
    `if (Test-Path ${targetPath}) { cd ${targetPath}; git pull } else { ${gitCloneCmd} }`,
  );
}

/**
 * Startet Flutter Build auf Remote Windows.
 */
export async function buildFlutterWindows(
  options: SshOptions,
  repoPath: string,
  apiUrl: string,
): Promise<void> {
  const buildCmd = `cd ${repoPath} && flutter build windows --dart-define=NOVOOA_RUNTIME=standalone --dart-define=WORKSPACE_API_URL=http://${apiUrl}:8090 --release`;

  await executeSshCommand(options, buildCmd);
}

/**
 * Startet Docker Compose auf Remote Windows.
 */
export async function startDockerCompose(
  options: SshOptions,
  repoPath: string,
): Promise<void> {
  const cmd = `cd ${repoPath} && docker compose -f docker-compose.local.yaml up --build --detach`;

  await executeSshCommand(options, cmd);
}

/**
 * Prüft Docker Compose Status.
 */
export async function checkDockerStatus(options: SshOptions, repoPath: string): Promise<string> {
  const cmd = `cd ${repoPath} && docker compose -f docker-compose.local.yaml ps`;

  return await executeSshCommand(options, cmd);
}

/**
 * Zeigt Docker Compose Logs.
 */
export async function showDockerLogs(options: SshOptions, repoPath: string): Promise<string> {
  const cmd = `cd ${repoPath} && docker compose -f docker-compose.local.yaml logs --tail=50`;

  return await executeSshCommand(options, cmd);
}

/**
 * Stoppt Docker Compose.
 */
export async function stopDockerCompose(options: SshOptions, repoPath: string): Promise<void> {
  const cmd = `cd ${repoPath} && docker compose -f docker-compose.local.yaml down`;

  await executeSshCommand(options, cmd);
}
