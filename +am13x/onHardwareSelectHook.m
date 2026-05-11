function onHardwareSelectHook(hCS)
%ONHARDWARESELECT Hook point on target selection
%
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


if isempty(hCS.getModel)
    return;
end
set_param(hCS, 'ERTCustomFileTemplate', 'AM13x_codertarget_file_process.tlc');

% Optimization related defaults, keeping it as faster runs -O3 similar to
% SDK examples
set_param(hCS, 'BuildConfiguration', 'Faster runs');
set_param(hCS,'CodeReplacementLibrary','AM13x_TMU');
% Enable Multitasking for scheduler
set_param(hCS,'EnableMultiTasking','on');
% Other handy defaults
set_param(hCS,'ProdLongLongMode','on');
% set_param(hCS,'MaxStackSize','2048');
% Set default max identifier length to 256 for longer model names
set_param(hCS, 'MaxIdLength', 256);

% Set default SysConfig file if not already set
try
    currentSyscfgPath = codertarget.data.getParameterValue(hCS, 'SysConfig.ProjectFile');
    
    % Check if SysConfig path is not set or is the placeholder
    if isempty(currentSyscfgPath) || startsWith(currentSyscfgPath, '<')
        % Get the path to the default.syscfg file
        % The file is located at: <support_package_root>/examples/default.syscfg
        targetRoot = am13x.getTargetRoot();
        defaultSyscfgPath = fullfile(targetRoot, 'examples', 'default.syscfg');
        
        % Verify the default file exists
        if exist(defaultSyscfgPath, 'file')
            % Set the default SysConfig file path
            codertarget.data.setParameterValue(hCS, 'SysConfig.ProjectFile', defaultSyscfgPath);
            fprintf('[INFO] Default SysConfig file set: %s\n', defaultSyscfgPath);
        else
            fprintf('[WARN] Default SysConfig file not found at: %s\n', defaultSyscfgPath);
        end
    end
catch ME
    % Silently handle errors - don't interrupt hardware selection
    fprintf('[WARN] Could not set default SysConfig file: %s\n', ME.message);
end

end