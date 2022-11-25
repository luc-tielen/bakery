import { promisify } from 'util';
import fs from 'fs/promises';
import { file, withFile } from 'tmp-promise';
import process from 'process';
import childProcess from 'child_process';
import express from 'express';
import bodyParser from 'body-parser';

const execFile = promisify(childProcess.execFile);

process.on('SIGINT', () => {
  console.info('Shutting down server..');
  process.exit(0);
});
process.on('SIGTERM', () => {
  console.info('Shutting down server..');
  process.exit(0);
});

const wallocObjFile = './walloc.o';

const compileEclairProgram = async (program) =>
  withFile(async ({ path: inputFile }) => {
    const { path: outputFile, cleanup } = await file();
    await fs.writeFile(inputFile, program);
    const { stderr } = await execFile('./compile_eclair.sh', [
      inputFile,
      wallocObjFile,
      outputFile,
    ]);

    if (stderr) {
      return { errorMessage: stderr };
    }

    return { wasmFile: outputFile, cleanup };
  });

const logger = (req, res, next) => {
  res.on('finish', () => {
    console.log(res.statusCode, JSON.stringify(req.body || {}));
  });
  next();
};

const showWelcomePage = (_req, res) => {
  res.send(`
  <h1>Welcome to <em>Bakery</em>!</h1>

  <p>
    Bakery is a webserver that can compile <a href="https://github.com/luc-tielen/eclair-lang">Eclair</a> programs on the fly.
  </p>
  <p>
    For more information on how to use Bakery and Eclair, click <a href="https://github.com/luc-tielen/bakery">here</a>.
  </p>
  `);
};

const main = () => {
  const app = express();
  express.static.mime.types['wasm'] = 'application/wasm';

  app.use(bodyParser.json());
  app.use(logger);

  app.get('/', showWelcomePage);

  app.post('/', async (req, res) => {
    const program = req.body?.program;
    if (!program || typeof program !== 'string') {
      res.status(400).send('Bad request');
      return;
    }

    const { errorMessage, wasmFile, cleanup } = await compileEclairProgram(
      program
    );
    if (errorMessage) {
      res.status(400).send(errorMessage);
      return;
    }

    res.writeHead(200, { 'Content-Type': 'application/wasm' });
    res.write(await fs.readFile(wasmFile));
    res.end();
    await cleanup();
  });

  app.listen(8080, '::');
};

main();
