-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
OOB_MSGTYPE_APPLYCONC = "applyconc";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCONC, handleApplyConc);

	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerResultHandler("save", onSave);

	ActionsManager.registerModHandler("death", modSave);
	ActionsManager.registerResultHandler("death", onDeathRoll);

	ActionsManager.registerModHandler("concentration", modSave);
	ActionsManager.registerResultHandler("concentration", onConcentrationRoll);
end

function handleApplySave(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	local rOrigin = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.sSaveDesc = msgOOB.sSaveDesc;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	rAction.sResult = msgOOB.sResult;
	rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);
	
	applySave(rSource, rOrigin, rAction);
end

function notifyApplySave(rSource, bSecret, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.sSaveDesc = rRoll.sSaveDesc;
	msgOOB.nTarget = rRoll.nTarget;
	msgOOB.sResult = rRoll.sResult;
	if rRoll.bRemoveOnMiss then msgOOB.nRemoveOnMiss = 1; end

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	if rRoll.sSource ~= "" then
		msgOOB.sTargetType = "ct";
		msgOOB.sTargetNode = rRoll.sSource;
	else
		msgOOB.sTargetType = "";
		msgOOB.sTargetNode = "";
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function performRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
	local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d20" };
	local nMod, bADV, bDIS, sAddText = ActorManager2.getSave(rActor, sSave);
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[SAVE] " .. StringManager.capitalize(sSave);
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	
	rRoll.bSecret = bSecretRoll;
	rRoll.nTarget = nTargetDC;

	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSave(rSource, rTarget, rRoll)
	local bAutoFail = false;

	local sSave = nil;
	if rRoll.sDesc:match("%[DEATH%]") then
		sSave = "death";
	elseif rRoll.sDesc:match("%[CONCENTRATION%]") then
		sSave = "concentration";
	else
		sSave = rRoll.sDesc:match("%[SAVE%] (%w+)");
		if sSave then
			sSave = sSave:lower();
		end
	end

	local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	local nCover = 0;
	if sSave == "dexterity" then
		if rRoll.sSaveDesc then
			nCover = tonumber(rRoll.sSaveDesc:match("%[COVER %-(%d)%]")) or 0;
		else
			if ModifierStack.getModifierKey("DEF_SCOVER") then
				nCover = 5;
			elseif ModifierStack.getModifierKey("DEF_COVER") then
				nCover = 2;
			end
		end
	end
	
	if rSource then
		local bEffects = false;

		-- Build filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end

		-- Get effect modifiers
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.getActor("ct", rRoll.sSource);
		end
		local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"SAVE"}, false, aSaveFilter, rSaveSource);
		if nEffectCount > 0 then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager5E.hasEffect(rSource, "ADVSAV", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVSAV", aSaveFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		elseif sSave == "death" and EffectManager5E.hasEffect(rSource, "ADVDEATH") then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffect(rSource, "DISSAV", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISSAV", aSaveFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		elseif sSave == "death" and EffectManager5E.hasEffect(rSource, "DISDEATH") then
			bDIS = true;
			bEffects = true;
		end
		if sSave == "dexterity" then
			if EffectManager5E.hasEffectCondition(rSource, "Restrained") then
				bDIS = true;
				bEffects = true;
			end
			if nCover < 5 then
				if EffectManager5E.hasEffect(rSource, "SCOVER", rTarget) then
					nCover = 5;
					bEffects = true;
				elseif nCover < 2 then
					if EffectManager5E.hasEffect(rSource, "COVER", rTarget) then
						nCover = 2;
						bEffects = true;
					end
				end
			end
		end
		if StringManager.contains({ "strength", "dexterity" }, sSave) then
			if EffectManager5E.hasEffectCondition(rSource, "Paralyzed") then
				bAutoFail = true;
				bEffects = true;
			end
			if EffectManager5E.hasEffectCondition(rSource, "Stunned") then
				bAutoFail = true;
				bEffects = true;
			end
			if EffectManager5E.hasEffectCondition(rSource, "Unconscious") then
				bAutoFail = true;
				bEffects = true;
			end
		end
		if StringManager.contains({ "strength", "dexterity", "constitution", "concentration" }, sSave) then
			if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
				bEffects = true;
				bDIS = true;
			end
		end
		if sSave == "dexterity" and EffectManager5E.hasEffectCondition(rSource, "Dodge") and 
				not (EffectManager5E.hasEffectCondition(rSource, "Paralyzed") or
				EffectManager5E.hasEffectCondition(rSource, "Stunned") or
				EffectManager5E.hasEffectCondition(rSource, "Unconscious") or
				EffectManager5E.hasEffectCondition(rSource, "Incapacitated") or
				EffectManager5E.hasEffectCondition(rSource, "Grappled") or
				EffectManager5E.hasEffectCondition(rSource, "Restrained")) then
			bEffects = true;
			bADV = true;
		end
		if rRoll.sSaveDesc then
			if rRoll.sSaveDesc:match("%[MAGIC%]") then
				if EffectManager5E.hasEffectCondition(rSource, "Magic Resistance") then
					bEffects = true;
					bADV = true;
				end
			end
		end

		-- Get ability modifiers
		local sTemp = nil;
		if sSave == "concentration" then
			sTemp = "constitution";
		elseif sSave ~= "death" then
			sTemp = sSave;
		end
		if sSave then
			local nBonusStat, nBonusEffects = ActorManager2.getAbilityEffectsBonus(rSource, sSave);
			if nBonusEffects > 0 then
				bEffects = true;
				nAddMod = nAddMod + nBonusStat;
			end
		end
		
		-- Get exhaustion modifiers
		local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		if nExhaustCount > 0 then
			bEffects = true;
			if nExhaustMod >= 3 then
				bDIS = true;
			end
		end
		
		-- If effects apply, then add note
		if bEffects then
			for _, vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
			
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end

		-- Handle War Caster feat
		if sSave == "concentration" and ActorManager.isPC(rSource) and CharManager.hasFeat(ActorManager.getCreatureNode(rSource), CharManager.FEAT_WAR_CASTER) then
			bADV = true;
			rRoll.sDesc = rRoll.sDesc .. " [" .. CharManager.FEAT_WAR_CASTER:upper() .. "]";
		end
	end
	
	if nCover > 0 then
		rRoll.nMod = rRoll.nMod + nCover;
		rRoll.sDesc = rRoll.sDesc .. string.format(" [COVER +%d]", nCover);
	end
	
	ActionsManager2.encodeDesktopMods(rRoll);
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
	
	if bAutoFail then
		rRoll.sDesc = rRoll.sDesc .. " [AUTOFAIL]";
	end
end

function onSave(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		notifyApplySave(rSource, rMessage.secret, rRoll);
	end
end

function applySave(rSource, rOrigin, rAction, sUser)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Save";
	msgLong.text = "Save [" .. rAction.nTotal ..  "]";
	if rAction.nTarget > 0 then
		msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. rSource.sName .. "]";
		msgLong.text = msgLong.text .. " [for " .. rSource.sName .. "]";
	end
	if rOrigin then
		msgShort.text = msgShort.text .. " [vs " .. rOrigin.sName .. "]";
		msgLong.text = msgLong.text .. " [vs " .. rOrigin.sName .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	local sAttack = "";
	local bHalfMatch = false;
	if rAction.sSaveDesc then
		sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
		bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
	end
	rAction.sResult = "";
	
	if rAction.nTarget > 0 then
		if rAction.nTotal >= rAction.nTarget then
			msgLong.text = msgLong.text .. " [SUCCESS]";
			
			if rSource then
				local bHalfDamage = bHalfMatch;
				local bAvoidDamage = false;
				if bHalfDamage then
					if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
						bAvoidDamage = true;
						msgLong.text = msgLong.text .. " [AVOIDANCE]";
					elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
						local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
						if sSave then
							sSave = sSave:lower();
						end
						if sSave == "dexterity" then
							bAvoidDamage = true;
							msgLong.text = msgLong.text .. " [EVASION]";
						end
					end
				end
				
				if bAvoidDamage then
					rAction.sResult = "none";
					rAction.bRemoveOnMiss = false;
				elseif bHalfDamage then
					rAction.sResult = "half_success";
					rAction.bRemoveOnMiss = false;
				end
				
				if rOrigin and rAction.bRemoveOnMiss then
					TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
				end
			end
		else
			msgLong.text = msgLong.text .. " [FAILURE]";

			if rSource then
				local bHalfDamage = false;
				if bHalfMatch then
					if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
						bHalfDamage = true;
						msgLong.text = msgLong.text .. " [AVOIDANCE]";
					elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
						local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
						if sSave then
							sSave = sSave:lower();
						end
						if sSave == "dexterity" then
							bHalfDamage = true;
							msgLong.text = msgLong.text .. " [EVASION]";
						end
					end
				end
				
				if bHalfDamage then
					rAction.sResult = "half_failure";
				end
			end
		end
	end
	
	ActionsManager.messageResult(bSecret, rSource, rOrigin, msgLong, msgShort);
	
	if rSource and rOrigin then
		ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
	end
end

--
--  Death saving throw
--

function performDeathRoll(draginfo, rActor)
	local rRoll = { };
	rRoll.sType = "death";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[DEATH]";
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onDeathRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if ActorManager2.getPercentWounded(rSource) >= 1 then
		local nTotal = ActionsManager.total(rRoll);
		
		local bStatusCheck = true;
		local _,sOriginalStatus = ActorManager2.getPercentWounded(rSource);
		
		local nFirstDie = 0;
		if #(rRoll.aDice) > 0 then
			nFirstDie = rRoll.aDice[1].result or 0;
		end
		if nFirstDie == 1 then
			rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
			
			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			local nodeSource = nil;
			if sSourceType == "pc" or sSourceType == "ct" then
				nodeSource = DB.findNode(sSourceNode);
			end
			if nodeSource then
				local nValue = DB.getValue(nodeSource, "hp.deathsavefail", 0);
				if nValue < 3 then
					nValue = math.min(nValue + 2, 3);
					DB.setValue(nodeSource, "hp.deathsavefail", "number", nValue);
				end
			end
		elseif nFirstDie == 20 then
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
			
			ActionDamage.applyDamage(nil, rSource, rRoll.bSecret, "[HEAL]", 1);
			bStatusCheck = false;
		elseif nTotal >= 10 then
			rMessage.text = rMessage.text .. " [SUCCESS]";

			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			local nodeSource = nil;
			if sSourceType == "pc" or sSourceType == "ct" then
				nodeSource = DB.findNode(sSourceNode);
			end
			if nodeSource then
				local nValue = DB.getValue(nodeSource, "hp.deathsavesuccess", 0);
				if nValue < 3 then
					nValue = nValue + 1;
					DB.setValue(nodeSource, "hp.deathsavesuccess", "number", nValue);
				end
				if nValue >= 3 then
					local aEffect = { sName = "Stable", nDuration = 0 };
					if ActorManager.getFaction(rSource) ~= "friend" then
						aEffect.nGMOnly = 1;
					end
					EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), aEffect, true);
				end
			end
		else
			rMessage.text = rMessage.text .. " [FAILURE]";

			local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
			local nodeSource = nil;
			if sSourceType == "pc" or sSourceType == "ct" then
				nodeSource = DB.findNode(sSourceNode);
			end
			if nodeSource then
				local nValue = DB.getValue(nodeSource, "hp.deathsavefail", 0);
				if nValue < 3 then
					DB.setValue(nodeSource, "hp.deathsavefail", "number", nValue + 1);
				end
			end
		end
		
		if bStatusCheck then
			local bShowStatus = false;
			if ActorManager.getFaction(rTarget) == "friend" then
				bShowStatus = not OptionsManager.isOption("SHPC", "off");
			else
				bShowStatus = not OptionsManager.isOption("SHNPC", "off");
			end
			if bShowStatus then
				local _,sNewStatus = ActorManager2.getPercentWounded(rSource);
				if sOriginalStatus ~= sNewStatus then
					rMessage.text = rMessage.text .. " [" .. Interface.getString("combat_tag_status") .. ": " .. sNewStatus .. "]";
				end
			end
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

--
--  Concentration saving throw
--

function hasConcentrationEffects(rSource)
	return #(getConcentrationEffects(rSource)) > 0;
end

function getConcentrationEffects(rSource)
	local aEffects = {};
	
	local nodeCTSource = ActorManager.getCTNode(rSource);
	if nodeCTSource then
		local sCTNodeSource = nodeCTSource.getPath();
		for _,nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
			local sCTNode = nodeCT.getPath();
			for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
				local bSourceMatch = false;
				if sCTNode == sCTNodeSource then
					if DB.getValue(nodeEffect, "source_name", "") == "" then
						bSourceMatch = true;
					end
				else
					if DB.getValue(nodeEffect, "source_name", "") == sCTNodeSource then
						bSourceMatch = true;
					end
				end
				if bSourceMatch then
					if DB.getValue(nodeEffect, "label", ""):match("%([cC]%)") then
						table.insert(aEffects, { nodeCT = nodeCT, nodeEffect = nodeEffect });
					end
				end
			end
		end
	end
	
	return aEffects;
end

function handleApplyConc(msgOOB)
	local rSource = ActorManager.getActor(msgOOB.sSourceType, msgOOB.sSourceNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	
	applyConcentrationRoll(rSource, rAction);
end

function notifyApplyConc(rSource, bSecret, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYCONC;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.nTarget = rRoll.nTarget;

	local sSourceType, sSourceNode = ActorManager.getTypeAndNodeName(rSource);
	msgOOB.sSourceType = sSourceType;
	msgOOB.sSourceNode = sSourceNode;

	Comm.deliverOOBMessage(msgOOB, "");
end

function performConcentrationRoll(draginfo, rActor, nTargetDC)
	local rRoll = { };
	rRoll.sType = "concentration";
	rRoll.aDice = { "d20" };
	local nMod, bADV, bDIS, sAddText = ActorManager2.getSave(rActor, "constitution");
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[CONCENTRATION]";
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	rRoll.nTarget = nTargetDC;
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onConcentrationRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		notifyApplyConc(rSource, rMessage.secret, rRoll);
	end
end

function applyConcentrationRoll(rSource, rAction)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Concentration";
	msgLong.text = "Concentration [" .. rAction.nTotal ..  "]";
	if rAction.nTarget > 0 then
		msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. rSource.sName .. "]";
		msgLong.text = msgLong.text .. " [for " .. rSource.sName .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	if rAction.nTotal >= rAction.nTarget then
		msgLong.text = msgLong.text .. " [SUCCESS]";
	else
		msgLong.text = msgLong.text .. " [FAILURE]";
	end
	
	ActionsManager.messageResult(bSecret, rSource, nil, msgLong, msgShort);
	
	-- On failed concentration check, remove all effects with the same source creature
	if rAction.nTotal < rAction.nTarget then
		expireConcentrationEffects(rSource);
	end
end

function expireConcentrationEffects(rSource)
	local aSourceConcentrationEffects = getConcentrationEffects(rSource);
	for _,v in ipairs(aSourceConcentrationEffects) do
		EffectManager.expireEffect(v.nodeCT, v.nodeEffect, 0);
	end
end
