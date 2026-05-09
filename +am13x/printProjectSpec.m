function printProjectSpec(endianness, products, CGTInstallationDirectory, ccsProjectFolderPath, ~, ~, ~, mainSrcDir, projectName, cgtVersion, outputFormat, linker_flags, ~, LibrariesWithC2000WareMacro, projectSpecfileName, cgtPath, deviceID, includeFilesString, configurationName, compiler_defines_string, linker_defines_string, compiler_flags, listOfFilesWithRelativePath, linkerCmdFile)
% PRINTPROJECTSPEC Generates a project specification (.PROJECTSPEC) XML file for Code Composer Studio PROJECT.
%
% This function creates a .projectspec file, which is used by Texas Instruments
% Code Composer Studio (CCS) to define project settings, paths, and configurations.
%
% INPUTS:
%   endianness               - contains the little endian or big endian as per the compiler_flags
%   CGTInstallationDirectory - The directory where CCS is installed.
%   ccsProjectFolderPath     - The folder path for the CCS project.
%   tokenName                - A string representing the token name for the installation directory
%   TIDriverPath             - The value of the path variable.
%   processingUnit           - The processing unit type (e.g., 'CortexM33').
%   mainSrcDir               - The main source directory for the project.
%   projectName              - The name of the project.
%   cgtVersion               - The version of the Code Generation Tools.
%   outputFormat             - The output format for the project.
%   linker_flags             - Flags for the linker.
%   configFile               - The configuration file path.
%   LibrariesWithC2000WareMacro - A list of libraries with C2000Ware macros.
%   projectSpecfileName      - The name of the .projectspec file to be created.
%   cgtPath                  - The path to the Code Generation Tools.
%   deviceID                 - The device ID for the target hardware.
%   includeFilesString       - A string of include file paths.
%   configurationName        - The name of the configuration.
%   compiler_defines_string  - Compiler defines as a string.
%   linker_defines_string    - Linker defines as a string.
%   compiler_flags           - Compiler flags.
%   listOfFilesWithRelativePath - A list of files with their paths relative to the CCS_Project path.
%   linkerCmdFile            - Path to the linker command file to be included in the project.
% OUTPUTS:
%   The function does not return any outputs but writes the .projectspec file to the specified location.
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

toolChain = 'TICLANG';
file = fopen(projectSpecfileName, 'wt');
% Write the XML header
fprintf(file, '<?xml version="1.0" encoding="utf-8"?>\n');
fprintf(file, '<projectSpec>\n');

fprintf(file, '\n'); %new line

% Write the project element with attributes
fprintf(file, '        <project\n');
fprintf(file, '        name="%s"\n', projectName);


% Concatenate based on the core type
finalDeviceName = deviceID;
fprintf(file, '        device="%s"\n', finalDeviceName);
fprintf(file, '        deviceCore="%s"\n', 'CORTEX_M33');
fprintf(file, '        cgtVersion="%s"\n', cgtVersion);
fprintf(file, '        toolChain="%s"\n', toolChain);
fprintf(file, '        products="%s"\n', products);
fprintf(file, '        connection="%s"\n', 'TIXDS110_Connection.xml');
fprintf(file, '        endianness="%s"\n', endianness);
fprintf(file, '        enableSysConfigTool="%s"\n', 'true');
fprintf(file, '        outputFormat="%s"\n', outputFormat);
fprintf(file, '        outputType="%s"\n', 'executable');

% fprintf(file, '        ignoreDefaultDeviceSettings="%s"\n', 'true');
% fprintf(file, '        ignoreDefaultCCSSettings="%s"\n', 'true');
% fprintf(file, '        launchWizard="False"\n');
% fprintf(file, '        linkerCommandFile=""\n');


fprintf(file, '        >\n');

scope = 'project'; %#ok<NASGU>
% Write the path variable XML snippet to the .projectspec file
% Do not emit path variable for COM_TI_AM13E230X_SDK_INSTALL_DIR its conflicting with SDK
% fprintf(file, '<pathVariable name="%s" path="%s" scope="%s" />\n', tokenName, TIDriverPath , scope);

% Printing the MACRO definition for CCSProjectFolder to make use of relative paths,
% 'IncludeOptions' in the CCS Project properties works with MACROS but not
% with the absolute Path
% Define the path variable XML snippet for the CCS project folder
projectFolderPathValue = strrep(fullfile(mainSrcDir, 'CCS_Project'), '\', '/');
scope = 'project';
% Write the path variable XML snippet to the .projectspec file
fprintf(file, '<pathVariable name="%s" path="%s" scope="%s" />\n', ccsProjectFolderPath, projectFolderPathValue, scope);


% define the TI_INCLUDE manually
projectFolderPathValue = strrep(fullfile(CGTInstallationDirectory, 'include'), '\', '/');
%modify the compiler_flags here : replace : $(TI_INCLUDE) with the  projectFolderPathValue
%path :
compiler_flags = strrep(compiler_flags, '$(TI_INCLUDE)', projectFolderPathValue);

% CCS projectspec uses ${VAR} syntax; convert any $(VAR) make-style macros
compiler_flags      = regexprep(compiler_flags,      '\$\(([^)]+)\)', '\${$1}');
includeFilesString  = regexprep(includeFilesString,  '\$\(([^)]+)\)', '\${$1}');
linker_flags        = regexprep(linker_flags,        '\$\(([^)]+)\)', '\${$1}');
% Split each space-separated token onto its own line inside the XML attribute
% value. strtrim removes any leading/trailing whitespace left by earlier
% flag-removal steps. The regex preserves spaces inside "Program Files" paths.
compiler_flags          = regexprep(strtrim(compiler_flags),          '(?<!Program)\s(?!Files)', newline);
includeFilesString      = regexprep(strtrim(includeFilesString),      '(?<!Program)\s(?!Files)', newline);
compiler_defines_string = regexprep(strtrim(compiler_defines_string), '(?<!Program)\s(?!Files)', newline);
linker_flags            = regexprep(strtrim(linker_flags),            '(?<!Program)\s(?!Files)', newline);
linker_defines_string   = regexprep(strtrim(linker_defines_string),   '(?<!Program)\s(?!Files)', newline);

% Build the combined compilerBuildOptions and linkerBuildOptions strings.
% Each section (flags / includes / defines) is joined with a newline so every
% token occupies its own line inside the XML attribute value.
% Convert all parts to char first — compiler_defines_string arrives as a
% string array (from string() in createProjectSpecFile) and strjoin requires
% all cell elements to be char vectors.
compilerParts = {char(compiler_flags), char(includeFilesString), char(compiler_defines_string)};
compilerParts = compilerParts(~cellfun(@(s) isempty(strtrim(s)), compilerParts));
compilerBuildOptions = strjoin(compilerParts, newline);

linkerParts = {char(linker_flags), char(linker_defines_string)};
linkerParts = linkerParts(~cellfun(@(s) isempty(strtrim(s)), linkerParts));
linkerBuildOptions = strjoin(linkerParts, newline);

% printing the configurations to the projectspec
% Format matches CCS expected projectspec layout:
%   <configuration name="debug"
%    compilerBuildOptions="\nflag1\nflag2\n..."
%    linkerBuildOptions="\nflag1\nflag2\n " />
fprintf(file, '    <configuration name="%s"\n compilerBuildOptions="\n%s"\n linkerBuildOptions="\n%s\n " />\n', ...
    configurationName, compilerBuildOptions, linkerBuildOptions);


%Printing the ListOfFiles in the projectspec, one by one
% Loop through each file in listOfFiles
for i = 1:length(listOfFilesWithRelativePath)
    % Extract the string from the cell array
    filePath = listOfFilesWithRelativePath{i};

    % Normalise to forward slashes and write to file
    filePath = strrep(filePath, '\', '/');
    fprintf(file, '    <file action="link" path="%s" targetDirectory=""/>\n', filePath);
end

% Add the linker command file to the project
if ~isempty(linkerCmdFile)
    fprintf(file, '    <file action="copy" path="%s" targetDirectory=""/>\n', linkerCmdFile);
end
% Add generated files are properly integrated into your CCS project structure
% Search for .syscfg in model directory and one level down
syscfgFiles = dir(fullfile(mainSrcDir, '*.syscfg'));          % same folder as .slx
if ~isempty(syscfgFiles)
    syscfgPath = fullfile(syscfgFiles(1).folder, syscfgFiles(1).name);
    [~, syscfgName, syscfgExt] = fileparts(syscfgPath);
    syscfgFileName = ['../', syscfgName, syscfgExt]; % e.g. '../led_toggle_1Hz_am13x.syscfg'
    fprintf(file, '    <file action="copy" path="%s" openOnCreation="false" excludeFromBuild="false"/>\n', syscfgFileName);
end

% Print the Libraries and .cmds
% Loop through each library in Libraries
for i = 1:length(LibrariesWithC2000WareMacro)
    % Extract the string from the cell array
    libraryPath = LibrariesWithC2000WareMacro{i};

    % Remove double quotes from the libraryPath
    % This is required because the 'rtslib' from the createCCSProject
    % contains the "", which is incorrect for the .projectspec format
    libraryPath = strrep(libraryPath, '"', '');


    % Check if the library contains the keyword 'rts' and has a '.lib' extension
    if contains(libraryPath, 'rts') && endsWith(libraryPath, '.lib')
        % Extract the library name from the path
        [~, libName, ext] = fileparts(libraryPath);

        % Append the cgtPath with the specific path up to 'lib'
        % as full path is required in the projectspec
        libraryPath = strrep(fullfile(cgtPath, 'lib', [libName, ext]), '\', '/');
    end

    % Write the string to the file with the specified format
    fprintf(file, '    <file action="link" path="%s" targetDirectory="" applicableConfigurations="%s"/>\n', libraryPath, configurationName); % pick from config set
end


% print the configFile details to the .projectSpec
%fprintf(file, '<file action="link" path="%s" targetDirectory="" />\n', configFile);


% Close the project and projectSpec elements
fprintf(file, '  </project>\n');
fprintf(file, '</projectSpec>\n');

% Close the file
fclose(file);
end
