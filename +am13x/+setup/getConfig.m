function config = getConfig()
%GETCONFIG Load configuration from JSON file
%
%   config = am13x.setup.getConfig() loads the HSP configuration from the
%   hsp_am13x_config.json file. Returns a structure with the configuration
%   paths. Empty strings ("") are returned for optional toolchain paths that
%   were not configured.
%
%   Returns:
%       config - Structure containing configuration paths:
%                .ccs_install_path (may be empty string if not configured)
%                .ti_arm_clang_path (may be empty string if not configured)
%                .iar_root_path (may be empty string if not configured)
%                .mcusdk_install_path
%                .syscfg_install_path
%
%   Example:
%       config = am13x.setup.getConfig();
%       if ~isempty(config.ccs_install_path) && config.ccs_install_path ~= ""
%           fprintf('CCS Path: %s\n', config.ccs_install_path);
%       end
%
%   See also: am13x.setup.setConfig

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

% Get the HSP root directory using the existing utility function
hspDir = am13x.getTargetRoot();

% Path to config file
configFile = fullfile(hspDir, 'hsp_am13x_config.json');

% Check if config file exists
if ~exist(configFile, 'file')
    error('am13x:getConfig:FileNotFound', ...
        'Configuration file not found: %s\n', configFile);
end

try
    % Read JSON file
    fid = fopen(configFile, 'r');
    if fid == -1
        error('am13x:getConfig:CannotOpen', ...
            'Cannot open configuration file: %s', configFile);
    end

    rawData = fread(fid, inf, 'char=>char')';
    fclose(fid);

    % Parse JSON
    jsonData = jsondecode(rawData);

    % Extract paths, handling missing or empty fields gracefully

    % CCS path (optional)
    if isfield(jsonData.paths, 'ccs_install_path')
        config.ccs_install_path = jsonData.paths.ccs_install_path;
    else
        config.ccs_install_path = "";
    end

    % TI ARM CLANG path (optional)
    if isfield(jsonData.paths, 'ti_arm_clang_path')
        config.ti_arm_clang_path = jsonData.paths.ti_arm_clang_path;
    else
        config.ti_arm_clang_path = "";
    end

    % IAR root path (optional)
    if isfield(jsonData.paths, 'iar_root_path')
        config.iar_root_path = jsonData.paths.iar_root_path;
    else
        config.iar_root_path = "";
    end

    % Derive IAR ARM path from root path only if IAR root path is provided
    if ~isempty(config.iar_root_path) && config.iar_root_path ~= ""
        config.iar_arm_path = fullfile(config.iar_root_path, 'arm');
    else
        config.iar_arm_path = "";
    end

    % MCU SDK path (required)
    if isfield(jsonData.paths, 'mcusdk_install_path')
        config.mcusdk_install_path = jsonData.paths.mcusdk_install_path;
    else
        error('am13x:getConfig:MissingField', 'Required field mcusdk_install_path not found in configuration file');
    end

    % SysConfig path (required)
    if isfield(jsonData.paths, 'syscfg_install_path')
        config.syscfg_install_path = jsonData.paths.syscfg_install_path;
    else
        error('am13x:getConfig:MissingField', 'Required field syscfg_install_path not found in configuration file');
    end

catch ME
    error('am13x:getConfig:ParseError', ...
        'Failed to parse configuration file: %s', ME.message);
end

end