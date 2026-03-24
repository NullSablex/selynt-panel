import http from 'node:http';
const APP_NAME = '{{APP_NAME}}';
const NODE_VER = process.version;

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${APP_NAME}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  background:#f0f2f5;display:flex;align-items:center;justify-content:center;
  min-height:100vh;color:#333}
.card{background:#fff;border-radius:12px;padding:48px 56px;text-align:center;
  box-shadow:0 2px 12px rgba(0,0,0,.08);max-width:480px;width:90%}
.icon{font-size:48px;margin-bottom:16px}
h1{font-size:22px;font-weight:600;margin-bottom:8px}
.ver{font-size:36px;font-weight:700;color:#2d8cf0;margin:16px 0}
.app{font-size:14px;color:#888;margin-bottom:24px}
.info{font-size:13px;color:#aaa;line-height:1.6}
</style>
</head>
<body>
<div class="card">
  <div class="icon">&#9881;</div>
  <h1>Node.js Application</h1>
  <div class="ver">${NODE_VER}</div>
  <div class="app">${APP_NAME}</div>
  <div class="info">
    Your application is running.<br>
    Edit your entry file to deploy your project.
  </div>
</div>
</body>
</html>`;

const server = http.createServer((_req, res) => {
  res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
  res.end(html);
});

server.listen(() => {
  console.log(`${APP_NAME} listening — Node ${NODE_VER}`);
});
