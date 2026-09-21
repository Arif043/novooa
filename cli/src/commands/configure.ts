import inquirer from 'inquirer';
import chalk from 'chalk';
import * as config from '../config.js';
import { testConnection } from '../ssh-helper.js';

export async function configureCommand(): Promise<void> {
  console.log('\n' + chalk.blue('⚙️  Konfiguration'));

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
  };

  if (answers.testConnection) {
    console.log(chalk.dim('\nVerbindung wird getestet...'));
    const connected = await testConnection({
      host: newConfig.windowsHost,
      username: newConfig.windowsUsername,
    });

    if (connected) {
      console.log(chalk.green('✓ SSH-Verbindung erfolgreich!'));
    } else {
      console.log(chalk.yellow('⚠ SSH-Verbindung fehlgeschlagen.'));
      console.log(chalk.dim('Stelle sicher, dass:'));
      console.log(chalk.dim('  • SSH auf dem Windows-Rechner aktiviert ist'));
      console.log(chalk.dim('  • Die IP-Adresse korrekt ist'));
      console.log(chalk.dim('  • Der Benutzer korrekt ist'));
    }
  }

  await config.saveConfig(newConfig);
  console.log(chalk.green('\n✓ Konfiguration gespeichert!\n'));
}
