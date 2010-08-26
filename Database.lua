local myname, ns = ...

ns.defaults = {}

function ns.InitDB()
	_G[myname.."DB"] = _G[myname.."DB"] or {}
	ns.db = {} --_G[myname.."DB"]
	
	ns.factionrealm = UnitFactionGroup("player") .. "-" .. GetRealmName()
	ns.db[ns.factionrealm] = ns.db[ns.factionrealm] or {}
	
	ns.char = UnitName("player")
	ns.db[ns.factionrealm][ns.char] = ns.db[ns.factionrealm][ns.char] or {}
end


function ns.FlushDB()
	-- for i,v in pairs(ns.defaults) do if ns.db[i] == v then ns.db[i] = nil end end
	-- 	for i,v in pairs(ns.defaultsPC) do if ns.dbpc[i] == v then ns.dbpc[i] = nil end end
	
	ns.db = ns.defaults
end
