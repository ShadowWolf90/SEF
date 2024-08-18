if SERVER then
    
    function LoadSEFFiles()
        local folder = "SEF"
        local files, directories = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            AddCSLuaFile(filepath)
            include(filepath)
            print("[Status Effect Framework] File " .. filename .. " has been loaded.")
        end
    end

    concommand.Add("SEF_Reload", function(ply, cmd, args)
        LoadSEFFiles()
        for _, v in ipairs(player.GetAll()) do
            v:ConCommand("SEF_Reload_Client")
        end
    end, nil, "Reloads whole Status Effect Framework.")

    hook.Add("InitPostEntity", "LoadSEFSystemServer", function() 
        LoadSEFFiles()
    end)
else

    local function LoadSEFFilesClient()
        local folder = "SEF"
        local files, directories = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            include(filepath)
            print("[Status Effect Framework] Client file " .. filename .. " has been loaded.")
        end
    end

    hook.Add("InitPostEntity", "LoadSEFSystemServer", function()
        LoadSEFFilesClient() 
    end)

    concommand.Add("SEF_Reload_Client", function()
        LoadSEFFilesClient()
    end)
end
