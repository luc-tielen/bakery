import { promisify } from 'util';
import fs from 'fs/promises';
import { file, withFile } from 'tmp-promise';
import process from 'child_process';
import express from 'express';
import bodyParser from 'body-parser';

const execFile = promisify(process.execFile);

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

const main = () => {
  const app = express();
  express.static.mime.types['wasm'] = 'application/wasm';

  app.use(bodyParser.json());
  app.use(logger);

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
      res.status(404).send(errorMessage);
      return;
    }

    res.download(wasmFile);
    await cleanup();
  });

  app.listen(8080);
};

main();
