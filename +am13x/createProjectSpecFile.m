function createProjectSpecFile(CGTInstallationDirectory, tokenName, TIDriverPath , projectName,  cgtVersion, outputFormat, linker_flags, compiler_flags, listofFiles, includeFiles, compiler_defines, linker_defines, configFile, ~, projectSpecfileName, processingUnit, bootFromFlash, mainSrcDir, cgtPath, deviceID, ~, toolchain)
% CREATEPROJECTSPECFILE transforms the variables required for the .projectspec file for TI CCS project creation.
%
% PARAMETERS:
% tokenName - Macro for path replacement (e.g., 'C2000WAREINSTALLDIR').
% TIDriverPath  - Actual path value corresponding to the macro.
% projectName - Name of the CCS project.
% cgtVersion - Version of code generation tools.
% outputFormat - Desired output format for the project.
% linker_flags - Flags for the linking process.
% compiler_flags - Flags for the compilation process.
% listofFiles - List of source files to include.
% includeFiles - List of include directories.
% compiler_defines - Compiler-specific defines.
% linker_defines - Linker-specific defines.
% configFile - Configuration file for the project.
% Libraries - Libraries to link with the project.
% projectSpecfileName - Name of the output .projectspec file.
% processingUnit - Processing unit used (e.g., 'CortexM33').
% bootFromFlash - Flag indicating boot from flash (1 for true).
% mainSrcDir - Main source directory for the project.
% cgtPath - Path to code generation tools.
% deviceID - Identifier for the target device.
% targetHardwareInfo  - Data target specification.
% toolchain - Toolchain for code generation.

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

linkerCmdFile = '${COM_TI_AM13E230X_SDK_INSTALL_DIR}/ti_sdk_config/am13e230x/default/linker_m33_ti_arm_clang.cmd';

% Initialize the updated file lists
listOfFilesWithC2000WareDirMacro = listofFiles;
endianness = 'little'; % little by default

% Add products attribute for SDK dependencies
products = 'sysconfig;AM13E2X-SDK';

LibrariesWithC2000WareMacro = '';

% Modifying the full path to the relative path with respect to the .projectSpec directory
% to incorporate the portability of the code across different users.
% This section converts absolute include paths to relative paths using the CCSProjectFolder macro.
% For example, if the include path is 'C:\Users\Username\Projects\MyProject\Include',
% and the CCS workspace is            'C:\Users\Username\Projects\MyProject\CCS_Project',
% the relative path becomes '..\Include', and the macro will be appended as '${CCSProjectFolder}\..\Include'.

replaceStringCCS = '${CCSProjectFolder}/';

% Construct the full CCS workspace path (keep native separators for getRelativeFilePath)
ccsWorkspace = fullfile(mainSrcDir, 'CCS_Project');

% Preallocate updated include files, replacing the full path with the relative paths
includeFilesWithCCSProjectMacro= includeFiles;

% SDK install dir (forward-slash normalised) used to detect SDK include paths
sdkInstallDir = strrep(TIDriverPath, '\', '/');

% Loop through each path in the INCLUDEFILES
for i = 1:length(includeFiles)

    % Normalise the include path to forward slashes for comparison
    includePathFwd = strrep(includeFiles{i}, '\', '/');

    % SDK paths must use the ${COM_TI_AM13E230X_SDK_INSTALL_DIR} macro
    % regardless of whether a relative path could be computed, so check
    % for the SDK prefix first.
    if ~isempty(sdkInstallDir) && startsWith(includePathFwd, sdkInstallDir)
        % Replace the SDK root with the CCS environment variable macro
        suffix = includePathFwd(length(sdkInstallDir)+1:end);
        % Ensure suffix starts with /
        if isempty(suffix) || suffix(1) ~= '/'
            suffix = ['/' suffix];
        end
        includeFilesWithCCSProjectMacro{i} = ['${' tokenName '}' suffix];
    else
        % Use the getRelativeFilePath function to calculate the relative path
        relativePath = am13x.getRelativeFilePath(ccsWorkspace, includeFiles{i});

        % Check if the relative path is different from the original include path
        if ~strcmp(includeFiles{i}, relativePath)
            % Path is inside the project tree: use CCSProjectFolder macro.
            % Normalise to forward slashes for consistent projectspec output.
            relativePath = strrep(relativePath, '\', '/');
            includeFilesWithCCSProjectMacro{i} = [replaceStringCCS, relativePath];
        else
            % Path is on a different drive or unreachable relatively:
            % keep the original path normalised to forward slashes.
            includeFilesWithCCSProjectMacro{i} = includePathFwd;
        end
    end
end


% 'I' is needed before the includefiles as per the .projectspec syntax.
% No space between '-I' and the path so the regex in printProjectSpec
% does not split the flag from its argument (e.g. "-I${CCSProjectFolder}\..\..")
includeFilesWithPrefix = strcat('-I', includeFilesWithCCSProjectMacro);
% Join all include paths into a single space-separated string;
% printProjectSpec will later split each token onto its own line.
includeFilesString = strjoin(includeFilesWithPrefix, ' ');


%   'arm_cortex_m_multitasking.c' is not having the full path in the
%   listOfFiles , so need to search if this is present then  need  to
%   append the full path with it , ( projectspec requires the fullpath of
%   the files )
% File to search for
fileToSearch = 'arm_cortex_m_multitasking.c';
% Check if the file is present in the list
fileFound  = false;
for i = 1:length(listOfFilesWithC2000WareDirMacro)
    if strcmp(listOfFilesWithC2000WareDirMacro{i}, fileToSearch)
        fileFound  = true;
        break;
    end
end
% Append the path if the file is found
if fileFound
    new_file = fullfile(pwd, fileToSearch);
    listOfFilesWithFullPathAppend = [listOfFilesWithC2000WareDirMacro(1:i-1), {new_file}, listOfFilesWithC2000WareDirMacro(i+1:end)];
else
    listOfFilesWithFullPathAppend = listOfFilesWithC2000WareDirMacro;
end


% Initialize a cell array to hold the updated file paths
listOfFilesWithRelativePath = cell(size(listOfFilesWithFullPathAppend));

% Define the CCS project folder path
ccsProjectFolderPath = 'CCSProjectFolder';

% Loop through each file path
for i = 1:length(listOfFilesWithFullPathAppend)
    filePath = listOfFilesWithFullPathAppend{i};

    % Construct the full path to the CCS_Project directory
    ccsProjectDir = fullfile(mainSrcDir, 'CCS_Project');

    % Check if the file path starts with the main source directory
    if startsWith(filePath, mainSrcDir)
        % Use the getRelativeFilePath function to calculate the relative path
        relativePath = am13x.getRelativeFilePath(ccsProjectDir, filePath);

        % Normalise to forward slashes for consistent projectspec output
        listOfFilesWithRelativePath{i} = strrep(relativePath, '\', '/');
    else
        % Keep the original path for files outside the main source directory,
        % normalised to forward slashes
        listOfFilesWithRelativePath{i} = strrep(filePath, '\', '/');
    end
end


% constructing the configuration name
% Determine configuration based on processing unit and boot source
if strcmp(processingUnit, 'M33')
    coreName = 'am13e230x'; %#ok<NASGU>

    if contains(compiler_flags, '-mlittle-endian')
        endianness = 'little';
        compiler_flags = strrep(compiler_flags, '-mlittle-endian', '');
    elseif contains(compiler_flags, '-mbig-endian')
        endianness = 'big';
    end
    % Remove '-c' and '-ml' from the compiler flags: for arm core
    compiler_flags = strrep(compiler_flags, ' -c ', ' ');
    compiler_flags = strrep(compiler_flags, '-ml', '');

    % Remove warning flags from linker_flags (compiler-only flags)
    warningFlagsToRemove = {'-Wall', '-Wextra', '-Werror', ...
        '-Wno-gnu-variable-sized-type-not-at-end', ...
        '-Wno-unused-function', ...
        '-Wno-unused-command-line-argument', ...
        '-Wno-unused-parameter'};
    for w = 1:length(warningFlagsToRemove)
        linker_flags = strrep(linker_flags, warningFlagsToRemove{w}, '');
    end

    % Remove cpu/float flags from linker (not needed, CCS infers from project settings)
    cpuFlagsToRemove = {'-mcpu=cortex-m33', '-mfloat-abi=hard', '-mfpu=fpv5-sp-d16', ...
        '-mlittle-endian', '-mthumb'};
    for c = 1:length(cpuFlagsToRemove)
        linker_flags = strrep(linker_flags, cpuFlagsToRemove{c}, '');
    end

    % Fix linker library search paths and quoted flag values.
    % All four patterns below preserve the flag content while removing
    % the surrounding double quotes that CCS projectspec does not need.
    %
    % Pattern 1: -Wl,-i"<path>"  ->  -i<path>
    linker_flags = strrep(linker_flags, '-Wl,-i', '-i');
    linker_flags = strrep(linker_flags, '-i"', '-i');
    %
    % Pattern 2: =(")(.*?)(") -> =$2 : remove quotes around flag=value
    %   e.g. --xml_link_info="foo_linkInfo.xml" -> --xml_link_info=foo_linkInfo.xml
    %   (.*?) captures the value non-greedily between the two quotes
    linker_flags = regexprep(linker_flags, '=(")(.*?)(")', '=$2');
    %
    % Pattern 3a: (?<=\S)" -> '' : remove opening quote after a non-whitespace char
    %   e.g. -Wl,-m"$(PRODUCT_NAME).map" -> -Wl,-m$(PRODUCT_NAME).map"
    %        -Wl,-i"$(TI_LIB)"           -> -Wl,-i$(TI_LIB)"
    %   lookbehind (?<=\S) ensures only quotes glued to a token are removed
    linker_flags = regexprep(linker_flags, '(?<=\S)"', '');
    %
    % Pattern 3b: "(?=\s|$) -> '' : remove closing quote at end of a token
    %   e.g. -i$(TI_LIB)" -> -i$(TI_LIB)
    %   lookahead (?=\s|$) ensures only quotes at token boundaries are removed
    linker_flags = regexprep(linker_flags, '"(?=\s|$)', '');

        % Remove any bare '-I' tokens left after $(TI_INCLUDE) was stripped
    % by the build-config flag-removal regexes (e.g. '-I"$(TI_INCLUDE)"'
    % becomes just '-I' after the macro value is removed).
    compiler_flags = regexprep(compiler_flags, '(^|\s)-I(\s|$)', ' ');
    compiler_flags = strtrim(compiler_flags);

    % Resolve $(ARCH_FLAG) make macro. CCS projectspec does not expand make
    % macros, so $(ARCH_FLAG) must be replaced with its actual value.
    % Read the value from the toolchain object; fall back to AM13x default.
    archFlagValue = '-march=armv8.1-m.main+cdecp0'; % default
    try
        archFlagValue = toolchain.getMacroValue('ARCH_FLAG');
    catch
    end
    % Substitute $(ARCH_FLAG) in compiler flags with its resolved value
    compiler_flags = strrep(compiler_flags, '$(ARCH_FLAG)', archFlagValue);
    % Remove $(ARCH_FLAG) from linker flags - not needed, CCS infers from project
    linker_flags   = strrep(linker_flags,   '$(ARCH_FLAG)', '');

    % Ensure -march= is present in compiler flags (in case $(ARCH_FLAG) was absent)
    if ~contains(compiler_flags, '-march=')
        compiler_flags = [archFlagValue ' ' compiler_flags];
    end
else
    % For other processing units, determine CPU1 or CPU2 ( including CPU1CLA, CPU2CLA )
    %% endianness isn't defined for the c28x core in the compiler flags as it is little by default and uneditable in CCS project properties , it's only coming up for the ARM cortex in the compiler flags
    if contains(processingUnit, 'CPU1')
        coreName = 'CPU1'; %#ok<NASGU>
    elseif contains(processingUnit, 'CPU2')
        coreName = 'CPU2'; %#ok<NASGU>
    end
end
% Determine RAM or Flash based on boot source
if bootFromFlash == 1 % any(strcmp(linkerOpts, '-Wl,--rom_model'));
    memoryType = 'FLASH'; %#ok<NASGU>
else
    memoryType = 'RAM'; %#ok<NASGU>
end
% Construct the final configuration name
if any(strcmp(linker_flags, 'TI_SDK_RELEASE_LIB'))
    configurationName = 'Debug';
else
    configurationName = 'Release';
end

linker_flags = strrep(linker_flags, '$(TI_SDK_RELEASE_LIB)', '${COM_TI_AM13E230X_SDK_INSTALL_DIR}/build/am13e230x/lib/${ConfigName}');
linker_flags = strrep(linker_flags, '$(TI_SDK_DEBUG_LIB)', '${COM_TI_AM13E230X_SDK_INSTALL_DIR}/build/am13e230x/lib/${ConfigName}');

% projectSPec requires compiler flags and linker flags as a char vector.
% Convert cell array to char via string() + strjoin(), then cast to char
% so downstream functions (strjoin in printProjectSpec) always receive char.
compiler_defines = string(compiler_defines);
compiler_defines_string = char(strjoin(compiler_defines, ' '));
linker_defines = string(linker_defines);
linker_defines_string = char(strjoin(linker_defines, ' '));


% Compiler_flags modification as required by .projectspec
%replace the 'i' in compiler flags with 'I' : required by .projectSPec
compiler_flags = strrep(compiler_flags, '-i$', '-I$');

flagsArray = strsplit(compiler_flags, ' ');
compiler_flags = strjoin(flagsArray, ' ');


% Create the .projectspec file
am13x.printProjectSpec(endianness, products, CGTInstallationDirectory, ccsProjectFolderPath, tokenName, TIDriverPath ,processingUnit, mainSrcDir, projectName, cgtVersion, outputFormat, linker_flags, configFile, LibrariesWithC2000WareMacro, projectSpecfileName, cgtPath, deviceID, includeFilesString, configurationName, compiler_defines_string, linker_defines_string, compiler_flags, listOfFilesWithRelativePath, linkerCmdFile);

end
