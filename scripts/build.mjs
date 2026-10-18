import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const sourcePath = resolve(root, 'siga-para.html');
const outputDirectory = resolve(root, 'dist');
const outputPath = resolve(outputDirectory, 'index.html');

const html = await readFile(sourcePath, 'utf8');
if (!html.includes('<!DOCTYPE html>') || !html.includes('</html>')) {
  throw new Error('siga-para.html não contém um documento HTML completo.');
}

await mkdir(outputDirectory, { recursive: true });
await writeFile(outputPath, html, 'utf8');
console.log(`Build estático gerado em ${outputPath}`);
