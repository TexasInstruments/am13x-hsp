function rtwTargetInfo(tr)
loc_registerThisTarget();
tr.registerTargetInfo(@loc_createPILConfig);
codertarget.TargetRegistry.addToTargetRegistry(@loc_registerThisTarget);
codertarget.TargetBoardRegistry.addToTargetBoardRegistry(@loc_registerBoardsForThisTarget);
end
 
% -------------------------------------------------------------------------
function isConfigSetCompatible = i_isConfigSetCompatible(configSet)
isConfigSetCompatible = false;
if configSet.isValidParam('CoderTargetData')
data = getParam(configSet,'CoderTargetData');
targetHardware = data.TargetHardware;
hwSupportingPIL = { 'AM13E230x' };
for i=1:numel(hwSupportingPIL)
if isequal(hwSupportingPIL{i},targetHardware)
isConfigSetCompatible = true;
break
end
end
end
end
 
% -------------------------------------------------------------------------
function config = loc_createPILConfig
config(1) = rtw.connectivity.ConfigRegistry;
config(1).ConfigName = 'am13x';
config(1).ConfigClass = 'am13x.pil.ConnectivityConfig';
config(1).isConfigSetCompatibleFcn = @i_isConfigSetCompatible;
end
 
% -------------------------------------------------------------------------
function boardInfo = loc_registerBoardsForThisTarget
target = 'AM13X';
[targetFolder, ~, ~] = fileparts(mfilename('fullpath'));
boardFolder = codertarget.target.getTargetHardwareRegistryFolder(targetFolder);
boardInfo = codertarget.target.getTargetHardwareInfo(targetFolder, boardFolder, target);
end
 
% -------------------------------------------------------------------------
function ret = loc_registerThisTarget
ret.Name = 'AM13X';
[targetFilePath, ~, ~] = fileparts(mfilename('fullpath'));
ret.TargetFolder = targetFilePath;
ret.TargetVersion = 1;
ret.AliasNames = {};
ret.ReferenceTargets = { 'ARM Cortex-M' };
end
