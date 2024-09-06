const logWasm = (s, len ) => {  
  const buf = new Uint8Array(this.memory.buffer, s, len);
  console.log(new TextDecoder("utf8").decode(buf));
}

var wasm = {
  logWasm,
};