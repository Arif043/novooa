import inquirer from 'inquirer';
import chalk from 'chalk';
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
    const keyPath = answers.sshKeyPath?.replace('~', require('os').homedir());

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
      console.log(chalk.dim('Stelle sicher, dass:'));
      if (answers.sshAuthMethod === 'key') {
        console.log(chalk.dim('  • Der SSH-Schlüssel existiert: ' + keyPath));
        console.log(chalk.dim('  • Der öffentliche Schlüssel auf Windows hinterlegt ist'));
      } else {
        console.log(chalk.dim('  • sshpass installiert ist (brew install sshpass)'));
        console.log(chalk.dim('  • Das Passwort korrekt ist'));
      }
      console.log(chalk.dim('  • Die IP-Adresse korrekt ist'));
      console.log(chalk.dim('  • OpenSSH auf Windows aktiviert ist'));
    }
  }

  await config.saveConfig(newConfig);
  console.log(chalk.green('\n✓ Konfiguration gespeichert!\n'));
}
