import chalk from 'chalk';

export async function buildRuntimeCommand(): Promise<void> {
  const orange = chalk.hex('#FF8C00');
  console.log('\n' + orange('🏗️  Runtime bauen'));
  console.log(chalk.yellow('⚠️  Diese Funktion kommt später.\n'));
}
