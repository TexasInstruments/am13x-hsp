classdef TargetApplicationFramework < rtw.pil.RtIOStreamApplicationFramework
%TARGETAPPLICATIONFRAMEWORK is an example target connectivity configuration class

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
        function this = TargetApplicationFramework(componentArgs)
            narginchk(1, 1);
            % call super class constructor
            this@rtw.pil.RtIOStreamApplicationFramework(componentArgs);

            % To build the PIL application you must specify a main.c file.
            % The following PIL main.c files are provided and can be
            % added to the application framework via the "addPILMain"
            % method:
            %
            % 1) A main.c adapted for on-target PIL and suitable
            %    for most PIL implementations. Select by specifying
            %    'target' argument to "addPILMain" method.
            %
            % 2) A main.c adapted for host-based PIL such as the
            %    "mypil" host example. Select by specifying 'host'
            %    argument to "addPILMain" method.

            % Additional source and library files to include in the build
            % must be added to the BuildInfo property

            % Get the BuildInfo object to update
            buildInfo = this.getBuildInfo;

            % Add device driver files to implement the target-side of the
            % host-target rtIOStream communications channel

            rootDir = am13x.internal.getRootDir;
            srcpath = fullfile(rootDir, 'src');
            buildInfo.addSourcePaths(srcpath);

            TargetHardware = getpref('AM13xPILpref', 'PILHardware');

            if(strcmpi(TargetHardware, 'AM13E230x'))
                buildInfo.addIncludeFiles({'rtiostream.h'}, fullfile(rootDir, 'include'));
                buildInfo.addSourceFiles({'rtiostream_serial_am13x.c', 'pil_main_am13x.c'}, fullfile(rootDir, 'src'));
                % add UART HAL path
                buildInfo.addIncludePaths(getenv('HAL_INCLUDE'));
                buildInfo.addIncludePaths(getenv('HALCFG_INCLUDE'));
                % Add defines
                baudRate = getpref('AM13xPILpref', 'Baud');
                addDefines(buildInfo,  ['-DAM13x_BAUDRATE=' baudRate], 'SkipForSil');

                % Use this for generic common pil main, we are using custom
                % pil_main_am13x to have proper seperation of device/startup init vs
                % rtioStream specific init
                % this.addPILMain('target');
            end
        end
    end
end
