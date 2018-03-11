local args = {...}
local currentProg = shell.getRunningProgram():sub(shell.dir():len() + 2, -5 )
local aptListDir = "/.ccapt/sources.list.d"
local aptList = "/.ccapt/sources.list"
local linkPattern = "^http"
local parameters = { "install", "remove", "upgrade", "add-server", "remove-server" }

local function capLine(line, width)
	if not width then
		width = ({term.getSize()})[1]
	end

	local lines = {}
	while line:len() > width do
		table.insert(lines, line:sub(1,width-1))
		line = line:sub(width)
	end
	table.insert(lines, line)
	return lines
end

local function helpLine(lines, command, description)
	table.insert(lines, "* "..command)
	for _,line in pairs(capLine("--"..description, ({term.getSize()})[1] - 2)) do
		table.insert(lines, "  "..line)
	end
	table.insert(lines, "")
end

local function downScroll(lines)
	local scrHeight = ({term.getSize()})[2] - 1
	local printed = 0
	while #lines > printed and scrHeight > printed do
		print(lines[printed + 1])
		printed = printed + 1
	end
	
	if #lines <= printed then
		return
	end
	
	local doScroll = true
	while doScroll and #lines > printed do
		local cx, cy = term.getCursorPos()
		term.setCursorPos(1,scrHeight+1)
		local bg = term.getBackgroundColor()
		local fg = term.getTextColor()
		term.setTextColor(colors.black)
		term.setBackgroundColor(colors.white)
		term.write(":More [Press any key] :Exit [Press q]")
		term.setTextColor(fg)
		term.setBackgroundColor(bg)
		term.setCursorPos(cx,cy)
	
	
		local ev, char = os.pullEvent("char")
		if char:lower() == "q" then
			term.clearLine()
			doScroll = false
		else
			term.clearLine()
			print(lines[printed + 1])
			printed = printed + 1
		end
	end
end

local function readAptSourceLists(listFiles)
	if listFiles == nil then
		listFiles = { aptList}
		for _,fileName in pairs(fs.list(aptListDir)) do
			table.insert(listFiles, aptListDir.."/"..fileName)
		end
	end
	
	local servers = {}
	for _,fileName in pairs(listFiles) do
		local file = fs.open(fileName,"r")
		local line = file.readLine()
		while line ~= nil do
			if line:match(linkPattern) then
				if not servers[line] then
					servers[line] = {}
				end
				servers[line][fileName] = true
			end
			line = file.readLine()
		end
		file.close()
	end
	return servers
end

fs.makeDir(aptListDir)
fs.open(aptList,"a").close() -- create apt list file
shell.setCompletionFunction(shell.getRunningProgram(), function(shell, parNumber, curParam, prevParams)  -- autocomplete
	
	local nextParam = nil
	if #prevParams == 0 then
		return {}
	elseif #prevParams == 1 then
		nextParam = parameters
	elseif #prevParams == 2 and prevParams[2] == "remove-server" then
		nextParam = {}
		for src, _ in pairs(readAptSourceLists({aptList})) do
			table.insert(nextParam, src)
		end
	else
		return {}
	end
		
	
	local pParams = {}
	for _,pParam in pairs(nextParam) do
		if pParam:sub(1,#curParam) == curParam then
			table.insert(pParams, pParam:sub(#curParam+1,#pParam) .. " ")
		end
	end
	return pParams
end)

if #args < 1 or args[1] == "help" then
	term.clear()
	local lines = {"Help:", "Usage: "..currentProg .. " ..."}
	helpLine(lines, "install <programname> [serveradress]","installes a program from standard servers or from a optional server.")
	helpLine(lines, "remove <programname>","removes a program from computer.")
	helpLine(lines, "upgrade [programname]","upgrades all installed programes or a specific program (if installed).")
	helpLine(lines, "add-server <serveradress>","adds a server to your Serverlist.")
	helpLine(lines, "remove-server <serveradress>","removes a server from your Serverlist.")
	downScroll(lines)

elseif args[1] == "add-server" and #args == 2 then
	local lists = readAptSourceLists({aptList})
	if not args[2]:match(linkPattern) then
		print("'"..args[2].."' is not a valid url")
	elseif lists[args[2]] ~= nil and lists[args[2]][aptList] == true then
		print("Already added")
	else
		local aptSrcFile = fs.open(aptList,"a")
		aptSrcFile.write(args[2].."\n")
		aptSrcFile.close()
		print("'"..args[2].."' added as source to '"..aptList.."'")
	end

elseif args[1] == "remove-server" and #args == 2 then
	local lists = readAptSourceLists()
	if lists[args[2]] == nil then
		print("Not found in 'sources.list'")
	elseif not lists[args[2]][aptList] then
		print("Not found in 'sources.list', but in other source files (have to be removed manually):")
		for aptFile, _ in pairs(lists[args[2]]) do
			print("*) '"..aptFile.."'")
		end
	else
		fs.move(aptList, aptList..".tmp")
		local aptSrcFile = fs.open( aptList..".tmp","r")
		local aptSrcFileN = fs.open( aptList,"w")
		local line = aptSrcFile.readLine()
		while line do
			if line ~= args[2] then
				aptSrcFileN.write(line.."\n")
			end
			line = aptSrcFile.readLine()
		end
		aptSrcFile.close()
		aptSrcFileN.close()
		fs.delete(aptList..".tmp")
		print("Removed successfully")
	end
		
end
