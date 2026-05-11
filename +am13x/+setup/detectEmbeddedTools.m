classdef detectEmbeddedTools < handle
    % DETECTEMBEDDEDTOOLS  Detects installed embedded development tools on Windows.
    %
    %   Supported tools:
    %     - Code Composer Studio (CCS)  - reads TI registry key directly
    %     - TI Clang compiler           - found inside CCS install folder
    %     - AM13x SDK                   - scanned from filesystem
    %     - IAR Embedded Workbench      - reads Uninstall registry
    %
    %   Usage:
    %     detector = am13x.setup.detectEmbeddedTools();
    %     detector.detect();
    %     detector.printSummary();
    %     info = detector.getResults();
    %
    %   getResults() returns a struct with fields:
    %     .ccs      - struct array  (toolName, version, location)
    %     .tiClang  - struct array  (toolName, version, location)
    %     .am13x    - struct array  (toolName, version, location)
    %     .iar      - struct array  (toolName, version, location)
    %

    % =========================================================================
    % Constants
    % =========================================================================

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


    properties (Constant, Access = private)

        % ---- CCS: dedicated TI registry parent key --------------------------
        % Each CCS install writes:  Location, Version, Language
        CCS_REGISTRY_PARENT  = 'SOFTWARE\Texas Instruments'
        CCS_REGISTRY_HIVE    = 'HKEY_LOCAL_MACHINE'

        % Supported CCS version  (major.minor as numbers for comparison)
        CCS_SUPPORTED_MAJOR  = 20
        CCS_SUPPORTED_MINOR  = 5

        % ---- Uninstall registry (for IAR) -----------------------------------
        REGISTRY_HIVES = {'HKEY_LOCAL_MACHINE', 'HKEY_CURRENT_USER'}
        UNINSTALL_SUBKEYS = { ...
            'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', ...
            'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' ...
            }

        % ---- Display-name patterns ------------------------------------------
        PATTERN_IAR = 'IAR Embedded Workbench|IAR Systems'

        % ---- TI Clang: sub-folder inside CCS install ------------------------
        % Relative path from CCS Location to compiler folder
        TICLANG_REL_PATH     = fullfile('ccs', 'tools', 'compiler')
        TICLANG_DIR_PREFIX   = 'ti-cgt-armllvm'

        % ---- AM13x SDK: filesystem scan root --------------------------------
        AM13X_SCAN_ROOTS     = {'C:\ti', 'D:\ti', 'C:\Texas Instruments'}
        AM13X_DIR_PREFIX     = 'am13'
        AM13X_MIN_VERSION    = '26_00_00_06'   % minimum required SDK version

        % ---- SysConfig: mixed registry + filesystem -------------------------
        % The TI registry key 'TI System Configuration Tool' may only reflect
        % the first installed version.  Newer versions installed without a
        % registry update are detected by scanning the same filesystem roots.
        % Only versions >= SYSCONFIG_MIN_VERSION are accepted.
        SYSCONFIG_DIR_PREFIX  = 'sysconfig_'
        SYSCONFIG_MIN_VERSION = '1.27.0'

        % Keywords for diagnose() scan
        DIAGNOSE_KEYWORDS    = {'CCS', 'Composer', 'Theia', 'IAR', ...
            'AM13', 'processor-sdk', 'Texas Instruments'}
    end

    % =========================================================================
    % Private state
    % =========================================================================
    properties (Access = private)
        ccsResults        (1,:) struct   % toolName, version, location
        tiClangResults    (1,:) struct
        am13xResults      (1,:) struct
        sysconfigResults  (1,:) struct
        iarResults        (1,:) struct
    end

    % =========================================================================
    % Public interface
    % =========================================================================
    methods (Access = public)

        % -----------------------------------------------------------------
        function obj = detectEmbeddedTools()
            empty = obj.emptyResultStruct();
            obj.ccsResults       = empty;
            obj.tiClangResults   = empty;
            obj.am13xResults     = empty;
            obj.sysconfigResults = empty;
            obj.iarResults       = empty;
        end

        % -----------------------------------------------------------------
        function detect(obj)
            % DETECT  Populates all tool results.
            %   Call once before getResults() or printSummary().
            obj.assertWindows();
            obj.detectCCS();
            obj.detectTIClang();
            obj.detectAM13xSDK();
            obj.detectSysConfig();
            obj.detectIAR();
        end

        % -----------------------------------------------------------------
        function results = getResults(obj)
            % GETRESULTS  Returns struct with .ccs / .tiClang / .am13x / .iar
            results.ccs       = obj.ccsResults;
            results.tiClang   = obj.tiClangResults;
            results.am13x     = obj.am13xResults;
            results.sysconfig = obj.sysconfigResults;
            results.iar       = obj.iarResults;
        end

        % -----------------------------------------------------------------
        function printSummary(obj)
            fprintf('\n========== Embedded Tool Detection Summary ==========\n');
            obj.printSection('Code Composer Studio',   obj.ccsResults);
            obj.printSection('TI Clang Compiler',      obj.tiClangResults);
            obj.printSection('AM13x SDK',              obj.am13xResults);
            obj.printSection('SysConfig',              obj.sysconfigResults);
            obj.printSection('IAR Embedded Workbench', obj.iarResults);
            fprintf('=====================================================\n\n');
        end

        % -----------------------------------------------------------------
        function diagnose(obj)
            % DIAGNOSE  Prints raw details to help debug empty results.
            obj.assertWindows();

            fprintf('\n--- CCS TI registry scan ---\n');
            kids = obj.safeQueryChildNames( ...
                obj.CCS_REGISTRY_HIVE, obj.CCS_REGISTRY_PARENT);
            fprintf('  Keys under %s\\%s:\n', ...
                obj.CCS_REGISTRY_HIVE, obj.CCS_REGISTRY_PARENT);
            for i = 1:numel(kids)
                loc = obj.safeQueryValue(obj.CCS_REGISTRY_HIVE, ...
                    [obj.CCS_REGISTRY_PARENT '\' kids{i}], 'Location');
                ver = obj.safeQueryValue(obj.CCS_REGISTRY_HIVE, ...
                    [obj.CCS_REGISTRY_PARENT '\' kids{i}], 'Version');
                fprintf('  [%s]  ver=%s  loc=%s\n', kids{i}, ver, loc);
            end

            fprintf('\n--- AM13x SDK filesystem scan ---\n');
            for r = 1:numel(obj.AM13X_SCAN_ROOTS)
                root = obj.AM13X_SCAN_ROOTS{r};
                fprintf('  Scanning: %s\n', root);
                if exist(root, 'dir') ~= 7
                    fprintf('  [not found]\n');
                    continue
                end
                entries = dir(root);
                for i = 1:numel(entries)
                    if entries(i).isdir && ...
                            strncmpi(entries(i).name, obj.AM13X_DIR_PREFIX, ...
                            numel(obj.AM13X_DIR_PREFIX))
                        fprintf('  Found: %s\n', entries(i).name);
                    end
                end
            end

            fprintf('\n--- IAR Uninstall registry scan ---\n');
            allKeys = obj.collectUninstallKeys();
            hits = 0;
            for k = 1:numel(allKeys)
                dn = obj.safeQueryValue(allKeys(k).hive, ...
                    allKeys(k).subKey, 'DisplayName');
                if contains(dn, 'IAR', 'IgnoreCase', true)
                    ver = obj.safeQueryValue(allKeys(k).hive, ...
                        allKeys(k).subKey, 'DisplayVersion');
                    loc = obj.resolveLocation(allKeys(k).hive, allKeys(k).subKey);
                    fprintf('  DisplayName : %s\n', dn);
                    fprintf('  Version     : %s\n', ver);
                    fprintf('  Location    : %s\n\n', loc);
                    hits = hits + 1;
                end
            end
            if hits == 0, fprintf('  No IAR entries found.\n'); end
            fprintf('--- End of diagnostic ---\n\n');
        end

    end % public methods

    % =========================================================================
    % Private - per-tool detection
    % =========================================================================
    methods (Access = private)

        % -----------------------------------------------------------------
        function detectCCS(obj)
            % Reads HKLM\SOFTWARE\Texas Instruments\CCS <ver> keys.
            % Each key has: Location (REG_SZ), Version (REG_SZ).
            %
            % Rule: only accept version == CCS_SUPPORTED_MAJOR.CCS_SUPPORTED_MINOR
            %       If multiple exist at that version, keep only one (first found).
            %       Ignore lower versions; warn but skip higher versions.

            kids = obj.safeQueryChildNames( ...
                obj.CCS_REGISTRY_HIVE, obj.CCS_REGISTRY_PARENT);

            for i = 1 : numel(kids)
                keyName = kids{i};
                % Only process keys that start with 'CCS'
                if ~strncmpi(keyName, 'CCS', 3)
                    continue
                end

                subKey  = [obj.CCS_REGISTRY_PARENT '\' keyName];
                version = obj.safeQueryValue( ...
                    obj.CCS_REGISTRY_HIVE, subKey, 'Version');
                location = obj.safeQueryValue( ...
                    obj.CCS_REGISTRY_HIVE, subKey, 'Location');

                if isempty(version) || isempty(location)
                    continue
                end
                if ~obj.validDir(location)
                    continue
                end

                [major, minor] = obj.parseMajorMinor(version);
                if isnan(major)
                    continue
                end

                supported = obj.CCS_SUPPORTED_MAJOR;
                suppMinor = obj.CCS_SUPPORTED_MINOR;

                if major == supported && minor == suppMinor
                    % Exact supported version - accept (only first occurrence)
                    if isempty(obj.ccsResults)
                        label = sprintf('Code Composer Studio %d.%d', major, minor);
                        obj.ccsResults(end+1) = obj.makeEntry(label, version, location);
                    end
                elseif major > supported || (major == supported && minor > suppMinor)
                    % Higher than supported - skip
                    fprintf(['[detectEmbeddedTools] CCS %s found but only ' ...
                        '%d.%d is supported. Skipping.\n'], ...
                        version, supported, suppMinor);
                end
                % Lower versions are silently ignored
            end
        end

        % -----------------------------------------------------------------
        function detectTIClang(obj)
            % Finds TI Clang compilers installed inside each detected CCS.
            % Path pattern: <CCS_Location>\ccs\tools\compiler\ti-cgt-armllvm_*

            for c = 1 : numel(obj.ccsResults)
                compilerRoot = fullfile(obj.ccsResults(c).location, ...
                    obj.TICLANG_REL_PATH);
                if exist(compilerRoot, 'dir') ~= 7
                    continue
                end

                entries = dir(compilerRoot);
                for i = 1 : numel(entries)
                    if ~entries(i).isdir
                        continue
                    end
                    name = entries(i).name;
                    if strncmpi(name, obj.TICLANG_DIR_PREFIX, ...
                            numel(obj.TICLANG_DIR_PREFIX))
                        fullLoc = fullfile(compilerRoot, name);
                        version = obj.extractVersionFromDirName(name);
                        label   = sprintf('TI Clang (armllvm) %s', version);
                        obj.tiClangResults(end+1) = ...
                            obj.makeEntry(label, version, fullLoc);
                    end
                end
            end

            obj.tiClangResults = obj.deduplicate(obj.tiClangResults);
        end

        % -----------------------------------------------------------------
        function detectAM13xSDK(obj)
            % AM13x SDK is not registered in the Windows registry.
            % It is installed directly under a known root (e.g. C:\ti) as
            % a folder matching the prefix 'am13'.
            % Folder name pattern: am13e230x_sdk_<ver>  or similar.
            %
            % Only SDKs >= AM13X_MIN_VERSION are accepted.
            % If multiple valid versions are found, the latest is placed first.

            for r = 1 : numel(obj.AM13X_SCAN_ROOTS)
                root = obj.AM13X_SCAN_ROOTS{r};
                if exist(root, 'dir') ~= 7
                    continue
                end

                entries = dir(root);
                for i = 1 : numel(entries)
                    if ~entries(i).isdir
                        continue
                    end
                    name = entries(i).name;
                    if strncmpi(name, obj.AM13X_DIR_PREFIX, ...
                            numel(obj.AM13X_DIR_PREFIX))
                        fullLoc = fullfile(root, name);
                        version = obj.extractVersionFromDirName(name);

                        % Skip versions below minimum required
                        if ~obj.sdkVersionAtLeast(version, obj.AM13X_MIN_VERSION)
                            fprintf(['[detectEmbeddedTools] AM13x SDK "%s" ' ...
                                'is below minimum required version %s. ' ...
                                'Skipping.\n'], name, obj.AM13X_MIN_VERSION);
                            continue
                        end

                        label = sprintf('AM13x SDK (%s)', name);
                        obj.am13xResults(end+1) = ...
                            obj.makeEntry(label, version, fullLoc);
                    end
                end
            end

            obj.am13xResults = obj.deduplicate(obj.am13xResults);

            % Sort by version descending so latest is first (index 1)
            % hsp_am13x_setup.m uses results.am13x(1).location as default
            if numel(obj.am13xResults) > 1
                versions = {obj.am13xResults.version};
                n        = numel(versions);
                idx      = 1:n;
                % Bubble sort descending by sdkVersionAtLeast comparison
                for a = 1:n-1
                    for b = a+1:n
                        if obj.sdkVersionAtLeast(versions{idx(b)}, versions{idx(a)})
                            idx([a b]) = idx([b a]);
                        end
                    end
                end
                obj.am13xResults = obj.am13xResults(idx);
                fprintf('[detectEmbeddedTools] AM13x SDK defaulting to latest: %s\n', ...
                    obj.am13xResults(1).location);
            end
        end

        % -----------------------------------------------------------------
        % -----------------------------------------------------------------
        function detectSysConfig(obj)
            % Detects TI SysConfig installations.
            %
            % Strategy:
            %   1. Read HKLM\SOFTWARE\Texas Instruments\TI System Configuration
            %      Tool - catches the version that was formally installed.
            %   2. Scan AM13X_SCAN_ROOTS for folders matching 'sysconfig_*'
            %      to catch versions installed without a registry update.
            %
            % Only versions >= SYSCONFIG_MIN_VERSION are accepted.
            % Deduplicated by location so registry + filesystem hits for the
            % same folder are not double-counted.

            % --- 1. Registry -------------------------------------------------
            regSubKey = [obj.CCS_REGISTRY_PARENT '\' ...
                'TI System Configuration Tool'];
            regLoc = obj.safeQueryValue( ...
                obj.CCS_REGISTRY_HIVE, regSubKey, 'Location');
            regVer = obj.safeQueryValue( ...
                obj.CCS_REGISTRY_HIVE, regSubKey, 'Version');
            regLoc = strtrim(regLoc);
            if ~isempty(regLoc) && obj.validDir(regLoc)
                % Strip build metadata e.g. '1.26.1+4441' -> '1.26.1'
                cleanVer = regexprep(regVer, '\+.*$', '');
                if obj.versionAtLeast(cleanVer, obj.SYSCONFIG_MIN_VERSION)
                    label = sprintf('SysConfig %s', cleanVer);
                    obj.sysconfigResults(end+1) = ...
                        obj.makeEntry(label, cleanVer, regLoc);
                end
            end

            % --- 2. Filesystem scan ------------------------------------------
            prefixLen = numel(obj.SYSCONFIG_DIR_PREFIX);
            for r = 1 : numel(obj.AM13X_SCAN_ROOTS)
                root = obj.AM13X_SCAN_ROOTS{r};
                if exist(root, 'dir') ~= 7
                    continue
                end
                entries = dir(root);
                for i = 1 : numel(entries)
                    if ~entries(i).isdir
                        continue
                    end
                    name = entries(i).name;
                    if ~strncmpi(name, obj.SYSCONFIG_DIR_PREFIX, prefixLen)
                        continue
                    end
                    % Version string is everything after 'sysconfig_'
                    ver     = name(prefixLen + 1 : end);   % e.g. '1.27.0'
                    fullLoc = fullfile(root, name);
                    if obj.versionAtLeast(ver, obj.SYSCONFIG_MIN_VERSION) && ...
                            obj.validDir(fullLoc)
                        label = sprintf('SysConfig %s', ver);
                        obj.sysconfigResults(end+1) = ...
                            obj.makeEntry(label, ver, fullLoc);
                    end
                end
            end

            obj.sysconfigResults = obj.deduplicate(obj.sysconfigResults);
        end

        % -----------------------------------------------------------------
        function detectIAR(obj)
            % IAR Embedded Workbench is found via the Uninstall registry.
            % The registry location ends with \arm; we strip that suffix
            % to return the Workbench root folder.

            allKeys = obj.collectUninstallKeys();

            for k = 1 : numel(allKeys)
                hive   = allKeys(k).hive;
                subKey = allKeys(k).subKey;

                displayName = obj.safeQueryValue(hive, subKey, 'DisplayName');
                if isempty(displayName)
                    continue
                end

                if ~obj.matches(displayName, obj.PATTERN_IAR)
                    continue
                end

                version = obj.safeQueryValue(hive, subKey, 'DisplayVersion');
                loc     = obj.resolveLocation(hive, subKey);
                if isempty(loc)
                    continue
                end

                % Strip trailing \arm folder - return Workbench root
                [parent, lastDir] = fileparts(loc);
                if strcmpi(lastDir, 'arm') && obj.validDir(parent)
                    loc = parent;
                end

                % Validate that this is actually an IAR installation
                % Check for characteristic IAR subdirectories or files
                if ~obj.isValidIARInstallation(loc)
                    continue
                end

                archTok = regexp(displayName, ...
                    '(?:for\s+|-)(\w+)', 'tokens', 'once');
                if ~isempty(archTok)
                    label = sprintf('IAR Embedded Workbench for %s', archTok{1});
                else
                    label = 'IAR Embedded Workbench';
                end

                obj.iarResults(end+1) = obj.makeEntry(label, version, loc);
            end

            obj.iarResults = obj.deduplicate(obj.iarResults);
        end

    end % private detection methods

    % =========================================================================
    % Private - registry access
    % =========================================================================
    methods (Access = private)

        % -----------------------------------------------------------------
        function allKeys = collectUninstallKeys(obj)
            allKeys = struct('hive', {}, 'subKey', {});
            for h = 1 : numel(obj.REGISTRY_HIVES)
                hive = obj.REGISTRY_HIVES{h};
                for u = 1 : numel(obj.UNINSTALL_SUBKEYS)
                    parent     = obj.UNINSTALL_SUBKEYS{u};
                    childNames = obj.safeQueryChildNames(hive, parent);
                    for c = 1 : numel(childNames)
                        e.hive   = hive;
                        e.subKey = [parent '\' childNames{c}];
                        allKeys(end+1) = e; %#ok<AGROW>
                    end
                end
            end
        end

        % -----------------------------------------------------------------
        function names = safeQueryChildNames(~, hive, subKey)
            % Returns immediate child sub-key names via reg.exe.
            % reg query "<hive\subKey>" lists each child as a full path;
            % we strip the parent prefix to recover the child name.
            names    = {};
            fullPath = [hive '\' subKey];
            cmd      = sprintf('reg query "%s" 2>nul', fullPath);
            try
                [status, out] = system(cmd);
            catch
                return
            end
            if status ~= 0 || isempty(strtrim(out))
                return
            end
            prefix    = [fullPath '\'];
            prefixLen = numel(prefix);
            lines     = strsplit(out, newline);
            for i = 1 : numel(lines)
                line = strtrim(lines{i});
                if numel(line) > prefixLen && strncmpi(line, prefix, prefixLen)
                    child = strtrim(line(prefixLen + 1 : end));
                    if ~isempty(child) && ~contains(child, '\')
                        names{end+1} = child; %#ok<AGROW>
                    end
                end
            end
        end

        % -----------------------------------------------------------------
        function value = safeQueryValue(~, hive, subKey, valueName)
            try
                value = winqueryreg(hive, subKey, valueName);
                if ~ischar(value)
                    value = char(value);
                end
            catch
                value = '';
            end
        end

        % -----------------------------------------------------------------
        function loc = resolveLocation(obj, hive, subKey)
            % Priority: InstallLocation > fileparts(UninstallString.exe)
            loc = '';

            candidate = obj.safeQueryValue(hive, subKey, 'InstallLocation');
            candidate = obj.cleanPath(candidate);
            if obj.validDir(candidate)
                loc = candidate;
                return
            end

            raw = obj.safeQueryValue(hive, subKey, 'UninstallString');
            raw = obj.cleanPath(raw);
            if isempty(raw), return, end

            exeTok = regexp(raw, '^(.*\.exe)', 'tokens', 'ignorecase', 'once');
            if ~isempty(exeTok)
                raw = strtrim(exeTok{1});
            end

            candidate = fileparts(raw);
            if obj.validDir(candidate)
                loc = candidate;
                return
            end
            candidate = fileparts(candidate);
            if obj.validDir(candidate)
                loc = candidate;
            end
        end

    end % private registry methods

    % =========================================================================
    % Private - utilities
    % =========================================================================
    methods (Access = private)

        % -----------------------------------------------------------------
        % -----------------------------------------------------------------
        function tf = sdkVersionAtLeast(~, verStr, minVerStr)
            % Compares underscore-separated SDK versions e.g. '26_00_00_06' >= '26_00_00_06'
            % Returns true when verStr >= minVerStr.
            tf = false;
            try
                aNums = cellfun(@str2double, strsplit(verStr,    '_'));
                bNums = cellfun(@str2double, strsplit(minVerStr, '_'));
                n = max(numel(aNums), numel(bNums));
                aNums(end+1:n) = 0;
                bNums(end+1:n) = 0;
                for i = 1:n
                    if     aNums(i) > bNums(i), tf = true;  return
                    elseif aNums(i) < bNums(i), tf = false; return
                    end
                end
                tf = true;  % equal
            catch
            end
        end

        function tf = versionAtLeast(~, verStr, minVerStr)
            % Returns true when verStr >= minVerStr.
            % Compares dot-separated numeric components only;
            % non-numeric suffixes (e.g. '+4441', 'LTS') are stripped.
            %
            % Examples:
            %   versionAtLeast('1.27.0', '1.27.0') -> true
            %   versionAtLeast('1.27.1', '1.27.0') -> true
            %   versionAtLeast('1.26.1', '1.27.0') -> false
            tf = false;
            try
                aNum = cellfun(@str2double, strsplit( ...
                    regexp(verStr,    '[\d.]+', 'match', 'once'), '.'));
                bNum = cellfun(@str2double, strsplit( ...
                    regexp(minVerStr, '[\d.]+', 'match', 'once'), '.'));
                n = max(numel(aNum), numel(bNum));
                aNum(end+1 : n) = 0;
                bNum(end+1 : n) = 0;
                for i = 1 : n
                    if     aNum(i) > bNum(i), tf = true;  return
                    elseif aNum(i) < bNum(i), tf = false; return
                    end
                end
                tf = true;  % all components equal
            catch
            end
        end

        % -----------------------------------------------------------------
        function tf = matches(~, text, pattern)
            tf = ~isempty(regexp(text, pattern, 'once'));
        end

        % -----------------------------------------------------------------
        function [major, minor] = parseMajorMinor(~, verStr)
            % Parses 'MM.mm.xx.xxxxx' -> major=MM, minor=mm.
            tok = regexp(verStr, '^(\d+)\.(\d+)', 'tokens', 'once');
            if isempty(tok)
                major = NaN;  minor = NaN;
            else
                major = str2double(tok{1});
                minor = str2double(tok{2});
            end
        end

        % -----------------------------------------------------------------
        function ver = extractVersionFromDirName(~, name)
            % Extracts version string from folder names like:
            %   ti-cgt-armllvm_4.0.4.LTS  -> '4.0.4.LTS'
            %   am13e230x_sdk_26_00_00_04  -> '26_00_00_04'
            tok = regexp(name, '[_-](\d+[\d._-]+)$', 'tokens', 'once');
            if ~isempty(tok)
                ver = tok{1};
            else
                ver = '';
            end
        end

        % -----------------------------------------------------------------
        function p = cleanPath(~, raw)
            p = strtrim(raw);
            p = strrep(p, '"', '');
            p = strtrim(p);
            if ~isempty(p) && p(end) == '\'
                p = p(1 : end-1);
            end
        end

        % -----------------------------------------------------------------
        function tf = validDir(~, path)
            tf = ~isempty(path) && ...
                (exist(path, 'dir') == 7) && ...
                ~contains(path, tempdir);
        end

        % -----------------------------------------------------------------
        function tf = isValidIARInstallation(~, path)
            % Validates that the path is a genuine IAR installation
            % by checking for characteristic subdirectories
            tf = false;
            if isempty(path) || exist(path, 'dir') ~= 7
                return
            end

            % Check for 'arm' subdirectory (IAR for ARM)
            armPath = fullfile(path, 'arm');
            if exist(armPath, 'dir') == 7
                % Further validate by checking for common IAR ARM files/folders
                % Check for bin directory with iccarm.exe or similar
                binPath = fullfile(armPath, 'bin');
                if exist(binPath, 'dir') == 7
                    tf = true;
                    return
                end
            end

            % Alternative: check if path name contains 'ewarm' (Embedded Workbench ARM)
            if contains(lower(path), 'ewarm')
                tf = true;
                return
            end
        end

        % -----------------------------------------------------------------
        function entry = makeEntry(~, toolName, version, location)
            entry.toolName = toolName;
            entry.version  = version;
            entry.location = location;
        end

        % -----------------------------------------------------------------
        function s = emptyResultStruct(~)
            s = struct('toolName', {}, 'version', {}, 'location', {});
        end

        % -----------------------------------------------------------------
        function out = deduplicate(~, entries)
            if isempty(entries)
                out = entries;
                return
            end
            locs     = {entries.location};
            [~, idx] = unique(locs, 'stable');
            out      = entries(idx);
        end

        % -----------------------------------------------------------------
        function printSection(~, title, entries)
            fprintf('\n  %s\n', title);
            fprintf('  %s\n', repmat('-', 1, numel(title)));
            if isempty(entries)
                fprintf('    [Not found]\n');
            else
                for k = 1 : numel(entries)
                    fprintf('    [%d] %s\n',        k, entries(k).toolName);
                    fprintf('        Version  : %s\n', entries(k).version);
                    fprintf('        Location : %s\n', entries(k).location);
                end
            end
        end

        % -----------------------------------------------------------------
        function assertWindows(~)
            if ~ispc
                error('detectEmbeddedTools:unsupportedPlatform', ...
                    'Registry-based detection is only supported on Windows.');
            end
        end

    end % private utility methods

end % classdef
