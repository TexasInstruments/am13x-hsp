function hLib = tmu_optimization_am13x
% TMU_OPTIMIZATION_AM13X Code Replacement Library for AM13X TMU
%
% Replaces standard math functions with TMU-accelerated implementations
% using fastrts_tmu.h

%  Copyright (C) 2026 Texas Instruments Incorporated
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions
%  are met:
%
%    Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
%
%    Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the
%    distribution.
%
%    Neither the name of Texas Instruments Incorporated nor the names of
%    its contributors may be used to endorse or promote products derived
%    from this software without specific prior written permission.
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
%  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
%  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
%  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
%  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

hLib = RTW.TflTable;

% Get path to fastrts_tmu.h
[fldrPath, ~, ~] = fileparts(mfilename("fullpath"));
targetroot = fullfile(fldrPath, '..', '..', '..');
filepath = fullfile(targetroot, 'source', 'mathlib', 'fastrts');

%---------- entry: sinf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'sin', ...
    'Priority', 100, ...
    'ImplementationName', 'sinf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: cosf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'cos', ...
    'Priority', 100, ...
    'ImplementationName', 'cosf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: asinf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'asin', ...
    'Priority', 100, ...
    'ImplementationName', 'asinf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: acosf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'acos', ...
    'Priority', 100, ...
    'ImplementationName', 'acosf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: atanf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'atan', ...
    'Priority', 100, ...
    'ImplementationName', 'atanf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: atan2f -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'atan2', ...
    'Priority', 100, ...
    'ImplementationName', 'atan2f_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u2', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

arg = hEnt.getTflArgFromString('u2', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: expf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'exp', ...
    'Priority', 100, ...
    'ImplementationName', 'expf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: logf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'log', ...
    'Priority', 100, ...
    'ImplementationName', 'logf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: sqrtf -----------
hEnt = RTW.TflCFunctionEntry;
hEnt.setTflCFunctionEntryParameters( ...
    'Key', 'sqrt', ...
    'Priority', 100, ...
    'ImplementationName', 'sqrtf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

%---------- entry: divf (Product block with divide) -----------
hEnt = RTW.TflCOperationEntry;  % <-- Must be TflCOperationEntry for operators!
hEnt.setTflCOperationEntryParameters( ...
    'Key', 'RTW_OP_DIV', ...
    'Priority', 100, ...
    'SaturationMode', 'RTW_WRAP_ON_OVERFLOW', ...
    'RoundingMode', 'RTW_ROUND_UNSPECIFIED', ...
    'ImplementationName', 'divf_tmu', ...
    'ImplementationHeaderFile', 'fastrts_tmu.h', ...
    'ImplementationHeaderPath', filepath);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('u2', 'single');
arg.IOType = 'RTW_IO_INPUT';
hEnt.addConceptualArg(arg);

arg = hEnt.getTflArgFromString('y1', 'single');
arg.IOType = 'RTW_IO_OUTPUT';
hEnt.Implementation.setReturn(arg);

arg = hEnt.getTflArgFromString('u1', 'single');
hEnt.Implementation.addArgument(arg);

arg = hEnt.getTflArgFromString('u2', 'single');
hEnt.Implementation.addArgument(arg);

hLib.addEntry(hEnt);

end