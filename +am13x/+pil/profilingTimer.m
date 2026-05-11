function hLib = profilingTimer(clockRate)
% PROFILINGTIMER Create Code Replacement Library Entry for function
%  code_profile_read_timer.  Enables profiling during PIL Simulation

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
%---------- entry: code_profile_read_timer -----------
hEnt = RTW.TflCFunctionEntry;

[fldrPath,~,~]=fileparts(mfilename("fullpath"));
targetroot = fullfile(fldrPath,'..','..');

TargetHardware = getpref('AM13xPILpref', 'PILHardware');
if(strcmpi(TargetHardware, 'AM13E230x'))
    hEnt.setTflCFunctionEntryParameters( ...
              'Key', 'code_profile_read_timer', ...
              'Priority', 100, ...
              'ImplementationName', 'profileReadTimer', ...
              'SaturationMode', 'RTW_SATURATE_ON_OVERFLOW', ...
              'ImplementationSourceFile', 'profiler_timer_am13x.c', ...
              'ImplementationHeaderFile', 'profiler_timer_am13x.h', ...
              'ImplementationHeaderPath', fullfile(targetroot, 'include'), ...
              'ImplementationSourcePath', fullfile(targetroot, 'src'));

            hEnt.EntryInfo.CountDirection = 'RTW_TIMER_UP';
            hEnt.EntryInfo.TicksPerSecond = clockRate;

    % Conceptual Args

            arg = hEnt.getTflArgFromString('y1','uint32');
            arg.IOType = 'RTW_IO_OUTPUT';
            hEnt.addConceptualArg(arg);

    % Implementation Args

           arg = hEnt.getTflArgFromString('y1','uint32');
           arg.IOType = 'RTW_IO_OUTPUT';
           hEnt.Implementation.setReturn(arg);

           hLib.addEntry( hEnt );
end

