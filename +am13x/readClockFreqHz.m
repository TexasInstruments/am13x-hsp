function freqHz = readClockFreqHz(buildDir, macroName)
%READCLOCKFREQHZ  Read a clock-frequency #define from the generated header.
%
%   freqHz = am13x.readClockFreqHz(buildDir, macroName) locates the file
%   ti_sdk_dl_config.h that SysConfig generated into the build directory
%   and returns the numeric value of the requested preprocessor macro
%   (e.g. 'MCLK_FREQ_HZ', 'CPUCLK_FREQ_HZ').
%
%   In PIL context, pass componentArgs.getApplicationCodePath as buildDir.
%
%   Inputs:
%       buildDir   - char/string path to the build output directory
%                    (use componentArgs.getApplicationCodePath in PIL)
%       macroName  - char/string name of the #define macro to read
%
%   Output:
%       freqHz     - double, frequency in Hz
%
%   Example:
%       mclkHz = am13x.readClockFreqHz( ...
%           componentArgs.getApplicationCodePath, 'MCLK_FREQ_HZ');
%
%   Errors:
%       Throws an error if the header cannot be found or the macro is absent.

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
% This function determines the relative path needed to navigate from
% the directory specified by basePath to the directory specified by targetPath.
% It calculates how many directories to go up from basePath and then how
% to navigate down into targetPath.
% If the top-most directory does not match, it returns targetPath as is.
    arguments
        buildDir  (1,1) string
        macroName (1,1) string
    end

    HEADER_NAME = 'ti_sdk_dl_config.h';

    % ------------------------------------------------------------------
    % 1. Locate the generated header in the build directory
    % ------------------------------------------------------------------
    headerPath = fullfile(buildDir, HEADER_NAME);

    if ~exist(headerPath, 'file')
        error('am13x:readClockFreqHz:headerNotFound', ...
            ['Could not find %s in build directory:\n  %s\n' ...
             'Ensure SysConfig file generation ran successfully ' ...
             'before querying clock frequencies.'], ...
            HEADER_NAME, buildDir);
    end

    % ------------------------------------------------------------------
    % 2. Parse the macro value from the header
    % ------------------------------------------------------------------
    freqHz = parseMacro(headerPath, macroName);
end

% -----------------------------------------------------------------------
function value = parseMacro(headerPath, macroName)
%PARSEMACRO  Extract the numeric value of a #define from a C header file.

    fid = fopen(headerPath, 'r');
    if fid == -1
        error('am13x:readClockFreqHz:cannotOpenHeader', ...
            'Could not open header file for reading: %s', headerPath);
    end
    content = fread(fid, '*char')';
    fclose(fid);

    % Match:  #define <MACRO_NAME>  <integer>
    % \s+ handles any amount of whitespace (spaces/tabs) between tokens,
    % including the wide column-aligned spacing used in ti_sdk_dl_config.h.
    pattern = ['(?m)^[ \t]*#[ \t]*define[ \t]+', char(macroName), '[ \t]+(\d+)'];
    tok = regexp(content, pattern, 'tokens', 'once');

    if isempty(tok)
        error('am13x:readClockFreqHz:macroNotFound', ...
            'Macro ''%s'' not found in %s.\nVerify the SysConfig project defines this clock.', ...
            macroName, headerPath);
    end

    value = str2double(tok{1});

    if isnan(value)
        error('am13x:readClockFreqHz:parseError', ...
            'Could not convert value of ''%s'' to a number (got: ''%s'').', ...
            macroName, tok{1});
    end
end