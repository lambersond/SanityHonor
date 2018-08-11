-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bReadOnly, bHide)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly, bHide);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	
	local bWeapon, sTypeLower, sSubtypeLower = ItemManager2.isWeapon(nodeRecord);
	local bArmor = ItemManager2.isArmor(nodeRecord);
	local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");
	
	local bSection = false;
	if updateControl("type", bReadOnly) then bSection = true; end
	if updateControl("subtype", bReadOnly) then bSection = true; end
	if updateControl("rarity", bReadOnly) then bSection = true; end
	
	local bSection2 = false;
	if updateControl("cost", bReadOnly) then bSection2 = true; end
	if updateControl("weight", bReadOnly) then bSection2 = true; end
	
	local bSection3 = false;
	if updateControl("bonus", bReadOnly, (bWeapon or bArmor or bArcaneFocus)) then bSection3 = true; end
	if updateControl("damage", bReadOnly, bWeapon) then bSection3 = true; end
	
	if updateControl("ac", bReadOnly, bArmor) then bSection3 = true; end
	if updateControl("dexbonus", bReadOnly, bArmor) then bSection3 = true; end
	if updateControl("strength", bReadOnly, bArmor) then bSection3 = true; end
	if updateControl("stealth", bReadOnly, bArmor) then bSection3 = true; end

	if updateControl("properties", bReadOnly, (bWeapon or bArmor)) then bSection3 = true; end
	
	description.setReadOnly(bReadOnly);
	
	divider.setVisible(bSection2 and bSection3);
	divider2.setVisible((bSection or bSection2) and bSection3);
	divider3.setVisible(bSection or bSection2 or bSection3);
end
