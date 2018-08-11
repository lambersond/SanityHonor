-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	for k,v in pairs(aDataModuleSet) do
		for _,v2 in ipairs(v) do
			Desktop.addDataModuleSet(k, v2);
		end
	end
end

aDataModuleSet = 
{
	["local"] =
	{
		{
			name = "5E - SRD",
			modules =
			{
				{ name = "DD5E SRD Bestiary" },
				{ name = "DD5E SRD Data" },
				{ name = "DD5E SRD Magic Items" },
			},
		},
		{
			name = "5E - Basic Rules",
			modules =
			{
				{ name = "DD Basic Rules - DM" },
				{ name = "DD Basic Rules - Player" },
			},
		},
		{
			name = "5E - Core Rules",
			modules =
			{
				{ name = "DD Dungeon Masters Guide", storeid = "WOTC5EDMG" },
				{ name = "DD MM Monster Manual", storeid = "WOTC5EMMDELUXE" },
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE" },
			},
		},
		{
			name = "5E - All Rules",
			modules =
			{
				{ name = "DD Dungeon Masters Guide", storeid = "WOTC5EDMG" },
				{ name = "DD MM Monster Manual", storeid = "WOTC5EMMDELUXE" },
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE" },
				{ name = "DD Curse of Strahd Players", storeid = "WOTC5ECOS" },
				{ name = "DD Elemental Evil Players Companion", storeid = "WOTC5EEEPC" },
				{ name = "D&D Sword Coast Adventurer's Guide - Player's Guide", storeid = "WOTC5ESCAG" },
				{ name = "Volos Guide to Monsters Players", storeid = "WOTC5EVGM" },
			},
		},
	},
	["client"] =
	{
		{
			name = "5E - SRD",
			modules =
			{
				{ name = "DD5E SRD Data" },
			},
		},
		{
			name = "5E - Basic Rules",
			modules =
			{
				{ name = "DD Basic Rules - Player" },
			},
		},
		{
			name = "5E - Core Rules",
			modules =
			{
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE" },
			},
		},
		{
			name = "5E - All Rules",
			modules =
			{
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE" },
				{ name = "DD Curse of Strahd Players", storeid = "WOTC5ECOS" },
				{ name = "DD Elemental Evil Players Companion", storeid = "WOTC5EEEPC" },
				{ name = "D&D Sword Coast Adventurer's Guide - Player's Guide", storeid = "WOTC5ESCAG" },
				{ name = "Volos Guide to Monsters Players", storeid = "WOTC5EVGM" },
			},
		},
	},
	["host"] =
	{
		{
			name = "5E - SRD",
			modules =
			{
				{ name = "DD5E SRD Bestiary" },
				{ name = "DD5E SRD Data" },
				{ name = "DD5E SRD Magic Items" },
			},
		},
		{
			name = "5E - Basic Rules",
			modules =
			{
				{ name = "DD Basic Rules - DM" },
				{ name = "DD Basic Rules - Player" },
			},
		},
		{
			name = "5E - Core Rules",
			modules =
			{
				{ name = "DD Dungeon Masters Guide", storeid = "WOTC5EDMG" },
				{ name = "DD MM Monster Manual", storeid = "WOTC5EMMDELUXE" },
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE" },
			},
		},
		{
			name = "5E - All Rules",
			modules =
			{
				{ name = "DD Dungeon Masters Guide", storeid = "WOTC5EDMG" },
				{ name = "DD MM Monster Manual", storeid = "WOTC5EMMDELUXE" },
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE" },
				{ name = "DD Curse of Strahd Players", storeid = "WOTC5ECOS" },
				{ name = "DD Elemental Evil Players Companion", storeid = "WOTC5EEEPC" },
				{ name = "D&D Sword Coast Adventurer's Guide - Player's Guide", storeid = "WOTC5ESCAG" },
				{ name = "D&D Sword Coast Adventurer's Guide - Campaign Guide", storeid = "WOTC5ESCAG" },
				{ name = "DD Volos Guide to Monsters", storeid = "WOTC5EVGM" },
				{ name = "Volos Guide to Monsters Players", storeid = "WOTC5EVGM" },
			},
		},
	},
};
