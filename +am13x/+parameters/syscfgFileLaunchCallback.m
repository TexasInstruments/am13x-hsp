function syscfgFileLaunchCallback(hObj, ~, ~, ~)
%SYSCFGFILELAUNCHCALLBACK Launch SysConfig CodeGen Tool with selected project
%   This callback is triggered when the user clicks the "Launch..." button
%   in the hardware settings dialog.
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

    % Get config set from hObj
    cs = hObj.getConfigSet;

    % Get current SysConfig file path using codertarget API
    syscfgFilePath = '';
    try
        syscfgFilePath = codertarget.data.getParameterValue(cs, 'SysConfig.ProjectFile');
    catch ME
        fprintf('[ERROR] Failed to get SysConfig.ProjectFile: %s\n', ME.message);
    end

    % Validate file path
    if isempty(syscfgFilePath) || startsWith(syscfgFilePath, '<')
        errordlg('No SysConfig file selected. Please browse or create a file first.', ...
                 'No File Selected', 'modal');
        return;
    end

    modelName = get_param(getModel(cs), 'Name');
    syscfgFilePath = am13x.parameters.resolveSyscfgPath(syscfgFilePath, modelName);

    if ~exist(syscfgFilePath, 'file')
        errordlg(sprintf('SysConfig file not found:\n%s\n\nPlease select a valid file.', ...
                         syscfgFilePath), 'File Not Found', 'modal');
        return;
    end

    % Get SysConfig installation path
    syscfgRoot = getenv('SYSCFG_ROOT');
    if isempty(syscfgRoot)
        errordlg(['SYSCFG_ROOT environment variable is not set.', newline, newline, ...
                  'Please run hsp_am13x_setup script to configure the SysConfig path.'], ...
                 'SysConfig Not Configured', 'modal');
        return;
    end

    % Get SDK path for product.json
    sdkPath = getenv('COM_TI_AM13E230X_SDK_INSTALL_DIR');
    productJsonPath = '';
    if ~isempty(sdkPath)
        productJsonPath = fullfile(sdkPath, '.metadata', 'product.json');
        if ~exist(productJsonPath, 'file')
            fprintf('[WARN] product.json not found: %s\n', productJsonPath);
            productJsonPath = '';
        end
    end

    % Find SysConfig GUI executable
    if ispc()
        syscfgExe = fullfile(syscfgRoot, 'sysconfig_gui.bat');
    elseif ismac()
        syscfgExe = fullfile(syscfgRoot, 'sysconfig_gui.sh');
    else
        syscfgExe = fullfile(syscfgRoot, 'sysconfig_gui.sh');
    end

    % Verify SysConfig GUI executable exists
    if ~exist(syscfgExe, 'file')
        errordlg(sprintf(['SysConfig GUI not found at:\n%s\n\n', ...
                         'Please verify SYSCFG_ROOT is set correctly.'], syscfgExe), ...
                 'SysConfig Not Found', 'modal');
        return;
    end

    % Build command to launch SysConfig GUI
    % sysconfig_gui.bat [options] [file.syscfg]
    % Options:
    %   --product <product.json>  : Specify product metadata
    %   --output <dir>            : Output directory (not needed for GUI)
    %   --compiler <name>         : Compiler toolchain
    %   --board <name>            : Board name

    if ispc()
        if ~isempty(productJsonPath)
            % Launch with product.json and syscfg file
            launchCmd = sprintf('"%s" --product "%s" "%s"', ...
                               syscfgExe, productJsonPath, syscfgFilePath);
        else
            % Launch with just syscfg file
            launchCmd = sprintf('"%s" "%s"', ...
                               syscfgExe, syscfgFilePath);
        end
    else
        if ~isempty(productJsonPath)
            launchCmd = sprintf('"%s" --product "%s" "%s" &', ...
                               syscfgExe, productJsonPath, syscfgFilePath);
        else
            launchCmd = sprintf('"%s" "%s" &', syscfgExe, syscfgFilePath);
        end
    end

    % Launch SysConfig GUI
    fprintf('[INFO] Launching SysConfig GUI...\n');
    fprintf('[INFO] Executable: %s\n', syscfgExe);
    fprintf('[INFO] SysConfig file: %s\n', syscfgFilePath);
    if ~isempty(productJsonPath)
        fprintf('[INFO] Product JSON: %s\n', productJsonPath);
    end
    fprintf('[INFO] Command: %s\n', launchCmd);

    [status, cmdout] = system(launchCmd);

    % On Windows, 'start' command may return non-zero even on success
    if status ~= 0 && ~ispc()
        errordlg(sprintf('Failed to launch SysConfig GUI:\n%s', cmdout), ...
                 'Launch Failed', 'modal');
        return;
    end

    fprintf('[OK] SysConfig GUI launched successfully.\n');

    % Show info dialog
    msgbox(sprintf(['SysConfig GUI has been launched.\n\n', ...
                   'File: %s\n\n', ...
                   'After making changes, save the file and rebuild your model.'], ...
                   syscfgFilePath), 'SysConfig Launched', 'help');

end