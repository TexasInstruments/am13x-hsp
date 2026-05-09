function createCCSproject(hCS, buildInfo)
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

projectName = buildInfo.getBuildName;
BuildDir = RTW.getBuildDir(projectName);
targetInfo = codertarget.attributes.getTargetHardwareAttributes(hCS);
isProfilingEnabled = isequal(get_param(hCS, 'CodeExecutionProfiling'), 'on');
this_file_dir = mfilename('fullpath');
[this_dir, ~] = fileparts(this_file_dir);
CGTInstallationDirectory = this_dir;
tokenName = 'COM_TI_AM13E230X_SDK_INSTALL_DIR';
TIDriverPath = getenv('COM_TI_AM13E230X_SDK_INSTALL_DIR');
cgtPath = '';
deviceID = 'AM13E23019';
configFile = '';
processingUnit = 'M33';

%% Get the list of source files
listOfFiles = buildInfo.getSourceFiles(true, true);
for index = 1:numel(listOfFiles)
    listOfFiles{index} = codertarget.utils.replaceTokens(hCS, listOfFiles{index}, targetInfo.Tokens);
    CodeProfilingInstrumentation = get_param(projectName, 'CodeProfilingInstrumentation');
    % When profiling is enabled all source files should be considered from instrumented folder
    if isProfilingEnabled && contains(listOfFiles{index}, BuildDir.BuildDirectory) && ...
            ~contains(listOfFiles{index}, fullfile(BuildDir.BuildDirectory, 'instrumented')) &&...
            (strcmp(CodeProfilingInstrumentation, 'coarse') || strcmp(CodeProfilingInstrumentation, 'detailed'))
        listOfFiles{index} = strrep(listOfFiles{index}, BuildDir.BuildDirectory, fullfile(BuildDir.BuildDirectory, 'instrumented'));
    end
end
%% Get the list of compiler defines
compiler_defines = buildInfo.getDefines;

%% Get the list of all include files
includeFiles = buildInfo.getIncludePaths(true);
for index = 1:numel(includeFiles)
    includeFiles{index} = codertarget.utils.replaceTokens(hCS, includeFiles{index}, targetInfo.Tokens);
    if (isequal((strfind(includeFiles{index}, '..')), 1))
        % If any of the include paths are relative, construct the full
        % path with the build directory
        includeFiles{index} = fullfile(BuildDir.BuildDirectory, includeFiles{index});
    end
end

%% Get the list of all the special tokens used
rootFolders = buildInfo.Settings.getRootFolders();
sDirs = {rootFolders.PathPattern};
sToks = {rootFolders.TokenPattern};

%% Get the list of all linker files
linkObjs = getLinkObjects(buildInfo);
Libraries = {};
for index = 1:numel(linkObjs)
    linkPath = codertarget.utils.replaceTokens(hCS, linkObjs(index).Path, targetInfo.Tokens);
    linkPath = regexprep(linkPath, sToks, sDirs, 'ignorecase');
    [~, ~, ext] = fileparts(linkObjs(index).Name);
    if isempty(ext)
        libExtension = '.a';
    else
        libExtension = '';
    end
    Libraries = [Libraries, fullfile(linkPath, [linkObjs(index).Name, libExtension])];
end

%% Get the Library file for the referenced model
if(strcmpi(get_param(projectName, 'ModelReferenceTargetType'), 'NONE'))
    if(~isempty(buildInfo.ModelRefs))
        for ctr = 1:length(buildInfo.ModelRefs)
            mdlref_libname = buildInfo.ModelRefs(ctr).Name;
            mdlref_libpath = regexprep(buildInfo.ModelRefs(ctr).Path, sToks, sDirs, 'ignorecase');
            [~, ~, ext] = fileparts(mdlref_libname);
            if isempty(ext)
                libExtension = '.a';
            else
                libExtension = '';
            end
            Libraries = [Libraries fullfile(mdlref_libpath, [mdlref_libname, libExtension])];
        end
    end
end

%% Get the list of Linker defines
linker_defines = {};
linker_flags = buildInfo.getLinkFlags;
retainFlags = {};
for index = 1:numel(linker_flags)
    if(~isempty(strfind(linker_flags{index}, '-l')))
        % Split multiple entries for linker with space as delimiter
        libraryEntry = split(linker_flags{index}, ' ');
        for libIndx = 1:numel(libraryEntry)
            % Search for the presence of multiple library inclusions
            if(~isempty(strfind(libraryEntry{libIndx}, '-l')))
                % remove -l flag before adding to the existing list of libraries
                rtslib = split(libraryEntry{libIndx}, '-l');
                Libraries = [Libraries, rtslib(2)];
            end
        end
    end
    if(~isempty(strfind(linker_flags{index}, '--define')))
        linker_defines = [linker_defines, linker_flags{index}];
    end
    if(~isempty(strfind(linker_flags{index}, '--retain')))
        retainCell = split(linker_flags{index}, ' ');
        for retainIndex = 1:numel(retainCell)
            if(~isempty(strfind(retainCell{retainIndex}, '--retain')))
                retainFlags = [retainFlags, retainCell{retainIndex}];
            end
        end
    end
end

% Get the Build Configuration selected during Code generation
build_config = get_param(projectName, 'BuildConfiguration');
% Get the value of Stack size
stacksize = get_param(hCS, 'MaxStackSize');

%% Get the list of Compiler, Assembler and Linker flags based on the Build Configuration
%
% For the normal Debug/Faster Builds/Faster Runs configurations (else branch),
% flags are read directly from the registered toolchain .mat file via
% getBuildConfigurationOption. $(VAR) macro tokens are preserved so they can
% be converted to ${VAR} CCS syntax later in printProjectSpec.
%
% For the 'Specify' configuration (if branch), flags come from
% CustomToolchainOptions and use four cleanup patterns on compiler_flags only:
%   pattern1: removes whitespace + -i"$(VAR)/include" style tokens
%   pattern2: removes whitespace + -i"$(VAR)" style tokens
%   pattern3: removes any bare $(VAR) token
%   pattern4: removes -I$(VAR) uppercase include tokens
%
% IMPORTANT: None of these patterns are applied to linker_flags because:
%   pattern4 uses character class [-I$(]+ which also matches $(VAR) tokens
%   such as $(COM_TI_AM13E230X_SDK_INSTALL_DIR) and $(TI_LIB), stripping
%   the entire macro and leaving bare -i flags with no path argument.
%   pattern3, pattern1, pattern2 are similarly destructive to -i path macros.
%   All $(VAR) SDK macros in linker_flags are preserved and converted to
%   ${VAR} CCS syntax later in printProjectSpec.

if(strcmpi(build_config, 'Specify'))
    pattern1 = '\s+[-i"$(]+\w*+[)]+[/include]+["]';
    pattern2 = '\s+[-i"$(]+\w*+[)]+["]';
    pattern3 = '[$(]+\w*+[)]*';
    copts = hCS.get_param('CustomToolchainOptions');
    compiler_flags = [copts{2} copts{4}];
    compiler_flags = regexprep(compiler_flags, pattern1, '');
    compiler_flags = regexprep(compiler_flags, pattern2, '');
    compiler_flags = regexprep(compiler_flags, pattern3, '');
    compiler_flags = strrep(compiler_flags, '"', '');
    compiler_flags = strrep(compiler_flags, '--compile_only', '');
    cflags_skipforsil = buildInfo.getCompileFlags;
    compiler_flags = [compiler_flags ' ' strjoin(cflags_skipforsil(:))];
    linker_flags = copts{6};
    % Substitute only the known scalar build tokens with their runtime values.
    % All other $(VAR) SDK macros are left intact for later ${VAR} conversion.
    linker_flags = strrep(linker_flags, '$(STACK_SIZE)', stacksize);
    linker_flags = strrep(linker_flags, '$(HEAP_SIZE)', getenv('HEAP_SIZE'));
    linker_flags = strrep(linker_flags, '$(PRODUCT_NAME)', projectName);
    linker_flags = [linker_flags ' ' strjoin(retainFlags(:))];
else
    aflags = [];
    cflags = [];
    linker_flags = [];
    k = buildInfo.getBuildToolInfo('ToolchainInfo');
    flags = k.getBuildConfigurationOption(build_config, 'Assembler');
    flags{end} = '';
    for index = 1:length(flags)
        if(~isempty(flags{index}))
            aflags = [aflags ' ' flags{index}];
        end
    end
    flags = k.getBuildConfigurationOption(build_config, 'C Compiler');
    flags{6} = '';
    flags{7} = '';
    flags{8} = '';
    for index = 1:length(flags)
        if(~isempty(flags{index}))
            cflags = [cflags ' ' flags{index}];
        end
    end
    cflags_skipforsil = buildInfo.getCompileFlags;
    compiler_flags = [aflags cflags ' ' strjoin(cflags_skipforsil(:))];
    compiler_flags = strrep(compiler_flags, '"', '');
    compiler_flags = strrep(compiler_flags, '--compile_only', '');
    flags = k.getBuildConfigurationOption(build_config, 'Linker');
    % Substitute only the known scalar build tokens with their runtime values.
    % $(VAR) SDK macros like $(TI_LIB) and $(COM_TI_AM13E230X_SDK_INSTALL_DIR)
    % are deliberately left intact - they will be converted to ${VAR} CCS
    % syntax later in printProjectSpec via the $(VAR)->${VAR} regexprep.
    flags = strrep(flags, '$(STACK_SIZE)', stacksize);
    flags = strrep(flags, '$(HEAP_SIZE)', getenv('HEAP_SIZE'));
    flags = strrep(flags, '$(PRODUCT_NAME)', projectName);
    for index = 1:length(flags)
        if(~isempty(flags{index}))
            linker_flags = [linker_flags ' ' flags{index}];
        end
    end
    linker_flags = [linker_flags ' ' strjoin(retainFlags(:))];
end

% Remove double quotes from linker_flags. The toolchain produces flags like
%   -Wl,-i"$(TI_LIB)"  and  -Wl,--xml_link_info="name.xml"
% CCS projectspec does not need the quotes. $(VAR) macro tokens are preserved
% and converted to ${VAR} syntax later in printProjectSpec.
% The -Wl,-i prefix is kept here and converted to plain -i in createProjectSpecFile.
linker_flags = regexprep(linker_flags, '=(")(.*?)(")', '=$2');  % --flag="value"  -> --flag=value
linker_flags = regexprep(linker_flags, '(?<=\S)"',     '');     % token"path      -> tokenpath
linker_flags = regexprep(linker_flags, '"(?=\s|$)',    '');     % path" <space>   -> path <space>

% AM13x always uses ELF/TICLANG - no legacy --abi or -z flags apply
compilerFormat = 'ELF';

%% Get code generation tool version
verFile = 'README.*';
verPattern = '(\d*\.(\d*\.)+\w*)';
fileList = dir(fullfile(cgtPath, verFile));
if ~isempty(fileList)
    cgtVersion = linkfoundation.util.getVersion(fullfile(cgtPath, fileList(1).name), verPattern);
else
    cgtVersion = '4.0.4.LTS';
end

%% Get path to the target configuration file
%  cmdEnd = codertarget.data.getParameterValue(hCS,'Runtime.LoadCommandArg');
%configFile = codertarget.utils.replaceTokens(hCS,cmdEnd,targetInfo.Tokens);

%% XML file creation
% Extract the component name from buildInfo
componentName = buildInfo.ComponentName;

% Construct the file name using the component name
projectSpecfileName = strcat(componentName, '.projectspec');

% Determine boot source: 1 for Flash, 0 for RAM
% bootFromFlash = codertarget.data.getParameterValue(hCS,'Runtime.FlashLoad');
bootFromFlash = any(strcmp(linker_flags, '-Wl,--rom_model'));
mainSrcDir = char(getSourcePaths(buildInfo, 1, 'BuildDir'));
% Extract the Device ID from HardwareInfo
%deviceID = codertarget.data.getParameterValue(hCS,'Runtime.DeviceID');

targetHardwareInfo  = codertarget.targethardware.getTargetHardware(hCS);
toolchain = buildInfo.getBuildToolInfo('ToolchainInfo');

am13x.createProjectSpecFile(CGTInstallationDirectory, tokenName, TIDriverPath, projectName, cgtVersion, compilerFormat, linker_flags, compiler_flags, listOfFiles, includeFiles, compiler_defines, linker_defines, configFile, Libraries, projectSpecfileName, processingUnit, bootFromFlash, mainSrcDir, cgtPath, deviceID, targetHardwareInfo, toolchain);

if ~isfolder('CCS_Project')
    mkdir('CCS_Project');
    movefile(projectSpecfileName, fullfile('CCS_Project', '/'), 'f');
else
    movefile(projectSpecfileName, fullfile('CCS_Project', '/'), 'f');
end

% Create a folder within code-gen folder to use as the CCS Workspace
if(~isfolder('CCS_Workspace'))
    mkdir('CCS_Workspace');
end
%% Open the project if user clicks on the hyperlink in diagnostic viewer
%Simulink.output.info(DAStudio.message('TIC2000:codegen:OpenCCSProject',CCS_InstallDir,project_folder,componentName));
% Command to import the project using CCS command-line tools
%importCommand = sprintf('"%s\\ccs\\eclipsec" -noSplash -data "%s" -application com.ti.ccstudio.apps.projectImport -ccs.projectspec "%s"', ...
%                        ccsPath, ccsPath, projectspecPath);
end
