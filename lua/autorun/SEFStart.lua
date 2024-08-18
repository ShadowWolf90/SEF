if SERVER then

    local function LoadSEFFiles(folder)
        local files, _ = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            AddCSLuaFile(filepath)
            include(filepath)
            print("[Status Effect Framework] File " .. filename .. " has been loaded.")
        end
    end

    hook.Add("InitPostEntity", "LoadSEFSystemServer", function() 
        LoadSEFFiles("SEF")
        LoadSEFFiles("SEF_Addon")
    end)

    concommand.Add("SEF_Reload", function(ply, cmd, args)
        LoadSEFFiles("SEF")
        LoadSEFFiles("SEF_Addon")
        for _, v in ipairs(player.GetAll()) do
            v:ConCommand("SEF_Reload_Client")
        end
    end, nil, "Reloads whole Status Effect Framework.")

else
    
    local function LoadSEFFilesClient(folder)
        local files, _ = file.Find(folder .. "/*.lua", "LUA")

        for _, filename in ipairs(files) do
            local filepath = folder .. "/" .. filename
            include(filepath)
            print("[Status Effect Framework] Client file " .. filename .. " has been loaded.")
        end
    end

    hook.Add("InitPostEntity", "LoadSEFSystemClient", function()
        LoadSEFFilesClient("SEF")
        LoadSEFFilesClient("SEF_Addon") 
    end)

    concommand.Add("SEF_Reload_Client", function()
        LoadSEFFilesClient("SEF")
        LoadSEFFilesClient("SEF_Addon")
    end)
end
