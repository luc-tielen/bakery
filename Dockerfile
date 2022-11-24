FROM primordus/eclair:v0.1.0 as stage1

WORKDIR /app/bakery

RUN git clone https://github.com/wingo/walloc /tmp/walloc \
  && cd /tmp/walloc \
  && clang -Oz --target=wasm32 -mbulk-memory -nostdlib -c -o walloc.o walloc.c \
  && cd /app/bakery \
  && cp /tmp/walloc/walloc.o .

COPY package.json package-lock.json ./
RUN source /root/.nvm/nvm.sh && npm install
COPY . .
CMD [ "node", "src/index.js" ]

FROM ubuntu:20.04 as bakery_app

WORKDIR /app/bakery
ENV DATALOG_DIR=/app/bakery/cbits
EXPOSE 8080

# Copy over minimal libs and bin for Eclair
COPY --from=stage1 /app/build/dist-newstyle/build/x86_64-linux/ghc-9.0.2/eclair-lang-0.0.1/x/eclair/build/eclair/eclair /usr/bin
COPY --from=stage1 /app/build/cbits/ /app/bakery/cbits/
COPY --from=stage1 \
  /lib/x86_64-linux-gnu/libLLVM-14.so.1 \
  /lib/x86_64-linux-gnu/libxml2.so.2 \
  /lib/x86_64-linux-gnu/libedit.so.2 \
	/lib/x86_64-linux-gnu/libbsd.so.0 \
	/lib/x86_64-linux-gnu/libicuuc.so.66 \
  /lib/x86_64-linux-gnu/libicudata.so.66 \
  /usr/lib/
# Same for Souffle
COPY --from=stage1 \
  /usr/bin/mcpp \
  /usr/local/bin/souffle-compile.py \
  /usr/local/bin/souffle \
  /usr/bin/
COPY --from=stage1 \
  /lib/x86_64-linux-gnu/libmcpp.so.0 \
  /lib/x86_64-linux-gnu/libsqlite3.so.0 \
  /lib/x86_64-linux-gnu/libgomp.so.1 \
  /usr/lib/
# Same for clang and wasm-ld
COPY --from=stage1 /usr/bin/clang-14 /usr/bin/wasm-ld-14 /usr/bin/
COPY --from=stage1 /lib/x86_64-linux-gnu/libclang-cpp.so.14 /usr/lib/
# Same for walloc
COPY --from=stage1 /app/bakery/walloc.o .
# Same for node
COPY --from=stage1 \
  /root/.nvm/nvm.sh \
  /root/.nvm/versions/node/v18.1.0/bin/node \
  /usr/bin/

COPY --from=stage1 \
  /app/bakery/node_modules \
  /app/bakery/node_modules/

COPY . .
CMD [ "node", "src/index.js" ]
