function [ccsPathProvided, tiArmClangPathProvided, iarRootPathProvided] = validatePaths(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath, validateCCS, validateTiArmClang, validateIAR)
%VALIDATEPATHS Validate that all required tool paths exist
%
%   [ccsPathProvided, tiArmClangPathProvided, iarRootPathProvided] = am13x.validatePaths(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath, validateCCS, validateTiArmClang, validateIAR)
%   validates that the provided paths exist on the filesystem. Returns updated
%   boolean flags indicating which toolchains are valid. Throws warnings for
%   invalid toolchain paths when at least one valid toolchain exists. The IAR
%   ARM toolchain path is derived automatically as <iarRootPath>/arm.
%
%   Note: CCS and TI ARM CLANG are now independent. TI ARM CLANG can be used
%   without CCS for build-only functionality. CCS is required for
%   deployment and CCS project creation.
%
%   Parameters:
%       ccsPath            - Path to Code Composer Studio installation (optional)
%       tiArmClangPath     - Path to TI ARM CLANG compiler
%       iarRootPath        - Path to IAR Embedded Workbench root directory
%       mcusdkPath         - Path to AM13E230x MCU SDK installation
%       syscfgPath         - Path to SysConfig tool
%       validateCCS        - (optional) Boolean flag to validate CCS path (default: true)
%       validateTiArmClang - (optional) Boolean flag to validate TI ARM CLANG path (default: true)
%       validateIAR        - (optional) Boolean flag to validate IAR paths (default: true)
%
%   Returns:
%       ccsPathProvided         - Boolean indicating if CCS path is valid
%       tiArmClangPathProvided  - Boolean indicating if TI ARM CLANG path is valid
%       iarRootPathProvided     - Boolean indicating if IAR paths are valid
%
%   Example:
%       % Validate all paths including CCS
%       [ccsValid, tiValid, iarValid] = am13x.validatePaths('C:/ti/ccs2050', ...
%                             'C:/ti/ccs2050/ccs/tools/compiler/ti-cgt-armllvm_4.0.4.LTS', ...
%                             'C:/iar/ewarm-9.70.1', ...
%                             'C:/ti/mcu_sdk', ...
%                             'C:/ti/sysconfig_1.25.999', ...
%                             true, true, true);
%
%       % Validate TI ARM CLANG without CCS (build-only mode)
%       [ccsValid, tiValid, iarValid] = am13x.validatePaths('', ...
%                             'C:/ti/compiler/ti-cgt-armllvm_4.0.4.LTS', ...
%                             '', ...
%                             'C:/ti/mcu_sdk', ...
%                             'C:/ti/sysconfig_1.25.999', ...
%                             false, true, false);
%
%   See also: am13x.setup.getConfig, am13x.setup.setConfig

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
        error('am13e2x:validatePaths:MissingInput', ...
              'At least five paths are required.\nUsage: am13x.validatePaths(ccsPath, tiArmClangPath, iarRootPath, mcusdkPath, syscfgPath, validateCCS, validateTiArmClang, validateIAR)');
    end

    % Set default values for optional parameters
    if nargin < 6 || isempty(validateCCS)
        validateCCS = true;
    end
    if nargin < 7 || isempty(validateTiArmClang)
        validateTiArmClang = true;
    end
    if nargin < 8 || isempty(validateIAR)
        validateIAR = true;
    end

    % Convert to char if needed
    if isstring(ccsPath), ccsPath = char(ccsPath); end
    if isstring(tiArmClangPath), tiArmClangPath = char(tiArmClangPath); end
    if isstring(iarRootPath), iarRootPath = char(iarRootPath); end
    if isstring(mcusdkPath), mcusdkPath = char(mcusdkPath); end
    if isstring(syscfgPath), syscfgPath = char(syscfgPath); end

    % Track validation errors and warnings
    errors = {};
    warnings = {};
    
    % Initialize return values with input flags
    ccsPathProvided = validateCCS;
    tiArmClangPathProvided = validateTiArmClang;
    iarRootPathProvided = validateIAR;

    % Validate CCS path if requested (independent of TI ARM CLANG)
    if validateCCS
        ccsValid = true;
        
        if ~isempty(ccsPath) && ccsPath ~= ""
            if ~exist(ccsPath, 'dir')
                warnings{end+1} = sprintf('CCS installation path does not exist: %s', ccsPath);
                warnings{end+1} = 'Without CCS, only build functionality will be available (deployment and CCS project creation from Simulink not possible)';
                ccsValid = false;
            end
        else
            warnings{end+1} = 'CCS path not provided. Only build functionality will be available (deployment and CCS project creation from Simulink not possible)';
            ccsValid = false;
        end
        
        % Update the return flag
        if ~ccsValid
            ccsPathProvided = false;
        end
    end

    % Validate TI ARM CLANG path if requested (independent of CCS)
    if validateTiArmClang
        tiArmClangValid = true;
        
        if ~isempty(tiArmClangPath) && tiArmClangPath ~= ""
            if ~exist(tiArmClangPath, 'dir')
                warnings{end+1} = sprintf('TI ARM CLANG compiler path does not exist: %s', tiArmClangPath);
                tiArmClangValid = false;
            end
        else
            warnings{end+1} = 'TI ARM CLANG path is required for TI ARM CLANG toolchain';
            tiArmClangValid = false;
        end
        
        % Update the return flag
        if ~tiArmClangValid
            tiArmClangPathProvided = false;
        end
    end

    % Validate IAR paths if requested
    if validateIAR
        iarValid = true;
        
        % Validate IAR Root path
        if ~isempty(iarRootPath) && iarRootPath ~= ""
            if ~exist(iarRootPath, 'dir')
                warnings{end+1} = sprintf('IAR root path does not exist: %s', iarRootPath);
                iarValid = false;
            else
                % Derive IAR ARM path from root path
                iarArmPath = fullfile(iarRootPath, 'arm');

                % Validate IAR ARM path
                if ~exist(iarArmPath, 'dir')
                    warnings{end+1} = sprintf('IAR ARM toolchain path does not exist: %s', iarArmPath);
                    iarValid = false;
                else
                    % Check for iccarm.exe compiler
                    iccarmPath = fullfile(iarArmPath, 'bin', 'iccarm.exe');
                    if ~exist(iccarmPath, 'file')
                        warnings{end+1} = sprintf('IAR ARM compiler (iccarm.exe) not found at: %s', iccarmPath);
                        iarValid = false;
                    end
                end
            end
        else
            warnings{end+1} = 'IAR root path is required when validating IAR toolchain';
            iarValid = false;
        end
        
        % Update the return flag
        if ~iarValid
            iarRootPathProvided = false;
        end
    end

    % Validate MCU SDK path (always required - error if invalid)
    if ~exist(mcusdkPath, 'dir')
        errors{end+1} = sprintf('MCU SDK installation path does not exist: %s', mcusdkPath);
    end

    % Validate SysConfig path (always required - error if invalid)
    if ~exist(syscfgPath, 'dir')
        errors{end+1} = sprintf('SysConfig installation path does not exist: %s', syscfgPath);
    end

    % Check if at least one toolchain is valid
    atLeastOneToolchainValid = tiArmClangPathProvided || iarRootPathProvided;
    
    % If no valid toolchain, convert warnings to errors (except CCS warnings)
    if ~atLeastOneToolchainValid && ~isempty(warnings)
        % Separate CCS warnings from toolchain warnings
        ccsWarnings = {};
        toolchainWarnings = {};
        for i = 1:length(warnings)
            if contains(warnings{i}, 'CCS') || contains(warnings{i}, 'build functionality')
                ccsWarnings{end+1} = warnings{i};
            else
                toolchainWarnings{end+1} = warnings{i};
            end
        end
        errors = [errors, toolchainWarnings];
        warnings = ccsWarnings;
    end

    % Display warnings if any
    if ~isempty(warnings)
        fprintf('\n');
        fprintf('========================================\n');
        fprintf('PATH VALIDATION WARNINGS\n');
        fprintf('========================================\n');
        for i = 1:length(warnings)
            fprintf('  %d. %s\n', i, warnings{i});
        end
        fprintf('\n');
        
        % Provide actionable guidance based on which toolchain failed
        if ~tiArmClangPathProvided && iarRootPathProvided
            fprintf('TI ARM CLANG toolchain will be DISABLED.\n');
            fprintf('Setup will continue using IAR toolchain only.\n');
            fprintf('\nTo enable TI ARM CLANG toolchain:\n');
            fprintf('  - Verify TI ARM CLANG compiler is installed\n');
            fprintf('  - Provide the correct TI ARM CLANG compiler path\n');
            fprintf('  - Optionally provide CCS path for deployment and CCS project creation\n');
            fprintf('  - Re-run setup with corrected paths\n');
        elseif tiArmClangPathProvided && ~iarRootPathProvided
            fprintf('IAR toolchain will be DISABLED.\n');
            fprintf('Setup will continue using TI ARM CLANG toolchain only.\n');
            if ~ccsPathProvided
                fprintf('Note: CCS not provided - build-only mode (no deployment and CCS project creation).\n');
            end
            fprintf('\nTo enable IAR toolchain:\n');
            fprintf('  - Verify IAR Embedded Workbench is installed\n');
            fprintf('  - Provide the correct IAR root path (not the ARM subfolder)\n');
            fprintf('  - Ensure iccarm.exe exists in <IARRootPath>/arm/bin/\n');
            fprintf('  - Re-run setup with corrected paths\n');
        end
        fprintf('========================================\n\n');
    end

    % If there are errors, throw them
    if ~isempty(errors)
        errorMsg = sprintf('Path validation failed:\n');
        for i = 1:length(errors)
            errorMsg = sprintf('%s  %d. %s\n', errorMsg, i, errors{i});
        end
        errorMsg = sprintf('%s\nPlease verify that all tools are installed at the specified paths.', errorMsg);
        error('am13e2x:validatePaths:InvalidPaths', '%s', errorMsg);
    end

    fprintf('Path validation completed successfully\n');

end