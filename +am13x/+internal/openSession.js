/*
Util to load program/application binary to any MCU architecture using new CCS scripting CLI tool

How to run this script:
cd <CCS_ROOT>\ccs\scripting
run.bat <script.js> <ccsRoot> <ccxmlPath> <coreArch> <binaryPath>

Inside this script, process.argv maps as:
args[0] = node executable        (managed internally by run.bat)
args[1] = launcher shim           (managed internally by run.bat)
args[2] = openSession.js path     (this script)
args[3] = CCS root path           e.g. C:/ti/ccs2050
args[4] = ccxml file path         e.g. C:/.../AM13E230X.ccxml
args[5] = core architecture       e.g. CORTEX_M33
args[6] = application binary path e.g. C:/.../model.out


NOTE: xds110_server.exe is killed before each call by loadAndRun.m.
This is required because ds.shutdown() does not kill xds110_server.exe,
leaving it holding the JTAG port and causing loadProgram() to hang
on subsequent calls.
*/

/********************************************************************
 * Copyright (C) 2026 Texas Instruments Incorporated.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

const args = process.argv;
console.log('Deployment Initiated...');
console.log('CCS Path: ', args[3]);
console.log('ccxml Path: ', args[4]);
console.log('Core Architecture: ', args[5]);
console.log('Binary Path: ', args[6]);

let ccsPath    = args[3];
let ccxmlPath  = args[4];
let coreArch   = args[5];
let binaryPath = args[6];

// Load CCS scripting modules
const scripting = require(ccsPath + '/ccs/scripting/node_modules/scripting');
const ds = scripting.initScripting();
ds.setScriptingTimeout(30000);

// Open debug session
ds.configure(ccxmlPath);
let session = ds.openSession("Texas Instruments XDS110 USB Debug Probe/" + coreArch);
session.target.connect();
session.settings.set('VerifyAfterProgramLoad', 'No verification');
session.settings.set('AutoRunToLabelOnRestart', false);

try {
    // Flash the binary — loadProgram() erases, programs and halts at reset vector
    console.log('Loading program...');
    session.memory.loadProgram(binaryPath);
    console.log('Deployment success');
    /*
    Sporadically application starts up fails without reset. Enable reset if deployment fails
    session.target.reset("System Reset");
    session.target.halt();
    */

} catch (error) {
    // Flash failed — disconnect cleanly before throwing
    console.error('Failed to load program:', error.message);
    session.target.disconnect();
    ds.shutdown();
    throw error;
}

// Release CPU — separated from loadProgram try/catch so flash errors
// and run errors are reported independently and not conflated
try {
    session.target.run(false);
    console.log('Application running, disconnecting CCS');
} catch (error) {
    // Harmless — target may already be running after loadProgram() internal reset
    console.log('Note: run() reported: ' + error.message + ' — target may already be running.');
}

session.target.disconnect();
ds.shutdown();
