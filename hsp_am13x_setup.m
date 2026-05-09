function hsp_am13x_setup

% Function to install AM13x Target, peripheral device driver blocks and
% toolchain

%  Copyright (C) 2025-2026 Texas Instruments Incorporated
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

% Load default paths from configuration file (create if doesn't exist)

try
    config = am13x.setup.getConfig();
    useDefaults = false;
    fprintf('Loaded default paths from configuration file\n');
catch
    useDefaults = true;
    fprintf('INFO: hsp_am13x_config.json file that stores recently used paths not found.\n');
end

% Auto-detect installed tools if no config exists or paths are missing
detectedPaths = struct();
if useDefaults
    fprintf('Scanning system for installed tools...\n');
    try
        detector = am13x.setup.detectEmbeddedTools();
        detector.detect();
        results = detector.getResults();

        % Extract first detected path for each tool (if available)
        if ~isempty(results.ccs)
            detectedPaths.ccs = results.ccs(1).location;
            fprintf('  Found CCS: %s\n', detectedPaths.ccs);
        end

        if ~isempty(results.tiClang)
            detectedPaths.tiClang = results.tiClang(1).location;
            fprintf('  Found TI ARM CLANG: %s\n', detectedPaths.tiClang);
        end

        if ~isempty(results.iar)
            detectedPaths.iar = results.iar(1).location;
            fprintf('  Found IAR: %s\n', detectedPaths.iar);
        end

        if ~isempty(results.am13x)
            detectedPaths.am13x = results.am13x(1).location;
            fprintf('  Found AM13x SDK: %s\n', detectedPaths.am13x);
        end

        if ~isempty(results.sysconfig)
            detectedPaths.sysconfig = results.sysconfig(1).location;
            fprintf('  Found SysConfig: %s\n', detectedPaths.sysconfig);
        end

        fprintf('Auto-detection complete.\n');
    catch ME
        fprintf('Warning: Auto-detection failed: %s\n', ME.message);
        fprintf('Using hardcoded default paths as fallback.\n');
    end
end

% Set default values for each path with priority:
% 1. Config file (if exists and not empty)
% 2. Auto-detected paths (if available)
% 3. Hardcoded fallback paths

if useDefaults || isempty(config.ccs_install_path) || config.ccs_install_path == ""
    if isfield(detectedPaths, 'ccs')
        defaultCCS = detectedPaths.ccs;
    else
        defaultCCS = 'C:\ti\ccs2050';
    end
else
    defaultCCS = config.ccs_install_path;
end

if useDefaults || isempty(config.ti_arm_clang_path) || config.ti_arm_clang_path == ""
    if isfield(detectedPaths, 'tiClang')
        defaultClang = detectedPaths.tiClang;
    else
        defaultClang = 'C:\ti\ccs2050\ccs\tools\compiler\ti-cgt-armllvm_4.0.4.LTS';
    end
else
    defaultClang = config.ti_arm_clang_path;
end

if useDefaults || isempty(config.iar_root_path) || config.iar_root_path == ""
    if isfield(detectedPaths, 'iar')
        defaultIARRoot = detectedPaths.iar;
    else
        defaultIARRoot = 'C:\iar\ewarm-9.70.1';
    end
else
    defaultIARRoot = config.iar_root_path;
end

if useDefaults || isempty(config.mcusdk_install_path) || config.mcusdk_install_path == ""
    if isfield(detectedPaths, 'am13x')
        defaultSDK = detectedPaths.am13x;
    else
        defaultSDK = 'C:\ti\am13e230x_sdk_26_00_00_06';
    end
else
    defaultSDK = config.mcusdk_install_path;
end

if useDefaults || isempty(config.syscfg_install_path) || config.syscfg_install_path == ""
    if isfield(detectedPaths, 'sysconfig')
        defaultSyscfg = detectedPaths.sysconfig;
    else
        defaultSyscfg = 'C:\ti\sysconfig_1.27.0';
    end
else
    defaultSyscfg = config.syscfg_install_path;
end

% Get tool paths and save as mat file inside target folder
prompt =   {'Enter CCS installated path (e.g. C:\ti\ccs2050):',...
    'Enter TI ARM CLANG compiler installated path (e.g. C:\ti\ccs2050\ccs\tools\compiler\ti-cgt-armllvm_4.0.4.LTS):',...
    'Enter IAR Embedded Workbench root path (e.g. C:\iar\ewarm-9.70.1):',...
    'Enter AM13E230x MCUSDK installated path (e.g. C:\ti\am13e230x_sdk_26_00_00_06):',...
    'Enter SysConfig installated path (e.g. C:\ti\sysconfig_1.27.0):',...
    ' '};
dlgtitle = 'Setup AM13x HSP';
fieldsize = [1 100; 1 100; 1 100; 1 100; 1 100; 5 100];
definput = {defaultCCS, ...
    defaultClang, ...
    defaultIARRoot, ...
    defaultSDK,...
    defaultSyscfg,...
    'Note: Upon first setup, an hsp_am13x_config.json configuration file will be created containing your specified installation paths. For subsequent use, you can customize this file to match your device paths and tool versions. For automated setup without prompts, use hsp_am13x_setup_cli.m.'};
tool_install_path = inputdlg(prompt,dlgtitle,fieldsize,definput);

if isempty(tool_install_path)
    disp('Setup cancelled by user.');
else

    % Call the CLI setup function with the provided paths
    % This handles validation, saving config, setting env vars, adding paths, etc.
    try
        hsp_am13x_setup_cli('CCSPath', tool_install_path{1}, ...
            'TIARMClangPath', tool_install_path{2}, ...
            'IARRootPath', tool_install_path{3}, ...
            'MCUSDKPath', tool_install_path{4}, ...
            'SysConfigPath', tool_install_path{5});
    catch ME
        error('Setup failed: %s\n you need to re run the hsp_am13x_setup.m or hsp_am13x_setup_cli.m again to use the HSP\n', ME.message);
    end
end
end