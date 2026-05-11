function syscfgFileEditCallback(hObj, hDlg, tag, ~)
%SYSCFGFILEEDITCALLBACK Handle manual editing of SysConfig file path
%
%   Parameters:
%       hObj  - Handle to the object
%       hDlg  - Handle to the dialog
%       tag   - Tag of the widget
%       ~     - Unused parameter

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

    % Get the new value from dialog
    newVal = hDlg.getWidgetValue(tag);

    % Skip if empty or placeholder
    if isempty(newVal) || startsWith(newVal, '<')
        return;
    end

    % Validate input
    validateattributes(newVal, {'char'}, {'nonempty', 'row'}, '', 'SyscfgFilePath');

    % Get config set and set the value
    cs = hObj.getConfigSet;
    codertarget.data.setParameterValue(cs, 'SysConfig.ProjectFile', newVal);

    % Warn if file doesn't exist
    if ~exist(newVal, 'file')
        fprintf('[WARN] SysConfig file not found: %s\n', newVal);
    else
        fprintf('[OK] SysConfig file path set: %s\n', newVal);
    end

end