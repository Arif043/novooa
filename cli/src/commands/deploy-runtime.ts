import inquirer from 'inquirer';
import chalk from 'chalk';
import ora from 'ora';
import * as os from 'os';
import * as config from '../config.js';
import * as ssh from '../ssh-helper.js';

export async function deployRuntimeCommand(): Promise<void> {
  const orange = chalk.hex('#FF8C00');
  console.log('\n' + orange('🐳 Lokale Runtime deployen'));

  const cfg = await config.loadConfig();
  if (!cfg) {
    console.log(chalk.red('✗ Konfiguration nicht gefunden. Bitte zunächst `configure` ausführen.\n'));
    return;
  }

  const answers = await inquirer.prompt([
    {
      type: 'list',
      name: 'action',
      message: 'Was möchtest du mit der Runtime tun?',
      choices: [
        { name: 'Starten (docker compose up)', value: 'start' },
        { name: 'Stoppen (docker compose down)', value: 'stop' },
        { name: 'Status prüfen', value: 'status' },
        { name: 'Logs anzeigen', value: 'logs' },
      ],
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
    // Test connection
    let spinner = ora('SSH-Verbindung wird getestet...').start();
    const connected = await ssh.testConnection(sshOpts);
    if (!connected) {
      spinner.fail('SSH-Verbindung fehlgeschlagen');
      return;
    }
    spinner.succeed('SSH-Verbindung erfolgreich');

    switch (answers.action) {
      case 'start': {
        // Stelle sicher dass Repository existiert (klone falls nötig)
        spinner = ora('Repository wird überprüft/geklont...').start();
        try {
          const repoExists = await ssh.repositoryExists(sshOpts, cfg.repoPath);
          if (!repoExists) {
            spinner.text = 'Klone Repository...';
            await ssh.cloneRepository(sshOpts, cfg.repoUrl, cfg.repoPath);
          }
          spinner.succeed('Repository ready');
        } catch (error) {
          spinner.fail(`Repository-Setup fehlgeschlagen: ${error}`);
          return;
        }

        // Docker Compose starten
        spinner = ora('Starte Docker Compose...').start();
        try {
          await ssh.startDockerCompose(sshOpts, cfg.repoPath);
          spinner.succeed('Runtime gestartet!');
        } catch (error) {
          spinner.fail(`Docker Compose fehlgeschlagen: ${error}`);
          return;
        }

        console.log(chalk.green('\n✓ Runtime läuft auf http://' + cfg.windowsHost + ':8090\n'));
        console.log(chalk.dim('Nächste Schritte:'));
        console.log(chalk.dim(`  1. Flutter Client mit --dart-define=WORKSPACE_API_URL=http://${cfg.windowsHost}:8090 bauen`));
        console.log(chalk.dim(`  2. Im Client http://${cfg.windowsHost}:8090 als Runtime-Endpoint eingeben\n`));
        break;
      }

      case 'stop': {
        const confirm = await inquirer.prompt([
          {
            type: 'confirm',
            name: 'sure',
            message: 'Runtime wirklich stoppen?',
            default: false,
          },
        ]);

        if (confirm.sure) {
          const spinner = ora('Runtime wird gestoppt...').start();
          await ssh.stopDockerCompose(sshOpts, cfg.repoPath);
          spinner.succeed('Runtime gestoppt');
        }
        break;
      }

      case 'status': {
        const spinner = ora('Status wird abgerufen...').start();
        spinner.stop();
        const status = await ssh.checkDockerStatus(sshOpts, cfg.repoPath);
        console.log(chalk.dim('\nDocker Status:\n'));
        console.log(status);
        console.log();
        break;
      }

      case 'logs': {
        const spinner = ora('Logs werden abgerufen...').start();
        spinner.stop();
        const logs = await ssh.showDockerLogs(sshOpts, cfg.repoPath);
        console.log(chalk.dim('\nDocker Logs (letzte 50 Zeilen):\n'));
        console.log(logs);
        console.log();
        break;
      }
    }
  } catch (error) {
    console.log(chalk.red(`\n✗ Fehler: ${error}\n`));
  }
}
