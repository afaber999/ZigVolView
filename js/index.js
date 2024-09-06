
const env = {
    ...wasm,
    // ...audio,
    // ...canvas,
    // ...zigdom,
    ...webgl,
    // setScore
}

const readCharStr = (ptr, len) => {
    const array = new Uint8Array(memory.buffer, ptr, len)
    const decoder = new TextDecoder()
    return decoder.decode(array)
}



function load_logodata_async(instance, url) {
    return new Promise( async (response, reject) =>  {
        try {
            const fetch_response = await fetch(url);

            const data_reader = fetch_response.body.getReader({
                mode: "byob",
              });

            const buffer_size = instance.exports.pushDataSize();  
            let array_buf = new ArrayBuffer(buffer_size);
            let total_bytes = 0;
            while (true) {
                const { value, done } = await data_reader.read(new Uint8Array(array_buf));
                if (done) break;
            
                array_buf = value.buffer;
                const chunk_buf = new Uint8Array(
                  instance.exports.memory.buffer,
                  instance.exports.global_chunk.value,
                  buffer_size,
                );
                chunk_buf.set(value);
                instance.exports.pushData(value.length);
                total_bytes += value.length;
            }

            {
                const f1 = await fetch("wasm_logo.png");
                const b1 = await f1.arrayBuffer();
                const i1 = new Uint8Array(b1);
                console.log(" JS SIDE: ", i1[3] )


                // allocate WASM memory
                const img_size = i1.length;
                const img_ptr = instance.exports.malloc(img_size);
                console.log("MEM_ALLOC MEM PTR: ", img_ptr.toString(16));
                
                // copy to WASM memory
                const img_buf = new Uint8Array(instance.exports.memory.buffer,img_ptr,img_size);
                img_buf.set(i1);
                
                instance.exports.pushImage(img_ptr, img_size);
                instance.exports.free(img_ptr);
            }
            response(total_bytes);
        } catch (err ) {
            reject(err);
        }
    });
}


async function runner(instance) {

    memory = instance.exports.memory;
    console.log("index.js: Entry runner");
    
    //const logo_url = "./ziglogo.bin";
    const logo_url = "./letterf.bin";
    const _logo_data_size = await load_logodata_async(instance, logo_url);
    //console.log( "GOT LOGODATA SIZE: ", logo_data_size);
    //instance.exports.copy_from_js(logo_data.buffer  );

    instance.exports.onInit();

    function resize() {
        $canvasgl.width = window.devicePixelRatio * window.innerWidth;
        $canvasgl.height = window.devicePixelRatio * window.innerHeight;
        $canvasgl.style.width = window.innerWidth + "px";
        $canvasgl.style.height = window.innerHeight + "px";
        instance.exports.onResize(window.innerWidth, window.innerHeight, window.devicePixelRatio);
        }
    window.addEventListener('resize', resize, false);
    resize();

    const onAnimationFrame = instance.exports.onAnimationFrame;

    document.addEventListener('keydown', e => instance.exports.onKeyDown(e.keyCode));
    // document.addEventListener('keyup', e => instance.exports.onKeyUp(e.keyCode, 0));
    // document.addEventListener('mousedown', e => instance.exports.onMouseDown(e.button, e.x, e.y));
    // document.addEventListener('mouseup', e => instance.exports.onMouseUp(e.button, e.x, e.y));
    // document.addEventListener('mousemove', e => instance.exports.onMouseMove(e.x, e.y));

    function step(timestamp) {
        onAnimationFrame(timestamp);
        window.requestAnimationFrame(step);
    }

    window.requestAnimationFrame(step);
    console.log("requested animation frame");
}


fetchAndInstantiate('zig-out/bin/main.wasm', { env }).then(runner);

function fetchAndInstantiate(url, importObject) {
    return fetch(url)
        .then(response => response.arrayBuffer())
        .then(bytes => WebAssembly.instantiate(bytes, importObject))
        .then(results => results.instance);
}
