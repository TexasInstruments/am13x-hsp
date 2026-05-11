function generateSyscfgFiles(hCS, buildInfo)
%GENERATESYSCFGFILES Generate configuration files from .syscfg file
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
%   This function searches for a .syscfg file in the example directory
%   and generates the corresponding ti_sdk_dl_config.c and .h files
%   using the SysConfig CLI tool.

    fprintf('\n### SysConfig File Generation\n');

    % Get model name from configuration set handle
    modelName = get_param(getModel(hCS), 'Name');

    % Get build directory
    BuildDir = RTW.getBuildDir(modelName);
    buildDirectory = BuildDir.BuildDirectory;
    if isequal('RTW', get_param(modelName, 'ModelReferenceTargetType'))
        buildDirectory = fullfile(BuildDir.CodeGenFolder, BuildDir.ModelRefRelativeBuildDir);
    end

    fprintf('Model Name: %s\n', modelName);
    fprintf('Build Directory: %s\n', buildDirectory);

    fprintf('\nLocating .slx model file...\n');

    % Get the .slx file location
    % Try to get the model file path from the model itself
    slxFile = '';
    try
        slxFile = get_param(modelName, 'FileName');
        fprintf('### Model file: %s\n', slxFile);
    catch
        fprintf('Warning: Could not determine model file location.\n');
    end

    % Determine the model directory (where the .slx file is located)
    modelDir = '';
    if ~isempty(slxFile)
        [modelDir, ~, ~] = fileparts(slxFile);
        fprintf('### Model directory: %s\n', modelDir);
    end

    fprintf('\nRetrieving SysConfig file path from Build options...\n');

    % Get the SysConfig file path from the model parameter
    cs = getActiveConfigSet(modelName);
    syscfgFile = codertarget.data.getParameterValue(cs, 'SysConfig.ProjectFile');

    fprintf('### Using SysConfig file: %s\n', syscfgFile);

    % The syscfgFile might be relative (e.g., "./config.syscfg")
    % Resolve the potentially relative path to the ansolute path before passing to SysConfig CLI
    if ~isempty(modelDir)
        try
            resolvedSyscfgFile = am13x.parameters.resolveSyscfgPath(syscfgFile, modelName);
            if ~strcmp(syscfgFile, resolvedSyscfgFile)
                fprintf('### Resolved to absolute path: %s\n', resolvedSyscfgFile);
            end
            syscfgFile = resolvedSyscfgFile;
        catch ME
            fprintf('Warning: Could not resolve SysConfig path: %s\n', ME.message);
            fprintf('Using path as-is: %s\n', syscfgFile);
        end
    end
    % copy *.syscfg file to codegen dir
    [~, name, ext] = fileparts(syscfgFile);
    syscfgFileName = [name, ext];
    destFileName = fullfile(buildDirectory, syscfgFileName);
    if ~exist(destFileName, 'file')
        % if not exist copy
        copyfile(syscfgFile, destFileName);
    else
        % if exist remove and perform fresh copy to point to latest
        delete(destFileName);
        copyfile(syscfgFile, destFileName);
    end


    fprintf('\n### Locating Tools\n');

    % Get required environment variables and paths
    sdkPath = getenv('COM_TI_AM13E230X_SDK_INSTALL_DIR');
    if isempty(sdkPath)
        error('COM_TI_AM13E230X_SDK_INSTALL_DIR environment variable is not set.');
    end
    fprintf('### SDK Path: %s\n', sdkPath);

    % Find SysConfig installation
    syscfgRoot = getenv('SYSCFG_ROOT');
    if isempty(syscfgRoot)
        error('SYSCFG_ROOT environment variable is not set. Please run hsp_am13x_setup to configure the SysConfig path.');
    end
    fprintf('### SysConfig Root: %s\n', syscfgRoot);

    % Derive Node.js path from SysConfig root directory
    syscfgNodePath = fullfile(syscfgRoot, 'nodejs', 'node.exe');

    % Verify Node.js executable exists
    if ~exist(syscfgNodePath, 'file')
        error('Node.js executable not found at: %s\nPlease verify your SysConfig installation includes the nodejs subdirectory.', syscfgNodePath);
    end
    fprintf('### Node.js: %s\n', syscfgNodePath);

    % Construct SysConfig CLI path
    syscfgCliPath = fullfile(syscfgRoot, 'dist', 'cli.js');
    if ~exist(syscfgCliPath, 'file')
        error('SysConfig CLI not found at: %s\nPlease verify your SysConfig installation.', syscfgCliPath);
    end
    fprintf('### SysConfig CLI: %s\n', syscfgCliPath);

    % Construct product.json path
    productJsonPath = fullfile(sdkPath, '.metadata', 'product.json');
    if ~exist(productJsonPath, 'file')
        error('product.json not found at: %s', productJsonPath);
    end
    fprintf('### Product JSON: %s\n', productJsonPath);

    % Create output directory in the build folder
    outputDir = buildDirectory;

    % Construct the SysConfig command
    % Format: node cli.js --product <product.json> --output <output_dir> <input.syscfg>
    syscfgCommand = sprintf('"%s" "%s" --product "%s" --output "%s" "%s"', ...
        syscfgNodePath, ...
        syscfgCliPath, ...
        productJsonPath, ...
        outputDir, ...
        syscfgFile);

    fprintf('\n### Generating Configuration Files\n');
    fprintf('Command: %s\n\n', syscfgCommand);

    % Execute the SysConfig command
    [status, cmdout] = system(syscfgCommand);

    if status ~= 0
        fprintf('ERROR: SysConfig generation failed!\n');
        fprintf('Status: %d\n', status);
        fprintf('Output:\n%s\n', cmdout);
        error('SysConfig generation failed with status %d', status);
    end

    fprintf('SysConfig Output:\n%s\n', cmdout);

    % Verify that the expected files were generated
    expectedConfigC = fullfile(outputDir, 'ti_sdk_dl_config.c');
    expectedConfigH = fullfile(outputDir, 'ti_sdk_dl_config.h');

    fprintf('\n### Verification\n');
    if ~exist(expectedConfigC, 'file')
        error('Expected file not found: %s', expectedConfigC);
    else
        fprintf('### Generated: %s\n', expectedConfigC);
    end

    if ~exist(expectedConfigH, 'file')
        error('Expected file not found: %s', expectedConfigH);
    else
        fprintf('### Generated: %s\n', expectedConfigH);
    end

    % Add the generated files to the build
    fprintf('\n### Adding to Build\n');
    buildInfo.addSourceFiles('ti_sdk_dl_config.c', outputDir);
    buildInfo.addIncludePaths(outputDir);

    fprintf('### SysConfig files added to build successfully.\n');
    fprintf('### SysConfig Generation Complete\n\n');
end