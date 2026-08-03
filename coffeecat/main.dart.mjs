// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `load-ids` option is passed. Each load ID maps to one
  //   or more wasm files as specified in the emitted JSON file. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It also takes a callback that should be invoked with the
  //   loaded module in a format supported by `WebAssembly.compile` or
  //   `WebAssembly.compileStreaming` and the result of using the JS 'import'
  //   API on the js file path. It should return a Promise that resolves when
  //   all the modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports,
      {loadDeferredModules, loadDynamicModule, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _1: (decoder, codeUnits) => decoder.decode(codeUnits),
      _2: () => new TextDecoder("utf-8", {fatal: true}),
      _3: () => new TextDecoder("utf-8", {fatal: false}),
      _4: (s) => +s,
      _5: x0 => new Uint8Array(x0),
      _6: (x0,x1,x2) => x0.set(x1,x2),
      _7: (x0,x1) => x0.transferFromImageBitmap(x1),
      _9: (x0,x1,x2) => x0.slice(x1,x2),
      _10: (x0,x1) => x0.decode(x1),
      _11: (x0,x1) => x0.segment(x1),
      _12: () => new TextDecoder(),
      _14: x0 => x0.buffer,
      _15: x0 => x0.wasmMemory,
      _16: () => globalThis.window._flutter_skwasmInstance,
      _17: x0 => x0.rasterStartMilliseconds,
      _18: x0 => x0.rasterEndMilliseconds,
      _19: x0 => x0.imageBitmaps,
      _135: (x0,x1) => x0.appendChild(x1),
      _166: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _167: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _168: (x0,x1) => new OffscreenCanvas(x0,x1),
      _169: x0 => x0.remove(),
      _170: (x0,x1) => x0.append(x1),
      _172: x0 => x0.unlock(),
      _173: x0 => x0.getReader(),
      _174: (x0,x1) => x0.item(x1),
      _175: x0 => x0.next(),
      _176: x0 => x0.now(),
      _177: (x0,x1) => x0.revokeObjectURL(x1),
      _178: x0 => x0.close(),
      _179: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _180: x0 => new window.ImageDecoder(x0),
      _181: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      _182: (x0,x1) => x0.decode(x1),
      _183: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._183(f,arguments.length,x0) }),
      _184: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _186: (x0,x1) => x0.getModifierState(x1),
      _187: x0 => x0.preventDefault(),
      _188: x0 => x0.stopPropagation(),
      _189: (x0,x1) => x0.removeProperty(x1),
      _190: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._190(f,arguments.length,x0) }),
      _191: x0 => new window.FinalizationRegistry(x0),
      _192: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _194: (x0,x1) => x0.unregister(x1),
      _195: (x0,x1) => x0.prepend(x1),
      _196: x0 => new Intl.Locale(x0),
      _197: (x0,x1) => x0.observe(x1),
      _198: x0 => x0.disconnect(),
      _199: (x0,x1) => x0.getAttribute(x1),
      _200: (x0,x1) => x0.contains(x1),
      _201: (x0,x1) => x0.querySelector(x1),
      _202: (x0,x1) => x0.matchMedia(x1),
      _203: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._203(f,arguments.length,x0) }),
      _204: (x0,x1,x2) => x0.call(x1,x2),
      _205: x0 => x0.blur(),
      _206: x0 => x0.hasFocus(),
      _207: (x0,x1) => x0.removeAttribute(x1),
      _208: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _209: (x0,x1) => x0.hasAttribute(x1),
      _210: (x0,x1) => x0.getModifierState(x1),
      _211: (x0,x1) => x0.createTextNode(x1),
      _212: x0 => x0.getBoundingClientRect(),
      _213: (x0,x1) => x0.replaceWith(x1),
      _214: (x0,x1) => x0.contains(x1),
      _215: (x0,x1) => x0.closest(x1),
      _653: x0 => new Uint8Array(x0),
      _656: () => globalThis.window.flutterConfiguration,
      _658: x0 => x0.assetBase,
      _663: x0 => x0.canvasKitMaximumSurfaces,
      _664: x0 => x0.debugShowSemanticsNodes,
      _665: x0 => x0.hostElement,
      _666: x0 => x0.multiViewEnabled,
      _667: x0 => x0.nonce,
      _669: x0 => x0.fontFallbackBaseUrl,
      _679: x0 => x0.console,
      _680: x0 => x0.devicePixelRatio,
      _681: x0 => x0.document,
      _682: x0 => x0.history,
      _683: x0 => x0.innerHeight,
      _684: x0 => x0.innerWidth,
      _685: x0 => x0.location,
      _686: x0 => x0.navigator,
      _687: x0 => x0.visualViewport,
      _688: x0 => x0.performance,
      _689: x0 => x0.parent,
      _691: x0 => x0.URL,
      _693: (x0,x1) => x0.getComputedStyle(x1),
      _694: x0 => x0.screen,
      _695: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._695(f,arguments.length,x0) }),
      _696: (x0,x1) => x0.requestAnimationFrame(x1),
      _700: (x0,x1) => x0.warn(x1),
      _702: (x0,x1) => x0.debug(x1),
      _703: x0 => globalThis.parseFloat(x0),
      _704: () => globalThis.window,
      _705: () => globalThis.Intl,
      _706: () => globalThis.Symbol,
      _707: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _709: x0 => x0.clipboard,
      _710: x0 => x0.maxTouchPoints,
      _711: x0 => x0.vendor,
      _712: x0 => x0.language,
      _713: x0 => x0.platform,
      _714: x0 => x0.userAgent,
      _715: (x0,x1) => x0.vibrate(x1),
      _716: x0 => x0.languages,
      _717: x0 => x0.documentElement,
      _718: (x0,x1) => x0.querySelector(x1),
      _719: (x0,x1) => x0.querySelectorAll(x1),
      _721: (x0,x1) => x0.createElement(x1),
      _724: (x0,x1) => x0.createEvent(x1),
      _725: x0 => x0.activeElement,
      _728: x0 => x0.head,
      _729: x0 => x0.body,
      _731: (x0,x1) => { x0.title = x1 },
      _734: x0 => x0.visibilityState,
      _735: () => globalThis.document,
      _736: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._736(f,arguments.length,x0) }),
      _737: (x0,x1) => x0.dispatchEvent(x1),
      _745: x0 => x0.target,
      _747: x0 => x0.timeStamp,
      _748: x0 => x0.type,
      _750: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _757: x0 => x0.firstChild,
      _761: x0 => x0.parentElement,
      _763: (x0,x1) => { x0.textContent = x1 },
      _764: x0 => x0.parentNode,
      _765: x0 => x0.nextSibling,
      _766: (x0,x1) => x0.removeChild(x1),
      _767: x0 => x0.isConnected,
      _775: x0 => x0.clientHeight,
      _776: x0 => x0.clientWidth,
      _777: x0 => x0.offsetHeight,
      _778: x0 => x0.offsetWidth,
      _779: x0 => x0.id,
      _780: (x0,x1) => { x0.id = x1 },
      _783: (x0,x1) => { x0.spellcheck = x1 },
      _784: x0 => x0.tagName,
      _785: x0 => x0.style,
      _787: (x0,x1) => x0.querySelectorAll(x1),
      _788: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _789: x0 => x0.tabIndex,
      _790: (x0,x1) => { x0.tabIndex = x1 },
      _791: (x0,x1) => x0.focus(x1),
      _792: x0 => x0.scrollTop,
      _793: (x0,x1) => { x0.scrollTop = x1 },
      _794: (x0,x1) => { x0.scrollLeft = x1 },
      _795: x0 => x0.scrollLeft,
      _796: x0 => x0.classList,
      _797: (x0,x1) => x0.scrollIntoView(x1),
      _800: (x0,x1) => { x0.className = x1 },
      _802: (x0,x1) => x0.getElementsByClassName(x1),
      _803: x0 => x0.click(),
      _804: (x0,x1) => x0.attachShadow(x1),
      _807: x0 => x0.computedStyleMap(),
      _808: (x0,x1) => x0.get(x1),
      _814: (x0,x1) => x0.getPropertyValue(x1),
      _815: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _816: x0 => x0.offsetLeft,
      _817: x0 => x0.offsetTop,
      _818: x0 => x0.offsetParent,
      _820: (x0,x1) => { x0.name = x1 },
      _821: x0 => x0.content,
      _822: (x0,x1) => { x0.content = x1 },
      _826: (x0,x1) => { x0.src = x1 },
      _827: x0 => x0.naturalWidth,
      _828: x0 => x0.naturalHeight,
      _832: (x0,x1) => { x0.crossOrigin = x1 },
      _834: (x0,x1) => { x0.decoding = x1 },
      _835: x0 => x0.decode(),
      _840: (x0,x1) => { x0.nonce = x1 },
      _845: (x0,x1) => { x0.width = x1 },
      _847: (x0,x1) => { x0.height = x1 },
      _850: (x0,x1) => x0.getContext(x1),
      _918: x0 => x0.width,
      _919: x0 => x0.height,
      _921: (x0,x1) => x0.fetch(x1),
      _922: x0 => x0.status,
      _924: x0 => x0.body,
      _925: x0 => x0.arrayBuffer(),
      _928: x0 => x0.read(),
      _929: x0 => x0.value,
      _930: x0 => x0.done,
      _937: x0 => x0.name,
      _938: x0 => x0.x,
      _939: x0 => x0.y,
      _942: x0 => x0.top,
      _943: x0 => x0.right,
      _944: x0 => x0.bottom,
      _945: x0 => x0.left,
      _955: x0 => x0.height,
      _956: x0 => x0.width,
      _957: x0 => x0.scale,
      _958: (x0,x1) => { x0.value = x1 },
      _961: (x0,x1) => { x0.placeholder = x1 },
      _963: (x0,x1) => { x0.name = x1 },
      _964: x0 => x0.selectionDirection,
      _965: x0 => x0.selectionStart,
      _966: x0 => x0.selectionEnd,
      _969: x0 => x0.value,
      _971: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _972: x0 => x0.readText(),
      _973: (x0,x1) => x0.writeText(x1),
      _975: x0 => x0.altKey,
      _976: x0 => x0.code,
      _977: x0 => x0.ctrlKey,
      _978: x0 => x0.key,
      _979: x0 => x0.keyCode,
      _980: x0 => x0.location,
      _981: x0 => x0.metaKey,
      _982: x0 => x0.repeat,
      _983: x0 => x0.shiftKey,
      _984: x0 => x0.isComposing,
      _986: x0 => x0.state,
      _987: (x0,x1) => x0.go(x1),
      _989: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _990: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _991: x0 => x0.pathname,
      _992: x0 => x0.search,
      _993: x0 => x0.hash,
      _997: x0 => x0.state,
      _1000: (x0,x1) => x0.createObjectURL(x1),
      _1002: x0 => new Blob(x0),
      _1012: x0 => x0.matches,
      _1016: x0 => x0.matches,
      _1020: x0 => x0.relatedTarget,
      _1022: x0 => x0.clientX,
      _1023: x0 => x0.clientY,
      _1024: x0 => x0.offsetX,
      _1025: x0 => x0.offsetY,
      _1028: x0 => x0.button,
      _1029: x0 => x0.buttons,
      _1030: x0 => x0.ctrlKey,
      _1034: x0 => x0.pointerId,
      _1035: x0 => x0.pointerType,
      _1036: x0 => x0.pressure,
      _1037: x0 => x0.tiltX,
      _1038: x0 => x0.tiltY,
      _1039: x0 => x0.getCoalescedEvents(),
      _1042: x0 => x0.deltaX,
      _1043: x0 => x0.deltaY,
      _1044: x0 => x0.wheelDeltaX,
      _1045: x0 => x0.wheelDeltaY,
      _1046: x0 => x0.deltaMode,
      _1053: x0 => x0.changedTouches,
      _1056: x0 => x0.clientX,
      _1057: x0 => x0.clientY,
      _1060: x0 => x0.data,
      _1063: (x0,x1) => { x0.disabled = x1 },
      _1065: (x0,x1) => { x0.type = x1 },
      _1066: (x0,x1) => { x0.max = x1 },
      _1067: (x0,x1) => { x0.min = x1 },
      _1068: x0 => x0.value,
      _1069: (x0,x1) => { x0.value = x1 },
      _1070: x0 => x0.disabled,
      _1071: (x0,x1) => { x0.disabled = x1 },
      _1073: (x0,x1) => { x0.placeholder = x1 },
      _1075: (x0,x1) => { x0.name = x1 },
      _1076: (x0,x1) => { x0.autocomplete = x1 },
      _1078: x0 => x0.selectionDirection,
      _1079: x0 => x0.selectionStart,
      _1081: x0 => x0.selectionEnd,
      _1084: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1085: (x0,x1) => x0.add(x1),
      _1087: (x0,x1) => { x0.noValidate = x1 },
      _1088: (x0,x1) => { x0.method = x1 },
      _1089: (x0,x1) => { x0.action = x1 },
      _1114: x0 => x0.orientation,
      _1115: x0 => x0.width,
      _1116: x0 => x0.height,
      _1117: (x0,x1) => x0.lock(x1),
      _1136: x0 => new ResizeObserver(x0),
      _1139: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1139(f,arguments.length,x0,x1) }),
      _1147: x0 => x0.length,
      _1148: x0 => x0.iterator,
      _1149: x0 => x0.Segmenter,
      _1150: x0 => x0.v8BreakIterator,
      _1151: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1154: x0 => x0.language,
      _1155: x0 => x0.script,
      _1156: x0 => x0.region,
      _1174: x0 => x0.done,
      _1175: x0 => x0.value,
      _1176: x0 => x0.index,
      _1180: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1181: (x0,x1) => x0.adoptText(x1),
      _1182: x0 => x0.first(),
      _1183: x0 => x0.next(),
      _1184: x0 => x0.current(),
      _1186: () => globalThis.window.FinalizationRegistry,
      _1197: x0 => x0.hostElement,
      _1198: x0 => x0.viewConstraints,
      _1201: x0 => x0.maxHeight,
      _1202: x0 => x0.maxWidth,
      _1203: x0 => x0.minHeight,
      _1204: x0 => x0.minWidth,
      _1205: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1205(f,arguments.length,x0) }),
      _1206: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1206(f,arguments.length,x0) }),
      _1207: (x0,x1) => ({addView: x0,removeView: x1}),
      _1210: x0 => x0.loader,
      _1211: () => globalThis._flutter,
      _1212: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1213: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1213(f,arguments.length,x0) }),
      _1214: (module,f) => finalizeWrapper(f, function() { return module.exports._1214(f,arguments.length) }),
      _1215: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1218: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1218(f,arguments.length,x0) }),
      _1219: x0 => ({runApp: x0}),
      _1221: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1221(f,arguments.length,x0,x1) }),
      _1222: x0 => new Promise(x0),
      _1223: x0 => x0.length,
      _1224: () => globalThis.window.ImageDecoder,
      _1225: x0 => x0.tracks,
      _1227: x0 => x0.completed,
      _1229: x0 => x0.image,
      _1235: x0 => x0.displayWidth,
      _1236: x0 => x0.displayHeight,
      _1237: x0 => x0.duration,
      _1240: x0 => x0.ready,
      _1241: x0 => x0.selectedTrack,
      _1242: x0 => x0.repetitionCount,
      _1243: x0 => x0.frameCount,
      _1295: x0 => x0.toArray(),
      _1296: x0 => x0.toUint8Array(),
      _1297: x0 => ({serverTimestamps: x0}),
      _1298: x0 => ({source: x0}),
      _1301: x0 => new firebase_firestore.FieldPath(x0),
      _1302: (x0,x1) => new firebase_firestore.FieldPath(x0,x1),
      _1303: (x0,x1,x2) => new firebase_firestore.FieldPath(x0,x1,x2),
      _1304: (x0,x1,x2,x3) => new firebase_firestore.FieldPath(x0,x1,x2,x3),
      _1305: (x0,x1,x2,x3,x4) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4),
      _1306: (x0,x1,x2,x3,x4,x5) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5),
      _1307: (x0,x1,x2,x3,x4,x5,x6) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6),
      _1308: (x0,x1,x2,x3,x4,x5,x6,x7) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7),
      _1309: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8),
      _1310: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => new firebase_firestore.FieldPath(x0,x1,x2,x3,x4,x5,x6,x7,x8,x9),
      _1311: () => globalThis.firebase_firestore.documentId(),
      _1312: (x0,x1) => new firebase_firestore.Timestamp(x0,x1),
      _1313: (x0,x1) => new firebase_firestore.GeoPoint(x0,x1),
      _1314: x0 => globalThis.firebase_firestore.vector(x0),
      _1315: x0 => globalThis.firebase_firestore.Bytes.fromUint8Array(x0),
      _1317: (x0,x1) => globalThis.firebase_firestore.collection(x0,x1),
      _1319: (x0,x1) => globalThis.firebase_firestore.doc(x0,x1),
      _1322: x0 => x0.call(),
      _1350: x0 => globalThis.firebase_firestore.deleteDoc(x0),
      _1351: x0 => globalThis.firebase_firestore.getDoc(x0),
      _1352: x0 => globalThis.firebase_firestore.getDocFromServer(x0),
      _1353: x0 => globalThis.firebase_firestore.getDocFromCache(x0),
      _1354: (x0,x1) => ({includeMetadataChanges: x0,source: x1}),
      _1357: (x0,x1,x2,x3) => globalThis.firebase_firestore.onSnapshot(x0,x1,x2,x3),
      _1360: (x0,x1) => globalThis.firebase_firestore.setDoc(x0,x1),
      _1361: (x0,x1) => globalThis.firebase_firestore.query(x0,x1),
      _1365: x0 => globalThis.firebase_firestore.limit(x0),
      _1366: x0 => globalThis.firebase_firestore.limitToLast(x0),
      _1367: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1367(f,arguments.length,x0) }),
      _1368: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1368(f,arguments.length,x0) }),
      _1369: (x0,x1) => globalThis.firebase_firestore.orderBy(x0,x1),
      _1371: (x0,x1,x2) => globalThis.firebase_firestore.where(x0,x1,x2),
      _1373: x0 => globalThis.firebase_firestore.doc(x0),
      _1376: (x0,x1) => x0.data(x1),
      _1380: x0 => x0.docChanges(),
      _1388: () => globalThis.firebase_firestore.serverTimestamp(),
      _1398: (x0,x1) => globalThis.firebase_firestore.getFirestore(x0,x1),
      _1400: x0 => globalThis.firebase_firestore.Timestamp.fromMillis(x0),
      _1401: (module,f) => finalizeWrapper(f, function() { return module.exports._1401(f,arguments.length) }),
      _1546: () => globalThis.firebase_firestore.updateDoc,
      _1547: () => globalThis.firebase_firestore.or,
      _1548: () => globalThis.firebase_firestore.and,
      _1563: x0 => x0.path,
      _1566: () => globalThis.firebase_firestore.GeoPoint,
      _1567: x0 => x0.latitude,
      _1568: x0 => x0.longitude,
      _1570: () => globalThis.firebase_firestore.VectorValue,
      _1571: () => globalThis.firebase_firestore.Bytes,
      _1574: x0 => x0.type,
      _1576: x0 => x0.doc,
      _1578: x0 => x0.oldIndex,
      _1580: x0 => x0.newIndex,
      _1582: () => globalThis.firebase_firestore.DocumentReference,
      _1586: x0 => x0.path,
      _1595: x0 => x0.metadata,
      _1596: x0 => x0.ref,
      _1601: x0 => x0.docs,
      _1603: x0 => x0.metadata,
      _1608: () => globalThis.firebase_firestore.Timestamp,
      _1609: x0 => x0.seconds,
      _1610: x0 => x0.nanoseconds,
      _1646: x0 => x0.hasPendingWrites,
      _1648: x0 => x0.fromCache,
      _1655: x0 => x0.source,
      _1660: () => globalThis.firebase_firestore.startAfter,
      _1661: () => globalThis.firebase_firestore.startAt,
      _1662: () => globalThis.firebase_firestore.endBefore,
      _1663: () => globalThis.firebase_firestore.endAt,
      _1702: (x0,x1) => x0.createElement(x1),
      _1708: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1709: x0 => x0.decode(),
      _1710: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1711: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1712: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1712(f,arguments.length,x0) }),
      _1713: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1713(f,arguments.length,x0) }),
      _1714: x0 => x0.send(),
      _1715: () => new XMLHttpRequest(),
      _1736: x0 => x0.toJSON(),
      _1737: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1737(f,arguments.length,x0) }),
      _1738: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1738(f,arguments.length,x0) }),
      _1739: (x0,x1,x2) => x0.onAuthStateChanged(x1,x2),
      _1740: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1740(f,arguments.length,x0) }),
      _1741: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1741(f,arguments.length,x0) }),
      _1742: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1742(f,arguments.length,x0) }),
      _1743: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1743(f,arguments.length,x0) }),
      _1744: (x0,x1,x2) => x0.onIdTokenChanged(x1,x2),
      _1748: (x0,x1,x2) => globalThis.firebase_auth.createUserWithEmailAndPassword(x0,x1,x2),
      _1758: (x0,x1,x2) => globalThis.firebase_auth.signInWithEmailAndPassword(x0,x1,x2),
      _1763: x0 => x0.signOut(),
      _1764: (x0,x1) => globalThis.firebase_auth.connectAuthEmulator(x0,x1),
      _1787: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromResult(x0),
      _1802: x0 => globalThis.firebase_auth.getAdditionalUserInfo(x0),
      _1803: (x0,x1,x2) => ({errorMap: x0,persistence: x1,popupRedirectResolver: x2}),
      _1804: (x0,x1) => globalThis.firebase_auth.initializeAuth(x0,x1),
      _1810: x0 => globalThis.firebase_auth.OAuthProvider.credentialFromError(x0),
      _1825: () => globalThis.firebase_auth.debugErrorMap,
      _1828: () => globalThis.firebase_auth.browserSessionPersistence,
      _1830: () => globalThis.firebase_auth.browserLocalPersistence,
      _1832: () => globalThis.firebase_auth.indexedDBLocalPersistence,
      _1835: x0 => globalThis.firebase_auth.multiFactor(x0),
      _1836: (x0,x1) => globalThis.firebase_auth.getMultiFactorResolver(x0,x1),
      _1838: x0 => x0.currentUser,
      _1852: x0 => x0.displayName,
      _1853: x0 => x0.email,
      _1854: x0 => x0.phoneNumber,
      _1855: x0 => x0.photoURL,
      _1856: x0 => x0.providerId,
      _1857: x0 => x0.uid,
      _1858: x0 => x0.emailVerified,
      _1859: x0 => x0.isAnonymous,
      _1860: x0 => x0.providerData,
      _1861: x0 => x0.refreshToken,
      _1862: x0 => x0.tenantId,
      _1863: x0 => x0.metadata,
      _1865: x0 => x0.providerId,
      _1866: x0 => x0.signInMethod,
      _1867: x0 => x0.accessToken,
      _1868: x0 => x0.idToken,
      _1869: x0 => x0.secret,
      _1881: x0 => x0.creationTime,
      _1882: x0 => x0.lastSignInTime,
      _1887: x0 => x0.code,
      _1889: x0 => x0.message,
      _1901: x0 => x0.email,
      _1902: x0 => x0.phoneNumber,
      _1903: x0 => x0.tenantId,
      _1926: x0 => x0.user,
      _1929: x0 => x0.providerId,
      _1930: x0 => x0.profile,
      _1931: x0 => x0.username,
      _1932: x0 => x0.isNewUser,
      _1935: () => globalThis.firebase_auth.browserPopupRedirectResolver,
      _1940: x0 => x0.displayName,
      _1941: x0 => x0.enrollmentTime,
      _1942: x0 => x0.factorId,
      _1943: x0 => x0.uid,
      _1945: x0 => x0.hints,
      _1946: x0 => x0.session,
      _1948: x0 => x0.phoneNumber,
      _1960: (x0,x1) => x0.getItem(x1),
      _1966: (x0,x1) => x0.createElement(x1),
      _1967: (x0,x1) => x0.appendChild(x1),
      _1970: (x0,x1,x2,x3,x4,x5,x6,x7,x8) => ({apiKey: x0,authDomain: x1,databaseURL: x2,projectId: x3,storageBucket: x4,messagingSenderId: x5,measurementId: x6,appId: x7,recaptchaSiteKey: x8}),
      _1971: (x0,x1) => globalThis.firebase_core.initializeApp(x0,x1),
      _1972: x0 => globalThis.firebase_core.getApp(x0),
      _1973: () => globalThis.firebase_core.getApp(),
      _1974: (x0,x1,x2) => globalThis.firebase_core.registerVersion(x0,x1,x2),
      _1976: () => globalThis.firebase_core.SDK_VERSION,
      _1982: x0 => x0.apiKey,
      _1984: x0 => x0.authDomain,
      _1986: x0 => x0.databaseURL,
      _1988: x0 => x0.projectId,
      _1990: x0 => x0.storageBucket,
      _1992: x0 => x0.messagingSenderId,
      _1994: x0 => x0.measurementId,
      _1996: x0 => x0.appId,
      _1998: x0 => x0.recaptchaSiteKey,
      _2000: x0 => x0.name,
      _2001: x0 => x0.options,
      _2002: (x0,x1,x2) => x0.setItem(x1,x2),
      _2003: (x0,x1) => x0.debug(x1),
      _2004: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2004(f,arguments.length,x0) }),
      _2005: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2005(f,arguments.length,x0,x1) }),
      _2006: (x0,x1) => ({createScript: x0,createScriptURL: x1}),
      _2007: (x0,x1,x2) => x0.createPolicy(x1,x2),
      _2008: (x0,x1) => x0.createScriptURL(x1),
      _2009: (x0,x1,x2) => x0.createScript(x1,x2),
      _2010: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2010(f,arguments.length,x0) }),
      _2012: Date.now,
      _2014: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _2015: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _2016: () => typeof dartUseDateNowForTicks !== "undefined",
      _2017: () => 1000 * performance.now(),
      _2018: () => Date.now(),
      _2019: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _2021: () => new WeakMap(),
      _2022: (map, o) => map.get(o),
      _2023: (map, o, v) => map.set(o, v),
      _2024: x0 => new WeakRef(x0),
      _2025: x0 => x0.deref(),
      _2032: () => globalThis.WeakRef,
      _2035: s => JSON.stringify(s),
      _2036: s => printToConsole(s),
      _2037: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _2038: (o, p, r) => o.replaceAll(p, () => r),
      _2040: Function.prototype.call.bind(String.prototype.toLowerCase),
      _2041: s => s.toUpperCase(),
      _2042: s => s.trim(),
      _2043: s => s.trimLeft(),
      _2044: s => s.trimRight(),
      _2045: (string, times) => string.repeat(times),
      _2046: Function.prototype.call.bind(String.prototype.indexOf),
      _2047: (s, p, i) => s.lastIndexOf(p, i),
      _2048: (string, token) => string.split(token),
      _2049: Object.is,
      _2054: (o, c) => o instanceof c,
      _2055: o => Object.keys(o),
      _2109: x0 => new Array(x0),
      _2111: x0 => x0.length,
      _2113: (x0,x1) => x0[x1],
      _2114: (x0,x1,x2) => { x0[x1] = x2 },
      _2117: (x0,x1,x2) => new DataView(x0,x1,x2),
      _2119: x0 => new Int8Array(x0),
      _2120: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _2122: x0 => new Uint8ClampedArray(x0),
      _2124: x0 => new Int16Array(x0),
      _2126: x0 => new Uint16Array(x0),
      _2128: x0 => new Int32Array(x0),
      _2130: x0 => new Uint32Array(x0),
      _2132: x0 => new Float32Array(x0),
      _2134: x0 => new Float64Array(x0),
      _2158: x0 => x0.random(),
      _2161: () => globalThis.Math,
      _2174: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _2175: (handle) => clearTimeout(handle),
      _2176: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _2177: (handle) => clearInterval(handle),
      _2178: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _2179: () => Date.now(),
      _2180: () => new Error().stack,
      _2181: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _2182: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _2183: (x0,x1) => x0.exec(x1),
      _2184: (x0,x1) => x0.test(x1),
      _2185: x0 => x0.pop(),
      _2187: o => o === undefined,
      _2189: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _2191: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _2192: o => o instanceof RegExp,
      _2193: (l, r) => l === r,
      _2194: o => o,
      _2195: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _2196: o => o,
      _2197: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _2198: o => o,
      _2199: b => !!b,
      _2200: o => o.length,
      _2202: (o, i) => o[i],
      _2203: f => f.dartFunction,
      _2204: () => ({}),
      _2205: () => [],
      _2207: () => globalThis,
      _2208: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _2209: (o, p) => p in o,
      _2210: (o, p) => o[p],
      _2211: (o, p, v) => o[p] = v,
      _2212: (o, m, a) => o[m].apply(o, a),
      _2214: o => String(o),
      _2215: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _2216: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._2216(f,arguments.length,x0) }),
      _2217: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._2217(f,arguments.length,x0,x1) }),
      _2218: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _2219: o => [o],
      _2220: (o0, o1) => [o0, o1],
      _2221: (o0, o1, o2) => [o0, o1, o2],
      _2222: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _2223: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _2224: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2225: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2228: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2229: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2230: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2231: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2232: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _2233: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _2234: x0 => new ArrayBuffer(x0),
      _2235: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _2237: x0 => x0.index,
      _2238: x0 => x0.groups,
      _2239: x0 => x0.flags,
      _2240: x0 => x0.multiline,
      _2241: x0 => x0.ignoreCase,
      _2242: x0 => x0.unicode,
      _2243: x0 => x0.dotAll,
      _2244: (x0,x1) => { x0.lastIndex = x1 },
      _2245: (o, p) => p in o,
      _2246: (o, p) => o[p],
      _2247: (o, p, v) => o[p] = v,
      _2248: (o, p) => delete o[p],
      _2276: x0 => x0.trustedTypes,
      _2277: (x0,x1) => { x0.text = x1 },
      _2278: o => o instanceof Array,
      _2282: a => a.pop(),
      _2283: (a, i) => a.splice(i, 1),
      _2284: (a, s) => a.join(s),
      _2285: (a, s, e) => a.slice(s, e),
      _2288: a => a.length,
      _2290: (a, i) => a[i],
      _2291: (a, i, v) => a[i] = v,
      _2293: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _2294: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _2296: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _2297: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _2298: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _2299: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _2300: o => o instanceof Uint8ClampedArray,
      _2301: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _2302: o => o instanceof Uint16Array,
      _2303: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _2304: o => o instanceof Int16Array,
      _2305: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _2306: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _2307: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _2308: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _2309: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _2311: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _2312: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _2313: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _2314: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _2315: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _2316: (a, i) => a.push(i),
      _2317: (t, s) => t.set(s),
      _2319: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _2321: o => o.buffer,
      _2322: o => o.byteOffset,
      _2323: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _2324: (b, o) => new DataView(b, o),
      _2325: (b, o, l) => new DataView(b, o, l),
      _2326: Function.prototype.call.bind(DataView.prototype.getUint8),
      _2327: Function.prototype.call.bind(DataView.prototype.setUint8),
      _2328: Function.prototype.call.bind(DataView.prototype.getInt8),
      _2329: Function.prototype.call.bind(DataView.prototype.setInt8),
      _2330: Function.prototype.call.bind(DataView.prototype.getUint16),
      _2331: Function.prototype.call.bind(DataView.prototype.setUint16),
      _2332: Function.prototype.call.bind(DataView.prototype.getInt16),
      _2333: Function.prototype.call.bind(DataView.prototype.setInt16),
      _2334: Function.prototype.call.bind(DataView.prototype.getUint32),
      _2335: Function.prototype.call.bind(DataView.prototype.setUint32),
      _2336: Function.prototype.call.bind(DataView.prototype.getInt32),
      _2337: Function.prototype.call.bind(DataView.prototype.setInt32),
      _2340: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _2341: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _2342: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _2343: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _2344: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _2345: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _2346: Function.prototype.call.bind(Number.prototype.toString),
      _2347: Function.prototype.call.bind(BigInt.prototype.toString),
      _2348: Function.prototype.call.bind(Number.prototype.toString),
      _2349: (d, digits) => d.toFixed(digits),
      _2362: () => globalThis.document,
      _2364: () => globalThis.console,
      _2369: (x0,x1) => { x0.height = x1 },
      _2371: (x0,x1) => { x0.width = x1 },
      _2373: (x0,x1) => { x0.pointerEvents = x1 },
      _2382: x0 => x0.style,
      _2385: x0 => x0.src,
      _2386: (x0,x1) => { x0.src = x1 },
      _2387: x0 => x0.naturalWidth,
      _2388: x0 => x0.naturalHeight,
      _2403: (x0,x1) => x0.error(x1),
      _2408: x0 => x0.status,
      _2409: (x0,x1) => { x0.responseType = x1 },
      _2411: x0 => x0.response,
      _3777: (x0,x1) => { x0.type = x1 },
      _3785: (x0,x1) => { x0.crossOrigin = x1 },
      _3787: (x0,x1) => { x0.text = x1 },
      _4244: () => globalThis.window,
      _4288: x0 => x0.location,
      _4569: x0 => x0.trustedTypes,
      _4570: x0 => x0.sessionStorage,
      _4586: x0 => x0.hostname,
      _6925: () => globalThis.document,
      _7008: x0 => x0.head,
      _13745: () => globalThis.console,
      _13773: x0 => x0.name,
      _13774: x0 => x0.message,
      _13775: x0 => x0.code,
      _13777: x0 => x0.customData,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });
    dartInstance.exports.$setThisModule(dartInstance);

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
