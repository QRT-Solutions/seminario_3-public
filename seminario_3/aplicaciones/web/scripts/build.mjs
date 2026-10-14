// Author: QRT Solutions
import { mkdir, copyFile, writeFile } from 'node:fs/promises';
const root = new URL('../', import.meta.url);
const url = process.env.PUBLIC_SUPABASE_URL;
const key = process.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY;
if (!url || !/^https:\/\/[a-z0-9]+\.supabase\.co\/?$/.test(url)) throw new Error('Configure PUBLIC_SUPABASE_URL');
if (!key || !/^sb_publishable_[A-Za-z0-9_-]+$/.test(key)) throw new Error('Use a modern public Supabase publishable key; never a secret');
await mkdir(new URL('dist/vendor/', root), {recursive:true});
for (const name of ['index.html','pepperstone.png','style.css','app.mjs','metrics.mjs','kpis.mjs','performance-charts.mjs','editor.mjs']) await copyFile(new URL(`src/${name}`,root),new URL(`dist/${name}`,root));
await copyFile(new URL('node_modules/chart.js/dist/chart.umd.js',root),new URL('dist/vendor/chart.js',root));
await copyFile(new URL('node_modules/chart.js/LICENSE.md',root),new URL('dist/vendor/CHART-LICENSE.md',root));
await writeFile(new URL('dist/config.json',root), JSON.stringify({author:'QRT Solutions',supabaseUrl:url.replace(/\/$/,''),publishableKey:key}));
await writeFile(new URL('dist/vercel.json',root), JSON.stringify({headers:[{source:'/(.*)',headers:[
  {key:'X-Content-Type-Options',value:'nosniff'},
  {key:'Referrer-Policy',value:'no-referrer'},
  {key:'Content-Security-Policy',value:`default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self' ${url.replace(/\/$/,'')}; img-src 'self' data:; font-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'none'`}
]},{source:'/config.json',headers:[{key:'Cache-Control',value:'no-store'}]}]},null,2));
console.log('Built dist/ with public configuration only.');
// Check emitted references, including assets supplied by npm at build time.
const {readFile,access}=await import('node:fs/promises');
const html=await readFile(new URL('dist/index.html',root),'utf8');
for(const match of html.matchAll(/(?:href|src)="([^"]+)"/g)){
  if(/^(data:|https?:|#)/.test(match[1]))continue;
  await access(new URL(`dist/${match[1]}`,root));
}
