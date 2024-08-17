-- Vars
terminal = sc.getTerminals()[1]
networkPort = sc.getNetworkPorts()[1]
speaker = sc.getSpeakers()[1]
term = false
con = false
oldcon = false
beep = false
stop = false
settingname = true
changename = false
getnames = false

version = "0.1.3"
commands = {"/help", "/info", "/changename", "/breakcon", "/entercon", "/names"}
name = ""

-- Functions
function send(text) if term then terminal.send(text) end end
function syssend(text) if term then terminal.send("#3A96DD"..text) end end
function errsend(errortext) if term then terminal.send("#9e0000ERROR: "..errortext) end end

function split(message)
    subString1 = message:match("^(.-)%s")
    subString2 = message:match("%s(.-)$")
    return subString1, subString2
end

function setname(text)
    settingname = false local oldname = name name = text
    if name == nil or name == "" or name == "system" or name == "sysname" then name = "User" end
    syssend("Your name now is: " .. name .. "\nYou can use /help to see all commands.\n")
    if changename == false then enterchat()
    elseif changename == true then networkPort.sendPacket("system User " .. oldname .. " change name to " .. name) end
end

function errnocon()
    errsend("To use SayHello you need to have network port and antenna!")
    syssend("You can`t use internet features but you still can use commands, /help to see all commands.\n")
    stop = true
end
function exitchat() if con then networkPort.sendPacket("system User " .. name .. " exit chat.") end end
function enterchat() if con then networkPort.sendPacket("system User " .. name .. " enter chat.") end end

-- Commands
function incommands(com) local ia = false for i,v in ipairs(commands) do if v == com then ia = true end end return ia end
function command(com)
    if com == "/help" then syssend("Command List:\n/help - list of all commands.\n/info - information.\n/changename - Change name to new.\n/names - Get names of all connected users\n/breakcon - stop connection\n/entercon - resume connection.\n")
    elseif com == "/info" then syssend("Information:\nname: "..name.."\nversion: "..version.."\nterminal: "..tostring(term).."\nnetwork connecton: "..tostring(con).."\nspeaker: "..tostring(beep).."\n")
    elseif com == "/breakcon" then exitchat() oldcon = con con = false stop = true syssend("Connection stopped, you can`t use internet features but you still can use commands, /help to see all commands.\n")
    elseif com == "/entercon" then enterchat() if oldcon then con = true stop = false end syssend("Connection continued, you can use internet features and commands, /help to see all commands.\n")
    elseif com == "/changename" then changename = true settingname = true send("Enter your new name: ")
    elseif com == "/names" then if con then getnames = true networkPort.sendPacket("system /names") end end
end

-- Program functions
function onLoad() -- On start
    if terminal == nil then stop = true else term = true end -- Check terminal
    if speaker ~= nil then beep = true end -- Check speaker

    if stop == false then
        terminal.clear()
        send("#3A96DDSayHello "..version.." - Free and open source computer chat for Scrap Mechanic!")

        -- Check of network
        if networkPort == nil then errnocon()
        elseif not networkPort.hasConnection() then errnocon()
        else con = true end
    end

    if stop == false then send("Enter your name: ") end -- If have network, enter name
end
function onUpdate() -- On update
	if stop == false then -- If all good
        if terminal.receivedInputs() then -- Send message
            local text = terminal.getInput()

            if settingname == false then -- Send message
                if incommands(text) then command(text)
                elseif name ~= nil and name ~= "" then
                    send(" > " .. text)
                    networkPort.sendPacket(name .. " ".. text)
                end
            else if con then setname(text) end end -- Set name
        end
        if networkPort.getTotalPackets() > 0 and not settingname then -- Input message
            if beep then speaker.beep() end
            local packet = networkPort.receivePacket() local packetAuthor = "" local packetText = ""
            packetAuthor, packetText = split(packet)
            if packetAuthor == nil or packetAuthor == "" then packetAuthor = "User" end -- Fix author name

            if packetAuthor == "system" then
                if packetText ~= "/names" then syssend(packetText) -- System message
                else networkPort.sendPacket("sysname " .. name) end -- Names
            elseif packetAuthor == "sysname" then if getnames then syssend(packetText) end -- System message
            else send(packetAuthor .. " > " .. packetText) end -- User message
        end
    else
        if not con and terminal.receivedInputs() then -- If dont has network
            local text = terminal.getInput()
            if incommands(text) then command(text) end -- Commands
        end
    end
end
function onDestroy() -- On shutdown
    if con then exitchat() end
    if term then terminal.clear() terminal.clearInputHistory() end
end
function onError(err) errsend(err) end -- On error

-- TODO
-- 0.1.4
    -- Исправить - нельзя иметь ник с пробелом
    -- Сохранение всего на диске.
