FROM primordus/eclair:v0.1.0

WORKDIR /app/bakery
EXPOSE 8080

RUN git clone https://github.com/wingo/walloc /tmp/walloc \
  && cd /tmp/walloc \
  && clang -Oz --target=wasm32 -mbulk-memory -nostdlib -c -o walloc.o walloc.c \
  && cd /app/bakery \
  && cp /tmp/walloc/walloc.o .

COPY package.json package-lock.json ./
RUN source /root/.nvm/nvm.sh && npm install
COPY . .
CMD [ "node", "src/index.js" ]
