function setConfig(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath)
%SETCONFIG Save configuration to JSON file
%
%   am13x.setup.setConfig(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath)
%   saves the provided paths to the hsp_am13x_config.json file for future use.
%   Empty strings ("") can be provided for optional toolchain paths (CCS, TI ARM CLANG, IAR).
%   The IAR ARM toolchain path is derived automatically as <iarRootPath>/arm.
%
%   Parameters:
%       ccsPath         - Path to Code Composer Studio installation (can be "" if not used)
%       tiArmClangPath  - Path to TI ARM CLANG compiler (can be "" if not used)
%       iarRootPath     - Path to IAR Embedded Workbench root directory (can be "" if not used)
%       mcusdkPath      - Path to AM13x MCU SDK installation (required)
%       syscfgPath      - Path to SysConfig tool (required)
%
%   Example:
%       % Save all paths
%       am13x.setup.setConfig('C:/ti/ccs2050', ...
%                          'C:/ti/ccs2050/ccs/tools/compiler/ti-cgt-armllvm_4.0.4.LTS', ...
%                          'C:/iar/ewarm-9.70.1', ...
%                          'C:/ti/mcu_sdk', ...
%                          'C:/ti/sysconfig_1.25.999');
%
%       % Save only TI ARM CLANG paths (no IAR)
%       am13x.setup.setConfig('C:/ti/ccs2050', ...
%                          'C:/ti/ccs2050/ccs/tools/compiler/ti-cgt-armllvm_4.0.4.LTS', ...
%                          '', ...
%                          'C:/ti/mcu_sdk', ...
%                          'C:/ti/sysconfig_1.25.999');
%
%   See also: am13x.setup.getConfig

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
    if nargin < 5
        error('am13x:setConfig:MissingInput', ...
              'All five paths are required.\nUsage: am13x.setup.setConfig(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath)');
    end

    % Convert to char if needed, preserving empty strings
    if isstring(ccsPath), ccsPath = char(ccsPath); end
    if isstring(tiArmClangPath), tiArmClangPath = char(tiArmClangPath); end
    if isstring(iarRootPath), iarRootPath = char(iarRootPath); end
    if isstring(mcusdkPath), mcusdkPath = char(mcusdkPath); end
    if isstring(syscfgPath), syscfgPath = char(syscfgPath); end

    % Get the HSP root directory using the existing utility function
    hspDir = am13x.getTargetRoot();

    % Path to config file
    configFile = fullfile(hspDir, 'hsp_am13x_config.json');

    % Create configuration structure
    config.version = '1.0.0';
    config.description = 'Default configuration paths for AM13x HSP setup';
    config.paths.ccs_install_path = char(ccsPath);
    config.paths.ti_arm_clang_path = char(tiArmClangPath);
    config.paths.iar_root_path = char(iarRootPath);
    config.paths.mcusdk_install_path = char(mcusdkPath);
    config.paths.syscfg_install_path = char(syscfgPath);
    config.notes.ccs_install_path = 'Path to Code Composer Studio installation directory';
    config.notes.ti_arm_clang_path = 'Path to TI ARM CLANG compiler directory';
    config.notes.iar_root_path = 'Path to IAR Embedded Workbench root directory (the ARM toolchain path is derived automatically as <iar_root_path>/arm)';
    config.notes.mcusdk_install_path = 'Path to AM13x MCU SDK installation directory';
    config.notes.syscfg_install_path = 'Path to SysConfig tool (used for generating peripheral configuration files from .syscfg files)';

    try
        % Convert to JSON with pretty formatting
        jsonStr = jsonencode(config);

        % Pretty print JSON (add indentation)
        jsonStr = strrep(jsonStr, ',', sprintf(',\n  '));
        jsonStr = strrep(jsonStr, '{', sprintf('{\n  '));
        jsonStr = strrep(jsonStr, '}', sprintf('\n}'));

        % Write to file
        fid = fopen(configFile, 'w');
        if fid == -1
            error('am13x:setConfig:CannotOpen', ...
                  'Cannot open configuration file for writing: %s', configFile);
        end

        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        fprintf('Configuration saved to: %s\n', configFile);

    catch ME
        error('am13x:setConfig:WriteFailed', ...
              'Failed to save configuration: %s', ME.message);
    end

end