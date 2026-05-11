function setSyscfgPath(modelName, syscfgPath)
%SETSYSCFGPATH Set the SysConfig project file path for a model
%
%   am13x.setSyscfgPath(modelName, syscfgPath) sets the SysConfig project
%   file path for the specified model. This allows programmatic configuration
%   of the SysConfig file path for automation purposes.
%
%   Parameters:
%       modelName  - Name of the Simulink model (string or char)
%       syscfgPath - Full path to the SysConfig project file (string or char)
%
%   Example:
%       % Set the SysConfig path for a model
%       am13x.setSyscfgPath('my_model', 'C:\Projects\my_project\config.syscfg');
%
%       % Verify it was set
%       path = am13x.getSyscfgPath('my_model');
%       fprintf('SysConfig file set to: %s\n', path);
%
%   See also: am13x.getSyscfgPath

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

    % Validate inputs
    if nargin < 2
        error('am13x:setSyscfgPath:MissingInput', ...
              'Both model name and SysConfig path are required.\nUsage: am13x.setSyscfgPath(modelName, syscfgPath)');
    end

    % Convert to char if string
    if isstring(modelName)
        modelName = char(modelName);
    end
    if isstring(syscfgPath)
        syscfgPath = char(syscfgPath);
    end

    % Validate model name
    validateattributes(modelName, {'char'}, {'nonempty', 'row'}, ...
                      'setSyscfgPath', 'modelName');

    % Validate syscfg path
    validateattributes(syscfgPath, {'char'}, {'nonempty', 'row'}, ...
                      'setSyscfgPath', 'syscfgPath');

    % Check if model is loaded
    if ~bdIsLoaded(modelName)
        error('am13x:setSyscfgPath:ModelNotLoaded', ...
              'Model "%s" is not loaded. Please load the model first.', modelName);
    end

    % Validate file exists
    if ~exist(syscfgPath, 'file')
        error('am13x:setSyscfgPath:FileNotFound', ...
              'SysConfig file does not exist: %s', syscfgPath);
    end

    % Validate file extension
    [~, ~, ext] = fileparts(syscfgPath);
    if ~strcmpi(ext, '.syscfg')
        warning('am13x:setSyscfgPath:InvalidExtension', ...
                'File does not have .syscfg extension: %s', syscfgPath);
    end

    try
        % Get the configuration set
        cs = getActiveConfigSet(modelName);

        % Set the SysConfig file path
        codertarget.data.setParameterValue(cs, 'SysConfig.ProjectFile', syscfgPath);

        fprintf('[OK] SysConfig file path set for model "%s": %s\n', modelName, syscfgPath);

    catch ME
        error('am13x:setSyscfgPath:SetFailed', ...
              'Failed to set SysConfig path: %s', ME.message);
    end

end