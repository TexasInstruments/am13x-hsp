function relativePath = getRelativeFilePath(basePath, targetPath)
% getRelativeFilePath Computes the relative path from basePath to targetPath.
%
% Parameters:
%   basePath - The base directory path from which the relative path is calculated.
%   targetPath - The target directory path to which the relative path is calculated.
%
% Returns:
%   relativePath - A string representing the relative path from basePath to targetPath,
%                  or targetPath itself if the top-most directories don't match.

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

% Split the paths into components using MATLAB's built-in strsplit function
basePathParts = strsplit(basePath, filesep);
targetPathParts = strsplit(targetPath, filesep);

% Check if the top-most directories match
if ~isempty(basePathParts) && ~isempty(targetPathParts) && strcmp(basePathParts{1}, targetPathParts{1})
    % Find the common base path
    minLength = min(length(basePathParts), length(targetPathParts));
    commonIndex = 0;

    for i = 1:minLength
        if strcmp(basePathParts{i}, targetPathParts{i})
            commonIndex = i;
        else
            break;
        end
    end

    % Calculate the number of directories to go up from basePath
    numDirsUp = length(basePathParts) - commonIndex;
    upPath = repmat(['..', filesep], 1, numDirsUp);

    % Calculate the path to go down into targetPath
    downPath = strjoin(targetPathParts(commonIndex+1:end), filesep);

    % Combine to get the relative path
    if isempty(downPath)
        relativePath = upPath(1:end-1); % Remove trailing file separator
    else
        relativePath = [upPath, downPath];
    end
else
    % If the top-most directories do not match, return targetPath as is
    relativePath = targetPath;
end
end