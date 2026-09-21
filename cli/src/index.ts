#!/usr/bin/env node

import inquirer from 'inquirer';
import chalk from 'chalk';
import { configureCommand } from './commands/configure.js';
import { buildFlutterCommand } from './commands/build-flutter.js';
import { deployRuntimeCommand } from './commands/deploy-runtime.js';
import { buildRuntimeCommand } from './commands/build-runtime.js';

const VERSION = '1.0.0';

async function main(): Promise<void> {
  console.log(chalk.cyan('\n╔════════════════════════════════════════╗'));
  console.log(chalk.cyan('║     novooa Deployment CLI v' + VERSION.padEnd(20) + '║'));
  console.log(chalk.cyan('╚════════════════════════════════════════╝\n'));

  const { command } = await inquirer.prompt([
    {
      type: 'list',
      name: 'command',
      message: 'Was möchtest du tun?',
      choices: [
        new inquirer.Separator('  🔧 Konfiguration'),
        { name: 'Konfigurieren (IP, SSH, Pfade)', value: 'configure' },

        new inquirer.Separator('  🚀 Deployment'),
        { name: 'Flutter Client auf Windows bauen', value: 'build-flutter' },
        { name: 'Lokale Runtime deployen', value: 'deploy-runtime' },
        { name: 'Runtime bauen', value: 'build-runtime' },

        new inquirer.Separator('  ⚙️  Sonstiges'),
        { name: 'Beenden', value: 'exit' },
      ],
      loop: false,
    },
  ]);

  switch (command) {
    case 'configure':
      await configureCommand();
      break;
    case 'build-flutter':
      await buildFlutterCommand();
      break;
    case 'deploy-runtime':
      await deployRuntimeCommand();
      break;
    case 'build-runtime':
      await buildRuntimeCommand();
      break;
    case 'exit':
      console.log(chalk.dim('Auf Wiedersehen!\n'));
      return;
  }

  // Menü erneut anzeigen
  const { again } = await inquirer.prompt([
    {
      type: 'confirm',
      name: 'again',
      message: 'Weitere Aktion durchführen?',
      default: false,
    },
  ]);

  if (again) {
    console.clear();
    await main();
  } else {
    console.log(chalk.dim('Auf Wiedersehen!\n'));
  }
}

main().catch((error) => {
  console.error(chalk.red('\nFehler:'), error);
  process.exit(1);
});
