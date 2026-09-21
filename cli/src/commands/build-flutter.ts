import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import * as os from 'os';
import * as config from '../config.js';
import * as ssh from '../ssh-helper.js';

export async function buildFlutterCommand(): Promise<void> {
  const orange = chalk.hex('#FF8C00');
  console.log('\n' + orange('🚀 Flutter Windows Client bauen'));

  const cfg = await config.loadConfig();
  if (!cfg) {
    console.log(chalk.red('✗ Konfiguration nicht gefunden. Bitte zunächst `configure` ausführen.\n'));
    return;
  }

  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'apiUrl',
      message: 'API-Endpoint IP (wird zu http://<ip>:8090):',
      default: cfg.windowsHost,
      validate: (input) => {
        const ipRegex =
          /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
        return ipRegex.test(input) || 'Bitte eine gültige IP-Adresse eingeben';
      },
    },
    {
      type: 'confirm',
      name: 'cloneFirst',
      message: 'Repository vor dem Build klonen/aktualisieren?',
      default: true,
    },
  ]);

  // Schlüssel-Pfad expandieren
  const keyPath = cfg.sshKeyPath?.replace('~', os.homedir());

  const sshOpts = {
    host: cfg.windowsHost,
    username: cfg.windowsUsername,
    keyFile: cfg.sshAuthMethod === 'key' ? keyPath : undefined,
  };

  try {
    // Step 1: Test connection
    let spinner = ora('SSH-Verbindung wird getestet...').start();
    const connected = await ssh.testConnection(sshOpts);
    if (!connected) {
      spinner.fail('SSH-Verbindung fehlgeschlagen');
      console.log(chalk.dim('Tipps:'));
      console.log(chalk.dim('  • OpenSSH muss auf Windows 10/11 aktiviert sein'));
      console.log(chalk.dim('  • Oder: SSH-Schlüssel im ~/.ssh konfigurieren'));
      return;
    }
    spinner.succeed('SSH-Verbindung erfolgreich');

    // Step 2: Clone or update repository
    spinner = ora('Überprüfe Repository...').start();
    const repoExists = await ssh.repositoryExists(sshOpts, cfg.repoPath);

    if (!repoExists) {
      spinner.text = 'Repository nicht gefunden. Klone es jetzt...';
      try {
        await ssh.cloneRepository(sshOpts, cfg.repoUrl, cfg.repoPath);
        spinner.succeed('Repository geklont');
      } catch (error) {
        spinner.fail(`Repository-Klonen fehlgeschlagen: ${error}`);
        console.log(chalk.dim('\nMögliche Ursachen:'));
        console.log(chalk.dim('  • Git nicht auf Windows installiert?'));
        console.log(chalk.dim('  • Repository-URL falsch?'));
        console.log(chalk.dim('  • Berechtigungen?\n'));
        return;
      }
    } else if (answers.cloneFirst) {
      spinner.text = 'Repository wird aktualisiert...';
      try {
        await ssh.cloneRepository(sshOpts, cfg.repoUrl, cfg.repoPath);
        spinner.succeed('Repository aktualisiert');
      } catch (error) {
        spinner.fail(`Repository-Update fehlgeschlagen: ${error}`);
        console.log(chalk.dim('Versuche trotzdem den Build...\n'));
      }
    } else {
      spinner.succeed('Repository existiert');
    }

    // Step 3: Build Flutter
    spinner = ora('Flutter wird gebaut (dies kann 5-10 Minuten dauern)...').start();
    await ssh.buildFlutterWindows(sshOpts, cfg.repoPath, answers.apiUrl);
    spinner.succeed('Flutter Build erfolgreich abgeschlossen!');

    console.log(chalk.green('\n✓ Build erfolgreich!\n'));
    console.log(chalk.dim('Pfad zur .exe:'));
    console.log(chalk.cyan(`${cfg.repoPath}\\build\\windows\\runner\\Release\\syscat2.exe\n`));
  } catch (error) {
    console.log(chalk.red(`\n✗ Fehler beim Build: ${error}\n`));
  }
}
