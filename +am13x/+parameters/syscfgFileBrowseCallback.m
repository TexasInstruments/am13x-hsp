function syscfgFileBrowseCallback(hObj, ~, ~, ~)
%SYSCFGFILEBROWSECALLBACK Browse to select an existing SysConfig project file
%
%   Parameters:
%       hObj  - Handle to the object
%       hDlg  - Handle to the dialog
%       tag   - Tag of the widget
%       ~     - Unused parameter

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

    % Define file filter
    fileFilter = {'*.syscfg', 'SysConfig Files (*.syscfg)'; ...
                  '*.*', 'All Files (*.*)'};
    dialogTitle = 'Select SysConfig Project File';

    % Get config set from hObj
    cs = hObj.getConfigSet;

    % Get current path for initial directory
    initialDir = pwd;
    try
        currentPath = codertarget.data.getParameterValue(cs, 'SysConfig.ProjectFile');
        if ~isempty(currentPath) && ~startsWith(currentPath, '<')
            [pathDir, ~, ~] = fileparts(currentPath);
            if ~isempty(pathDir) && exist(pathDir, 'dir')
                initialDir = pathDir;
            end
        end
    catch
        % Use pwd
    end

    % Open file browser
    prevDir = pwd;
    cd(initialDir);
    [fileName, filePath] = uigetfile(fileFilter, dialogTitle);
    cd(prevDir);

    % User cancelled
    if isequal(fileName, 0) || isequal(filePath, 0)
        return;
    end

    % Full path
    fullFilePath = fullfile(filePath, fileName);

    % Validate file exists
    if ~exist(fullFilePath, 'file')
        errordlg(sprintf('Selected file does not exist:\n%s', fullFilePath), ...
                 'File Not Found', 'modal');
        return;
    end

    % Validate extension
    [~, ~, ext] = fileparts(fullFilePath);
    if ~strcmpi(ext, '.syscfg')
        warndlg(sprintf('File does not have .syscfg extension:\n%s', fullFilePath), ...
                'Warning', 'modal');
    end

    % Set the value using codertarget.data.setParameterValue
    codertarget.data.setParameterValue(cs, 'SysConfig.ProjectFile', fullFilePath);

    fprintf('[OK] SysConfig file selected: %s\n', fullFilePath);

end