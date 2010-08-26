local myname, ns = ...

_G["SLASH_".. myname:upper().."1"] = "/caflush"
SlashCmdList[myname:upper()] = function(msg)
	-- Do crap here
	ns.FlushDB()
end
