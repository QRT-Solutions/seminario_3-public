// Author: QRT Solutions. Local static preview; only the allowlisted build files.
import http from 'node:http';
import {readFile} from 'node:fs/promises';
const port=Number(process.env.PORT||4173);
const types={'.png':'image/png','.html':'text/html; charset=utf-8','.css':'text/css','.mjs':'text/javascript','.js':'text/javascript','.json':'application/json'};
const files=new Set(['index.html','pepperstone.png','style.css','app.mjs','metrics.mjs','kpis.mjs','performance-charts.mjs','editor.mjs','config.json','vendor/chart.js']);
http.createServer(async(req,res)=>{
  const path=new URL(req.url,'http://localhost').pathname.slice(1)||'index.html';
  if(!files.has(path)){res.writeHead(404).end();return;}
  try{const data=await readFile(new URL(`../dist/${path}`,import.meta.url));res.writeHead(200,{'Content-Type':types[path.slice(path.lastIndexOf('.'))]||'text/plain','Cache-Control':'no-store'}).end(data);}
  catch{res.writeHead(404).end();}
}).listen(port,'127.0.0.1',()=>console.log(`Preview http://127.0.0.1:${port}`));
