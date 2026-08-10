import * as esbuild from 'esbuild'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import fs from 'node:fs'

const here = path.dirname(fileURLToPath(import.meta.url))
const outDir = path.resolve(here, '../Sources/TackitApp/Resources/editor')
fs.mkdirSync(outDir, { recursive: true })
fs.copyFileSync(path.join(here, 'src/index.html'), path.join(outDir, 'index.html'))

const options = {
  entryPoints: [path.join(here, 'src/editor.ts')],
  bundle: true,
  format: 'iife',
  outfile: path.join(outDir, 'bundle.js'),
  target: ['safari16'],
  minify: true,
  sourcemap: false,
}

if (process.argv.includes('--watch')) {
  const ctx = await esbuild.context(options)
  await ctx.watch()
  console.log('watching editor sources...')
} else {
  await esbuild.build(options)
  console.log('built editor bundle ->', outDir)
}
