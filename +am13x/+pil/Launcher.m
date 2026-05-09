classdef Launcher < rtw.connectivity.Launcher
%LAUNCHER is an example target connectivity configuration class

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

    properties
        % For the host-based example, additional arguments may be provided when the
        % executable is launched as a separate process on the host. For example it may
        % be required to specify a TCP/IP port number.
        ArgString= '';

        % For the host-based example, it is necessary to
        % keep track of the process ID of the executable
        % so that this process can be killed when no longer
        % required
        ExePid = '';

        % For the host-based example, it is necessary to keep track of a temporary file
        % created by the process launcher so that it can be deleted when the
        % process is terminated
        TempFile = '';
    end

    methods
        % constructor
        function this = Launcher(componentArgs, builder)
            narginchk(2, 2);
            % call super class constructor
            this@rtw.connectivity.Launcher(componentArgs, builder);
        end

        % destructor
        function delete(this) %#ok

            % This method is called when an instance of this class is cleared from memory,
            % e.g. when the associated Simulink model is closed. You can use
            % this destructor method to close down any processes, e.g. an IDE or
            % debugger that was originally started by this class. If the
            % stopApplication method already performs this housekeeping at the
            % end of each on-target simulation run then it is not necessary to
            % insert any code in this destructor method. However, if the IDE or
            % debugger may be left open between successive on-target simulation
            % runs then it is recommended to insert code here to terminate that
            % application.

        end

        function setArgString(this, argString)
            % Specify command line arguments; for example, you may need to provide a TCP/IP
            % port number to override the default port number. If your Launcher
            % does not require any dynamic parameter configuration then this
            % method may not be required.
            disp('EXECUTING METHOD SETARGSTRING')
            stack = dbstack;
            disp(['SETARGSTRING called from line '...
                  int2str(stack(2).line) ' of ' ...
                  stack(2).file ])

            this.ArgString = argString;
        end

        % Start the application
        function startApplication(this)
            % get name of the executable file
            out = this.getBuilder.getApplicationExecutable;
            hCS = this.getComponentArgs.getConfigInterface.getConfig;

            % launch
            TargetHardware = getpref('AM13xPILpref', 'PILHardware');
            disp('Starting PIL simulation')
                if(strcmpi(TargetHardware, 'AM13E230x'))
                    am13x.internal.loadAndRun(hCS, out);
                end
            pause(1);
        end

        % Stop the application
        function stopApplication(~)
            disp('Stopping PIL simulation')
        end
    end
end
