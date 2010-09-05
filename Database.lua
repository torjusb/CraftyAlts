local myname, ns = ...

function ns.InitDB()
	_G[myname.."DB"] = _G[myname.."DB"] or {}
	ns.db = _G[myname.."DB"]
	
	ns.factionrealm = UnitFactionGroup("player") .. "-" .. GetRealmName()
	ns.db[ns.factionrealm] = ns.db[ns.factionrealm] or {}
	
	ns.char = UnitName("player")
	ns.db[ns.factionrealm][ns.char] = ns.db[ns.factionrealm][ns.char] or {}
end