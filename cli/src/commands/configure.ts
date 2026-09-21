import inquirer from 'inquirer';
import chalk from 'chalk';
import * as os from 'os';
import * as config from '../config.js';
import { testConnection } from '../ssh-helper.js';

export async function configureCommand(): Promise<void> {
  const orange = chalk.hex('#FF8C00');
  console.log('\n' + orange('⚙️  Konfiguration'));

  const currentConfig = await config.loadConfig();
  const defaults = currentConfig || config.getDefaultConfig();

  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'windowsHost',
      message: 'Windows-Rechner IP-Adresse:',
      default: defaults.windowsHost,
      validate: (input) => {
        const ipRegex =
          /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
        return ipRegex.test(input) || 'Bitte eine gültige IP-Adresse eingeben (z.B. 192.168.0.134)';
      },
    },
    {
      type: 'input',
      name: 'windowsUsername',
      message: 'Windows-Benutzer (für SSH):',
      default: defaults.windowsUsername,
    },
    {
      type: 'list',
      name: 'sshAuthMethod',
      message: 'SSH-Authentifizierungsmethode:',
      choices: [
        {
          name: '🔑 SSH-Schlüssel (empfohlen, keine Passwort-Abfrage)',
          value: 'key',
        },
        {
          name: '🔐 Passwort (sshpass erforderlich)',
          value: 'password',
        },
      ],
      default: defaults.sshAuthMethod || 'key',
    },
    {
      type: 'input',
      name: 'sshKeyPath',
      message: 'SSH-Schlüssel-Pfad (z.B. ~/.ssh/id_ed25519):',
      default: defaults.sshKeyPath || '~/.ssh/id_ed25519',
      when: (ans) => ans.sshAuthMethod === 'key',
    },
    {
      type: 'input',
      name: 'repoUrl',
      message: 'Repository-URL:',
      default: defaults.repoUrl,
    },
    {
      type: 'input',
      name: 'repoPath',
      message: 'Repository-Pfad auf Windows (z.B. C:\\Development\\syscat2):',
      default: defaults.repoPath,
    },
    {
      type: 'confirm',
      name: 'testConnection',
      message: 'SSH-Verbindung testen?',
      default: true,
    },
  ]);

  const newConfig: config.DeployConfig = {
    windowsHost: answers.windowsHost,
    windowsUsername: answers.windowsUsername,
    repoUrl: answers.repoUrl,
    repoPath: answers.repoPath,
    sshAuthMethod: answers.sshAuthMethod,
    sshKeyPath: answers.sshKeyPath,
  };

  if (answers.testConnection) {
    console.log(chalk.dim('\nVerbindung wird getestet...'));

    // Schlüssel-Pfad expandieren (~/ → Home)
    const keyPath = answers.sshKeyPath?.replace('~', os.homedir());

    const connected = await testConnection({
      host: newConfig.windowsHost,
      username: newConfig.windowsUsername,
      keyFile: answers.sshAuthMethod === 'key' ? keyPath : undefined,
    });

    if (connected) {
      console.log(chalk.green('✓ SSH-Verbindung erfolgreich!'));
      console.log(chalk.dim('  Authentifizierung: ' + (answers.sshAuthMethod === 'key' ? '🔑 SSH-Schlüssel' : '🔐 Passwort')));
    } else {
      console.log(chalk.yellow('⚠ SSH-Verbindung fehlgeschlagen.'));
      console.log(chalk.dim('\nFehlerbehandlung:'));
      if (answers.sshAuthMethod === 'key') {
        console.log(chalk.dim('\n1️⃣  SSH-Schlüssel überprüfen:'));
        console.log(chalk.dim(`  • Schlüssel-Datei existiert? ${keyPath}`));
        console.log(chalk.dim('    ls -la ' + keyPath));

        console.log(chalk.dim('\n2️⃣  Öffentlichen Schlüssel auf Windows hinzufügen:'));
        console.log(chalk.dim('  Mac: cat ~/.ssh/id_ed25519.pub'));
        console.log(chalk.dim('  Windows (PowerShell als Admin):'));
        console.log(chalk.dim('    mkdir $env:USERPROFILE\\.ssh -Force'));
        console.log(chalk.dim('    Add-Content -Path $env:USERPROFILE\\.ssh\\authorized_keys -Value "<paste key here>"'));
        console.log(chalk.dim('    icacls $env:USERPROFILE\\.ssh\\authorized_keys /inheritance:r /grant:r "$env:USERNAME`:(F)"'));

        console.log(chalk.dim('\n3️⃣  SSH-Test direkt vom Mac:'));
        console.log(chalk.dim(`  ssh -i ${keyPath} ${answers.windowsUsername}@${answers.windowsHost} "Write-Host 'OK'"`));
      } else {
        console.log(chalk.dim('  • sshpass installiert? brew install sshpass'));
        console.log(chalk.dim('  • Passwort korrekt?'));
      }
      console.log(chalk.dim('\n  • IP-Adresse korrekt: ' + answers.windowsHost));
      console.log(chalk.dim('  • Benutzer korrekt: ' + answers.windowsUsername));
      console.log(chalk.dim('  • OpenSSH auf Windows aktiviert?'));
      console.log(chalk.dim('    Get-Service sshd (sollte Running sein)\n'));
    }
  }

  await config.saveConfig(newConfig);
  console.log(chalk.green('\n✓ Konfiguration gespeichert!\n'));
}
