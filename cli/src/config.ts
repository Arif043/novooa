import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';

export interface DeployConfig {
  windowsHost: string;
  windowsUsername: string;
  repoUrl: string;
  repoPath: string;
  sshAuthMethod?: 'key' | 'password'; // 'key' = SSH-Schlüssel, 'password' = Passwort
  sshKeyPath?: string; // Z.B. ~/.ssh/id_ed25519
}

const CONFIG_DIR = path.join(os.homedir(), '.novooa-cli');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');

export async function ensureConfigDir(): Promise<void> {
  try {
    await fs.mkdir(CONFIG_DIR, { recursive: true });
  } catch {
    // Directory exists or creation failed
  }
}

export async function loadConfig(): Promise<DeployConfig | null> {
  try {
    const data = await fs.readFile(CONFIG_FILE, 'utf-8');
    return JSON.parse(data) as DeployConfig;
  } catch {
    return null;
  }
}

export async function saveConfig(config: DeployConfig): Promise<void> {
  await ensureConfigDir();
  await fs.writeFile(CONFIG_FILE, JSON.stringify(config, null, 2), 'utf-8');
}

export function getDefaultConfig(): DeployConfig {
  return {
    windowsHost: '192.168.0.134',
    windowsUsername: 'Administrator',
    repoUrl: 'https://github.com/arif-ertugrul/syscat2.git',
    repoPath: 'C:\\Development\\syscat2',
  };
}
