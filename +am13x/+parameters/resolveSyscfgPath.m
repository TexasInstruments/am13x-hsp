function resolvedPath = resolveSyscfgPath(syscfgPath, modelName)
%RESOLVESYSCFGPATH Resolve syscfg file path (absolute or relative to .slx file)
%
%   resolvedPath = resolveSyscfgPath(syscfgPath, modelName) resolves the
%   syscfg file path. If the path is absolute, it returns it as-is. If the
%   path is relative, it resolves it relative to the directory containing
%   the .slx file.
%
%   Parameters:
%       syscfgPath - The syscfg file path (can be absolute or relative)
%       modelName  - Name of the Simulink model
%
%   Returns:
%       resolvedPath - The resolved absolute path to the syscfg file
%
%   Examples:
%       % Absolute path - returned as-is
%       path = resolveSyscfgPath('C:/project/config.syscfg', 'myModel');
%
%       % Relative path - resolved relative to .slx file location
%       path = resolveSyscfgPath('./config.syscfg', 'myModel');
%       path = resolveSyscfgPath('config.syscfg', 'myModel');

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
        error('am13x:resolveSyscfgPath:MissingInput', ...
              'Both syscfgPath and modelName are required.');
    end

    % Convert to char if string
    if isstring(syscfgPath)
        syscfgPath = char(syscfgPath);
    end
    if isstring(modelName)
        modelName = char(modelName);
    end

    % Return empty or placeholder paths as-is
    if isempty(syscfgPath) || startsWith(syscfgPath, '<')
        resolvedPath = syscfgPath;
        return;
    end

    % Absolute path: starts with drive letter (C:)
    isAbsolute = false;
    if (length(syscfgPath) >= 2 && syscfgPath(2) == ':')
        isAbsolute = true;
    end

    % If absolute, return as-is
    if isAbsolute
        resolvedPath = syscfgPath;
        return;
    end

    % Path is relative - resolve relative to .slx file directory
    fprintf('[INFO] Path is not absolute, using relative path: %s\n', syscfgPath);

    % Get the .slx file location using the same approach as generateSyscfgFiles
    try
        slxFile = get_param(modelName, 'FileName');
    catch
        error('am13x:resolveSyscfgPath:ModelNotFound', ...
              'Could not determine model file location for "%s". Unable to resolve relative path: %s', ...
              modelName, syscfgPath);
    end

    % Determine the model directory (where the .slx file is located)
    if ~isempty(slxFile)
        [modelDir, ~, ~] = fileparts(slxFile);
        fprintf('[INFO] Model directory: %s\n', modelDir);
    else
        error('am13x:resolveSyscfgPath:ModelNotFound', ...
              'Could not determine model directory for "%s". Unable to resolve relative path: %s', ...
              modelName, syscfgPath);
    end

    % Resolve the relative path
    resolvedPath = fullfile(modelDir, syscfgPath);

    % Normalize the path (resolve ./ and ../) without using Java
    % Use what() to get the canonical path on Windows
    try
        % Get file info which returns canonical path
        [fPath, fName, fExt] = fileparts(resolvedPath);
        if exist(fPath, 'dir')
            % Change to the directory to get its canonical path
            currentDir = pwd;
            cd(fPath);
            canonicalDir = pwd;
            cd(currentDir);
            resolvedPath = fullfile(canonicalDir, [fName, fExt]);
        end
    catch
        % If the above fails, keep the fullfile result
        % This handles cases where the directory doesn't exist yet
    end

    fprintf('[INFO] Resolved to: %s\n', resolvedPath);

    % Validate that the resolved file exists
    if ~exist(resolvedPath, 'file')
        error('am13x:resolveSyscfgPath:FileNotFound', ...
              'SysConfig file does not exist at resolved path:\n  Relative path: %s\n  Model directory: %s\n  Resolved path: %s', ...
              syscfgPath, modelDir, resolvedPath);
    end

end