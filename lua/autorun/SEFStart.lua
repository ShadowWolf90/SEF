function LoadSEFFiles()
    local folder = "SEF"
    local files, directories = file.Find(folder .. "/*.lua", "LUA")

    for _, filename in ipairs(files) do
        local filepath = folder .. "/" .. filename
        if SERVER then
            AddCSLuaFile(filepath)
        end
        include(filepath)
        print("[Status Effect Framework] File " .. filename .. " has been loaded.")
    end

    concommand.Add("SEF_Reload", function(ply, cmd, args)
        LoadSEFFiles()
    end, nil, "Reloads whole Status Effect Framework.")
end

LoadSEFFiles()