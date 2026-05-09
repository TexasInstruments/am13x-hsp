function syscfgPath = getSyscfgPath(modelName)
%GETSYSCFGPATH Get the SysConfig project file path for a model
%
%   syscfgPath = am13x.getSyscfgPath(modelName) returns the currently
%   configured SysConfig project file path for the specified model.
%
%   Parameters:
%       modelName - Name of the Simulink model (string or char)
%
%   Returns:
%       syscfgPath - Full path to the SysConfig project file (char)
%                    Returns empty string if not set or placeholder value
%
%   Example:
%       % Get the SysConfig path for a model
%       path = am13x.getSyscfgPath('my_model');
%       fprintf('Current SysConfig file: %s\n', path);
%
%   See also: am13x.setSyscfgPath

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

    % Validate input
    if nargin < 1
        error('am13x:getSyscfgPath:MissingInput', ...
              'Model name is required. Usage: am1330x.getSyscfgPath(modelName)');
    end

    % Convert to char if string
    if isstring(modelName)
        modelName = char(modelName);
    end

    % Validate model name
    validateattributes(modelName, {'char'}, {'nonempty', 'row'}, ...
                      'getSyscfgPath', 'modelName');

    % Check if model is loaded
    if ~bdIsLoaded(modelName)
        error('am13x:getSyscfgPath:ModelNotLoaded', ...
              'Model "%s" is not loaded. Please load the model first.', modelName);
    end

    try
        % Get the configuration set
        cs = getActiveConfigSet(modelName);

        % Get the SysConfig file path
        syscfgPath = codertarget.data.getParameterValue(cs, 'SysConfig.ProjectFile');

        % Return empty if placeholder or empty
        if isempty(syscfgPath) || ~ischar(syscfgPath) || startsWith(syscfgPath, '<')
            syscfgPath = '';
            return;
        end

    catch ME
        error('am13x:getSyscfgPath:RetrievalFailed', ...
              'Failed to retrieve SysConfig path: %s', ME.message);
    end

end