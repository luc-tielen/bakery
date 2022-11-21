# bakery

Serving freshly baked [Eclairs](https://github.com/luc-tielen/eclair-lang) over HTTP.

Bakery is a simple webserver in front of the Eclair compiler that makes it
possible to compile a program by submitting the program via an endpoint, and
getting the compiled WASM program back as a result.

The compiled WASM can be used directly in combination with
[eclair-wasm-bindings](https://github.com/luc-tielen/eclair-wasm-bindings).

## Running the server

A Dockerfile is provided. Run the following commands to clone this repo, build
the image and run it:

```bash
$ git clone git@github.com:luc-tielen/bakery.git && cd bakery
$ docker build -f Dockerfile . -t bakery
$ docker run -p 8080:8080 --rm -it bakery
```

## Endpoints

- POST / : expects a JSON body of the form `{"program": "..."}`. Returns a WASM
  file on success, otherwise a HTTP error status code is returned with the error.

## Usage instructions

When you run a bakery instance, you can use the
[eclair-wasm-bindings package](https://www.npmjs.com/package/eclair-wasm-bindings)
to run Eclair code as follows:

```typescript
import {
  withEclair,
  fact,
  program,
  U32,
  INPUT,
  OUTPUT,
} from 'eclair-wasm-bindings';

const eclairCode = `
@def edge(u32, u32).
@def reachable(u32, u32).

reachable(x, y) :-
  edge(x, y).

reachable(x, z) :-
  edge(x, y),
  reachable(y, z).
`;

const BAKERY_URL = 'http://127.0.0.1';
const BAKERY_PORT = 8080;
const compileEclairCode = (program: string) =>
  fetch(`${BAKERY_URL}:${BAKERY_PORT}/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ program }),
  });

const main = async () => {
  const memory = new WebAssembly.Memory({ initial: 10 });
  const { instance: wasmInstance } = await WebAssembly.instantiateStreaming(
    compileEclairCode(eclairCode),
    { env: { memory } }
  );

  withEclair(wasmInstance, memory, (handle) => {
    const edge = fact('edge', INPUT, [U32, U32]);
    const reachable = fact('reachable', OUTPUT, [U32, U32]);
    const path = program(handle, [edge, reachable]);

    path.edge.addFact([1, 2]);
    path.edge.addFacts([
      [2, 3],
      [3, 4],
    ]);

    path.run();

    const reachableFacts = path.reachable.getFacts();
    console.log(reachableFacts);
  });
};

main();
```
