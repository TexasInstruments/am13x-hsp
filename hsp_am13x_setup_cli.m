function hsp_am13x_setup_cli(options)
% HSP_AM13X_SETUP_CLI Command-line setup using paths from config or arguments
%
%   hsp_am13x_setup_cli() performs an automated installation of the
%   AM13x Target, peripheral device driver blocks, and toolchain using the
%   default paths stored in hsp_am13x_config.json. This function is designed
%   for automation and command-line usage without user prompts.
%
%   hsp_am13x_setup_cli(Name=Value) allows overriding specific paths using
%   named parameters. Only the specified paths will be overridden; others
%   will be loaded from the configuration file.
%
%   Parameters (all optional):
%       CCSPath         - Path to Code Composer Studio installation
%       TIARMClangPath  - Path to TI ARM CLANG compiler
%       IARRootPath     - Path to IAR Embedded Workbench root directory
%                         (the ARM toolchain path is derived automatically as <IARRootPath>/arm)
%       MCUSDKPath      - Path to AM13E230x MCU SDK installation
%       SysConfigPath   - Path to SysConfig tool
%
%   Examples:
%       % Use all default paths from config
%       hsp_am13x_setup_cli
%
%       % Override only SDK path
%       hsp_am13x_setup_cli(MCUSDKPath='C:/ti/new_sdk')
%
%       % Override multiple paths
%       hsp_am13x_setup_cli(CCSPath='C:/ti/ccs2050', MCUSDKPath='C:/ti/mcu_sdk')
%
%       % Override all paths
%       hsp_am13x_setup_cli(CCSPath='C:/ti/ccs2050', ...
%                           TIARMClangPath='C:/ti/compiler', ...
%                           IARRootPath='C:/iar/ewarm-9.70.1', ...
%                           MCUSDKPath='C:/ti/sdk', ...
%                           SysConfigPath='C:/ti/syscfg')
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

% Parse input arguments with named parameters
arguments
    options.CCSPath (1,1) string = ""
    options.TIARMClangPath (1,1) string = ""
    options.IARRootPath (1,1) string = ""
    options.MCUSDKPath (1,1) string = ""
    options.SysConfigPath (1,1) string = ""
end

disp('HSP AM13x setup...');

% Get path of this file (same as target path)
tmp_Fullpath = mfilename('fullpath');
[tgtDir, ~] = fileparts(tmp_Fullpath);

% Validate path for spaces (which causes errors when compiling source code inside target folder)
if ~contains(tgtDir,' ')
    disp('Path validation: Success!');
else
    disp('Path validation: Failed.');
    prepare_am13x_hsp_install();
    error('hsp_am13x:invalidPath', ...
        'Installation path contains spaces: %s\nPlease follow the steps above and reinstall.', tgtDir);
end

% Add paths to the MATLAB environment using helper function
addHSPPaths(tgtDir);

try
    config = am13x.setup.getConfig();
    disp('JSON Configuration loaded successfully');
catch ME
    fprintf('Failed to load configuration file: %s\n', ME.message);
    config = struct();
end

% Extract paths from options, fill any missing pieces with default config paths
if options.CCSPath ~= ""
    ccsPath = char(options.CCSPath);
elseif isfield(config, 'ccs_install_path')
    ccsPath = config.ccs_install_path;
else
    ccsPath = "";
    warning('CCS path not provided. Only build functionality will be available. Debug and load features require CCS installation.');
end

if options.TIARMClangPath ~= ""
    tiArmClangPath = char(options.TIARMClangPath);
elseif isfield(config, 'ti_arm_clang_path')
    tiArmClangPath = config.ti_arm_clang_path;
else
    tiArmClangPath = "";
end

if options.IARRootPath ~= ""
    iarRootPath = char(options.IARRootPath);
elseif isfield(config, 'iar_root_path')
    iarRootPath = config.iar_root_path;
else
    iarRootPath = "";
end

if options.MCUSDKPath ~= ""
    mcusdkPath = char(options.MCUSDKPath);
elseif isfield(config, 'mcusdk_install_path')
    mcusdkPath = config.mcusdk_install_path;
else
    error('mcu sdk path must be provided either as input, or from the configuration file, hsp_am13x_config.json');
end

if options.SysConfigPath ~= ""
    syscfgPath = char(options.SysConfigPath);
elseif isfield(config, 'syscfg_install_path')
    syscfgPath = config.syscfg_install_path;
else
    error('sysconfig path must be provided either as input, or from the configuration file, hsp_am13x_config.json');
end

% Check if all necessary paths are provided
ccsPathProvided = (ccsPath ~= "");
tiArmClangPathProvided = (tiArmClangPath ~= "");
iarRootPathProvided = (iarRootPath ~= "");
atleastOneToolchainPathsProvided = tiArmClangPathProvided || iarRootPathProvided;

if ~atleastOneToolchainPathsProvided
    error('At least one toolchain related paths not available. \nPlease run hsp_am13x_setup first to create the configuration\n Or provide all required paths as arguments in hsp_am13x_setup_cli');
end

% Validate that the paths exist and get updated boolean flags
try
    [ccsPathProvided, tiArmClangPathProvided, iarRootPathProvided] = am13x.setup.validatePaths(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath, ccsPathProvided, tiArmClangPathProvided, iarRootPathProvided);
catch ME
    error(ME.identifier, 'Setup failed due to invalid paths provided: %s', ME.message);
end

% Clear invalid paths based on updated boolean flags
if ~ccsPathProvided
    ccsPath = "";
end

if ~tiArmClangPathProvided
    tiArmClangPath = "";
end

if ~iarRootPathProvided
    iarRootPath = "";
end

% Save the paths to configuration file for future use
try
    am13x.setup.setConfig(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath);
catch ME
    warning(ME.identifier, 'Could not save configuration: %s', ME.message);
end

% Display loaded paths
disp('Using the following paths:');
fprintf('  MCU SDK:         %s\n', mcusdkPath);
fprintf('  SysConfig:       %s\n', syscfgPath);

% Display CCS path separately (optional for debug/load features)
if ccsPathProvided
    fprintf('  CCS Path:        %s\n', ccsPath);
else
    fprintf('  CCS Path:        Not provided (build-only mode)\n');
end

if tiArmClangPathProvided
    tool_install_path = {
        ccsPath;
        tiArmClangPath;
        mcusdkPath;
        syscfgPath
        };

    % Display TI ARM CLANG path
    fprintf('  TI ARM CLANG:    %s\n', tiArmClangPath);

    % Save tool paths as .mat files
    save(fullfile(tgtDir, 'toolchain', 'am13x', '+matlabshared', '+toolchain', '+ti_arm_clang', 'tool_install_paths.mat'), "tool_install_path");
end

if iarRootPathProvided
    % Derive IAR ARM path from root path
    iarArmPath = fullfile(iarRootPath, 'arm');

    tool_install_path_iar = {
        iarRootPath;
        iarArmPath;
        mcusdkPath;
        syscfgPath
        };

    % Display loaded paths
    fprintf('  IAR Root:        %s\n', tool_install_path_iar{1});
    fprintf('  IAR ARM:         %s (derived)\n', tool_install_path_iar{2});

    % Save tool paths as .mat files
    save(fullfile(tgtDir, 'toolchain', 'am13x', '+matlabshared', '+toolchain', '+iar_arm', 'tool_install_paths_iar.mat'), "tool_install_path_iar");
end

% Setup CCS and IAR environment variables using helper function
if tiArmClangPathProvided && iarRootPathProvided
    setupEnvironmentVariables(tgtDir, tool_install_path, tool_install_path_iar, tiArmClangPathProvided, iarRootPathProvided, mcusdkPath, syscfgPath);
elseif tiArmClangPathProvided
    setupEnvironmentVariables(tgtDir, tool_install_path, [], tiArmClangPathProvided, iarRootPathProvided, mcusdkPath, syscfgPath);
elseif iarRootPathProvided
    setupEnvironmentVariables(tgtDir, [], tool_install_path_iar, tiArmClangPathProvided, iarRootPathProvided, mcusdkPath, syscfgPath);
end

%Save the paths added to the MATLAB environment
savepath;

%Refresh to let the target be discovered (take effect) in the same MATLAB session
warning('off', 'RTW:targetRegistry:errEvalrtwTargetInfo');
sl_refresh_customizations;
warning('on', 'RTW:targetRegistry:errEvalrtwTargetInfo');


fprintf('\nActive toolchains: ');
if tiArmClangPathProvided && iarRootPathProvided
    fprintf('TI ARM CLANG, IAR\n');
elseif tiArmClangPathProvided
    fprintf('TI ARM CLANG only\n');
else
    fprintf('IAR only\n');
end

fprintf('\nSetup complete! To get started, explore the example models in the /examples/ folder.\n');

end

%% Helper function to add HSP paths to the MATLAB environment
function addHSPPaths(tgtDir)
% Add paths to the MATLAB environment !

addpath(tgtDir);
addpath(fullfile(tgtDir, 'registry'));
addpath(fullfile(tgtDir, 'src'));
addpath(genpath(fullfile(tgtDir, 'blocks')));
addpath(genpath(fullfile(tgtDir, 'examples')));
addpath(genpath(fullfile(tgtDir, 'toolchain')));
addpath(genpath(fullfile(tgtDir, 'doc')));
addpath(fullfile(tgtDir, 'code_replacement'));
disp('Installed TI ARM CLANG and IAR ARM toolchains!');

setpref('AM13xPILpref','COMport', 'COM1');
setpref('AM13xPILpref','Baud', '115200');
setpref('AM13xPILpref', 'PILHardware', 'AM13E230X');

setpref('MultiCore', 'Core', 'Core0');

end

%% Helper function to setup environment variables
function setupEnvironmentVariables(tgtDir, tool_install_path, tool_install_path_iar, tiArmClangPathProvided, iarRootPathProvided, mcusdkPath, syscfgPath)
disp('Setting up environment variables...');

% Normalize path helper: ensure char type and forward slashes
normalize = @(p) convertStringsToChars(strrep(string(p), '\', '/'));

% Normalize common paths
sdkPath = normalize(mcusdkPath);
syscfgPathNorm = normalize(syscfgPath);

% Derived paths from SDK
linkerPath = normalize(fullfile(sdkPath, 'ti_sdk_config', 'am13e230x', 'default'));
tmuPath = normalize(fullfile(sdkPath, 'source', 'mathlib', 'fastrts'));
halUARTPath = normalize(fullfile(sdkPath, 'source', 'hal', 'am13e230x', 'include'));
halCfgPath = normalize(fullfile(sdkPath, 'ti_sdk_config', 'am13e230x', 'default', 'Hal_Cfg'));

% ----------------------------------------------------------------
% Single source-of-truth: all environment variable name/value pairs.
% Both setenv (current session) and setx (batch file) are driven from
% this one table, so they are always identical.
% ----------------------------------------------------------------
envVars = {
    'MCUSDKINSTALLDIR',                 sdkPath;
    'COM_TI_AM13E230X_SDK_INSTALL_DIR', sdkPath;
    'TI_BUILD',                         normalize(fullfile(sdkPath, 'build', 'am13e230x', 'lib', 'Release'));
    'MCUSDK_INCLUDE',                   normalize(fullfile(sdkPath, 'source'));
    'CMSISCORE_INCLUDE',                normalize(fullfile(sdkPath, 'source', 'cmsis', 'Core', 'Include'));
    'CMSISDSP_INCLUDE',                 normalize(fullfile(sdkPath, 'source', 'cmsis', 'DSP', 'Include'));
    'DEVICE_HW_INCLUDE',                normalize(fullfile(sdkPath, 'source', 'device', 'am13e230x', 'include', 'hw'));
    'DRIVERLIB_INCLUDE',                normalize(fullfile(sdkPath, 'source', 'driverlib', 'am13e230x'));
    'TMU_INCLUDE',                      tmuPath;
    'HAL_INCLUDE',                      halUARTPath;
    'HALCFG_INCLUDE',                   halCfgPath;
    'LINKERCMDDIR',                     linkerPath;
    'LINKER_CMD_DIR',                   linkerPath;
    'SYSCFG_ROOT',                      syscfgPathNorm;
    };

% Add TI ARM CLANG environment variables if provided
if tiArmClangPathProvided
    ccsPath = normalize(tool_install_path{1});
    tiArmClangPath = normalize(tool_install_path{2});

    tiVars = {
        'CCSARMINSTALLDIR', tiArmClangPath;
        'TI_TOOLS',         normalize(fullfile(tiArmClangPath, 'bin'));
        'TI_INCLUDE',       normalize(fullfile(tiArmClangPath, 'include'));
        'TI_LIB',           normalize(fullfile(tiArmClangPath, 'lib'));
        };

    % Add CCS root only if provided
    if ~isempty(ccsPath) && ccsPath ~= ""
        tiVars = [{'CCSROOT', ccsPath}; tiVars];
    end

    envVars = [envVars; tiVars];
    disp('  - TI ARM CLANG environment variables configured');
end

% Add IAR environment variables if provided
if iarRootPathProvided
    iarRootPath = normalize(tool_install_path_iar{1});
    iarArmPath = normalize(tool_install_path_iar{2});

    iarVars = {
        'IARROOT',          iarRootPath;
        'IARARMINSTALLDIR', iarArmPath;
        };
    envVars = [envVars; iarVars];
    disp('  - IAR environment variables configured');
end

% Apply all variables to the current MATLAB session
for i = 1 : size(envVars, 1)
    setenv(envVars{i,1}, envVars{i,2});
end

% Write batch file so the same variables persist across Windows sessions
setenvFile = fullfile(tgtDir, 'mwsetenv.bat');
fd = fopen(setenvFile, 'w+');
for i = 1 : size(envVars, 1)
    fprintf(fd, 'setx %s "%s"\n', envVars{i,1}, envVars{i,2});
end
fclose(fd);

% Execute the batch file to persist the variables system-wide
[~, ~] = system(['"', setenvFile, '"']);
disp('Environment variables applied to current MATLAB session and persisted via mwsetenv.bat.');
disp('Note: setx changes only take effect in new processes; restart MATLAB to read them back via getenv().');
end


%% =========================================================================
% prepare_am13x_hsp_install
% Run this ONCE before installing the .mltbx to ensure the Add-Ons
% installation folder has no spaces in its path.
% ==========================================================================
function prepare_am13x_hsp_install()
% PREPARE_AM13X_HSP_INSTALL  Run this before installing the .mltbx.
%   Prints instructions to set the Add-Ons installation folder to a
%   path without spaces, required for code generation toolchains.

fprintf('=============================================================\n');
fprintf('  AM13x HSP - Pre-Install Checklist\n');
fprintf('=============================================================\n\n');
fprintf('IMPORTANT: The Add-Ons installation folder must NOT contain spaces.\n');
fprintf('The default MATLAB path (AppData\\...\\MATLAB Add-Ons) contains\n');
fprintf('spaces and will cause build failures in code generation toolchains.\n\n');
fprintf('Steps before installing the .mltbx:\n\n');
fprintf('  Step 1. In MATLAB go to:\n');
fprintf('          Settings -> MATLAB -> Add-Ons\n');
fprintf('          Set "Installation Folder" to a path WITHOUT spaces\n');
fprintf('          e.g. C:\\ti\\matlab_addons\n\n');
fprintf('  Step 2. Install the package by double-clicking the .mltbx file\n');
fprintf('          in the MATLAB Current Folder browser, or run:\n');
fprintf('          matlab.internal.open.openmltbx(''<path_to_am13x_hsp_xx.x.x.mltbx>'')\n\n');
fprintf('  Step 3. Run setup:\n');
fprintf('          hsp_am13x_setup\n\n');
fprintf('=============================================================\n');

end % function prepare_am13x_hsp_install
