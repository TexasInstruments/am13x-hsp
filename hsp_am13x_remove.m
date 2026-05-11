function [outputArg] = hsp_am13x_remove

% Function to uninstall AM13x Target, peripheral device driver blocks and
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


% Get path of this file (same as target path)
tmp_Fullpath = mfilename('fullpath');
[tgtDir, ~] = fileparts(tmp_Fullpath);

% Remove from MATLAB path using helper function
removeHSPPaths(tgtDir);

% Remove CCS environment variables using helper function
removeEnvironmentVariables(tgtDir);

rmpref('AM13xPILpref');
sl_refresh_customizations;
RTW.TargetRegistry.reset;
savepath;


outputArg = 0;

end

%% Helper function to remove HSP paths from MATLAB environment
function removeHSPPaths(tgtDir)
% Remove from MATLAB path !

rmpath(tgtDir);
rmpath(fullfile(tgtDir, 'registry'));
rmpath(fullfile(tgtDir, 'src'));
rmpath(genpath(fullfile(tgtDir, 'blocks')));
rmpath(genpath(fullfile(tgtDir, 'examples')));
rmpath(genpath(fullfile(tgtDir, 'toolchain')));
rmpath(genpath(fullfile(tgtDir, 'doc')));
rmpath(fullfile(tgtDir, 'code_replacement'));
disp('Uninstalled TI ARM CLANG and IAR ARM toolchains!');
end

%% Helper function to remove environment variables
function removeEnvironmentVariables(tgtDir)
disp('Removing CCS and IAR environment variables...');

% Create a cleanup batch file
cleanupFile = fullfile(tgtDir, 'cleanup_env.bat');
fd = fopen(cleanupFile, 'w+');

fprintf(fd, '@echo off\n');
fprintf(fd, 'echo Removing environment variables...\n');
fprintf(fd, 'reg delete HKCU\\Environment /v CCSARMINSTALLDIR /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v CCSROOT /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v MCUSDKINSTALLDIR /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v COM_TI_AM13E230X_SDK_INSTALL_DIR /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v LINKERCMDDIR /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v SYSCFG_ROOT /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v TI_TOOLS /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v TI_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v TI_LIB /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v TI_BUILD /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v MCUSDK_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v CMSISCORE_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v CMSISDSP_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v DEVICE_HW_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v DRIVERLIB_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v TMU_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v HAL_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v HALCFG_INCLUDE /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v LINKER_CMD_DIR /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v IARROOT /f\n');
fprintf(fd, 'reg delete HKCU\\Environment /v IARARMINSTALLDIR /f\n');
fprintf(fd, 'echo Environment variables removed.\n');
fclose(fd);

% Execute the cleanup batch file
[~, ~] = system(['"', cleanupFile, '"']);

% Clean up the batch file itself
if exist(cleanupFile, 'file')
    delete(cleanupFile);
end

% Remove the setup batch file if it exists
setenvFile = fullfile(tgtDir, 'mwsetenv.bat');
if exist(setenvFile, 'file')
    delete(setenvFile);
end

disp('CCS and IAR environment variables removed successfully!');
end

