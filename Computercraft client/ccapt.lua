local args = {...}
local currentProg = shell.getRunningProgram():sub(shell.dir():len() + 2, -5 )

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




if #args < 1 then
	term.clear()
	local lines = {"Help:", "Usage: "..currentProg .. " ..."}
	helpLine(lines, "install <programname> [serveradress]","installes a programm from standard servers or from a optional server.")
	helpLine(lines, "remove <programname>","removes a programm from computer.")
	helpLine(lines, "upgrade [programname]","upgrades a programm (if installed).")
	helpLine(lines, "add-server <serveradress>","adds a server to your Serverlist.")
	helpLine(lines, "remove-server <serveradress>","removes a server from your Serverlist.")
	downScroll(lines)
end
