classdef ConnectivityConfig < rtw.connectivity.Config
%CONNECTIVITYCONFIG is an example target connectivity configuration class

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

    methods
        function this = ConnectivityConfig(componentArgs)

            % A target application framework specifies additional source files and libraries
            % required for building the executable
            componentArgs.CoderAssumptionsEnabled = false;
            targetApplicationFramework = ...
                am13x.pil.TargetApplicationFramework(componentArgs);

            % Filename extension for executable on the target system (e.g.
            % '.exe' for Windows or '' for Unix
            if ispc
                exeExtension = '.out';
            else
                exeExtension = '';
            end

            % Create an instance of MakefileBuilder; this works in conjunction with your
            % template makefile to build the PIL executable
            builder = rtw.connectivity.MakefileBuilder(componentArgs, ...
                targetApplicationFramework, ...
                exeExtension);

            % Launcher
            launcher = am13x.pil.Launcher(componentArgs, builder);

            % File extension for shared libraries (e.g. .dll on Windows)
            [~, ~, sharedLibExt] = coder.BuildConfig.getStdLibInfo;

            % Evaluate name of the rtIOStream shared library
            rtiostreamLib = ['libmwrtiostreamserial' sharedLibExt];

            hostCommunicator = rtw.connectivity.RtIOStreamHostCommunicator(...
                componentArgs, ...
                launcher, ...
                rtiostreamLib);

            % For some targets it may be necessary to set a timeout value
            % for initial setup of the communications channel. For example,
            % the target processor may take a few seconds before it is
            % ready to open its side of the communications channel. If a
            % non-zero timeout value is set then the communicator will
            % repeatedly try to open the communications channel until the
            % timeout value is reached.
            hostCommunicator.setInitCommsTimeout(20);

            % Configure a timeout period for reading of data by the host
            % from the target. If no data is received with the specified
            % period an error will be thrown.
            timeoutReadDataSecs = 20;
            hostCommunicator.setTimeoutRecvSecs(timeoutReadDataSecs);


            % Specify additional arguments when starting the
            % executable (this configures the target-side of the
            % communications channel)
            %COMPort = 'COM67';
            COMPort = getpref('AM13xPILpref', 'COMport');
            BaudRate = getpref('AM13xPILpref', 'Baud');
            fprintf('### PIL Serial Port : %s\n', COMPort);
            fprintf('### PIL Baud : %s\n', BaudRate);

            % Custom arguments that will be passed to the
            % rtIOStreamOpen function in the rtIOStream shared
            % library (this configures the host-side of the
            % communications channel)

            %COMPort = 'COM67';
            %BaudRate = 115200;
            rtIOStreamOpenArgs = {...
                '-baud', num2str(BaudRate), ...
                '-port', COMPort, ...
                };

            hostCommunicator.setOpenRtIOStreamArgList(...
                rtIOStreamOpenArgs);


            % call super class constructor to register components
            this@rtw.connectivity.Config(componentArgs,...
                builder,...
                launcher,...
                hostCommunicator);

            % Optionally, you can register a hardware-specific timer. Registering a timer
            % enables the code execution profiling feature. In this example
            % implementation, we use a timer for the host platform.

            % Read MCLK_FREQ_HZ directly from the SysConfig-generated header
            % so the profiling timer always matches the actual device clock.
            cgDir = fullfile(componentArgs.getApplicationCodePath, '..\'); % one folder behind pil
            clockRate = am13x.readClockFreqHz(cgDir, 'MCLK_FREQ_HZ');

            % Custom am13x specific timer using DWT - performs better
            timer = am13x.pil.profilingTimer(clockRate);
            % Backup: base timer using systick
            % timer = codertarget.arm_cortex_m.pil.Timer(clockRate);
            this.setTimer(timer);

            % Specify removal of profiling instrumentation overheads
            this.activateOverheadFiltering(true);
            this.runOverheadBenchmark(true);
            this.setOverheadBenchmarkSteps(100);
        end
    end
end

