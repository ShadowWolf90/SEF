if SERVER then

    util.AddNetworkString("StatusEffectAdd")
    util.AddNetworkString("StatusEffectRemove")
    util.AddNetworkString("StatusEffectEntityAdd")
    util.AddNetworkString("StatusEffectEntityRemove")
    util.AddNetworkString("StatusEffectUpdateData")
    util.AddNetworkString("StatusEffectPassiveAdd")
    util.AddNetworkString("StatusEffectPassiveRemove")

    local ENTITY = FindMetaTable("Entity")
    EntActiveEffects = {}
    EntActivePassives = {}

    function ENTITY:ApplyEffect(effectName, time, ...)
        local effect = StatusEffects[effectName]
        if effect and (self:IsPlayer() or self:IsNPC() or self:IsNextBot()) then

            local EntID = self:EntIndex()

            if not EntActiveEffects[EntID] then
                print("[Status Effect Framework] Status Effect Table created for entity:", self)
                EntActiveEffects[EntID] = {}
            end

            if not EntActiveEffects[EntID][effectName] then
                print("[Status Effect Framework] Applied Effect:", effectName, "to entity:", self)
            end

            local args = {...}
            EntActiveEffects[EntID][effectName] = {
                Function = effect.Effect,
                StartTime = CurTime(),
                Duration = time,
                Args = args
            }

            local DynDesc
            if isfunction(effect.Desc) then
                DynDesc = effect.Desc(unpack(args))
            else
                DynDesc = effect.Desc
            end 

            if self:IsPlayer() then
                net.Start("StatusEffectAdd")
                net.WriteString(effectName)
                net.WriteString(DynDesc)
                net.WriteFloat(time)
                net.Send(self)
            end

            net.Start("StatusEffectEntityAdd")
            net.WriteInt(self:EntIndex(), 32)
            net.WriteString(effectName)
            net.WriteFloat(time)
            net.WriteFloat(CurTime())
            net.Broadcast()

        else
            print("[Status Effect Framework] Effect not found")
        end
    end
    
    function ENTITY:RemoveEffect(effectName)
        local EntID = self:EntIndex()
        if EntActiveEffects[EntID] and EntActiveEffects[EntID][effectName] then
            EntActiveEffects[EntID][effectName] = nil
            print("[Status Effect Framework] Removed Effect", effectName, "from entity:", self)

            if self:IsPlayer() then
                net.Start("StatusEffectRemove")
                net.WriteString(effectName)
                net.Send(self)
            end

            net.Start("StatusEffectEntityRemove")
            net.WriteInt(self:EntIndex(), 32)
            net.WriteString(effectName)
            net.Broadcast()
        else
            print("[Status Effect Framework] Effect not active or not found:", effectName)
        end
    end

    function ENTITY:ApplyPassive(effectName)
        local effect = PassiveEffects[effectName]
        if effect and (self:IsPlayer() or self:IsNPC() or self:IsNextBot()) then

            local EntID = self:EntIndex()

            if not EntActivePassives[EntID] then
                print("[Status Effect Framework] Passives Effect Table created for entity:", self)
                EntActivePassives[EntID] = {}
            end

            if not EntActivePassives[EntID][effectName] then
                print("[Status Effect Framework] Applied Passive Effect:", effectName, "to entity:", self)
            end

            EntActivePassives[EntID][effectName] = {
                Function = effect.Effect,
            }

            local DynDesc = effect.Desc


            if self:IsPlayer() then
                net.Start("StatusEffectPassiveAdd")
                net.WriteString(effectName)
                net.WriteString(DynDesc)
                net.Send(self)
            end

        else
            print("[Status Effect Framework] Passive not found")
        end
    end
    
    function ENTITY:RemovePassive(effectName)
        local EntID = self:EntIndex()
        if EntActivePassives[EntID] and EntActivePassives[EntID][effectName] then
            EntActivePassives[EntID][effectName] = nil
            print("[Status Effect Framework] Removed Passive", effectName, "from entity:", self)

            if self:IsPlayer() then
                net.Start("StatusEffectPassiveRemove")
                net.WriteString(effectName)
                net.Send(self)
            end
        else
            print("[Status Effect Framework] Passive not active or not found:", effectName)
        end
    end

    function ENTITY:SoftRemoveEffect(effectName)
        local EntID = self:EntIndex()
        if EntActiveEffects[EntID] and EntActiveEffects[EntID][effectName] then
            print("[Status Effect Framework] Softremoved Effect", effectName, "from entity:", self)
            EntActiveEffects[EntID][effectName].Duration = 1

            if self:IsPlayer() then
                net.Start("StatusEffectAdd")
                net.WriteString(effectName)
                net.WriteString("Effect is wearing off.")
                net.WriteFloat(1)
                net.Send(self)
            end

            net.Start("StatusEffectEntityAdd")
            net.WriteInt(self:EntIndex(), 32)
            net.WriteString(effectName)
            net.WriteFloat(1)
            net.WriteFloat(CurTime())
            net.Broadcast()
        else
            print("[Status Effect Framework] Effect not active or not found:", effectName)
        end
    end

    function ENTITY:HaveEffect(effectName)
        if EntActiveEffects[self:EntIndex()] and EntActiveEffects[self:EntIndex()][effectName] then
            return true
        else
            return false
        end
    end

    function ENTITY:HavePassive(effectName)
        if EntActivePassives[self:EntIndex()] and EntActivePassives[self:EntIndex()][effectName] then
            return true
        else
            return false
        end
    end

    function ENTITY:GetTimeLeft(effectName)
        local EntID = self:EntIndex()
        if EntActiveEffects[EntID] and EntActiveEffects[EntID][effectName] then
            local effectData = EntActiveEffects[EntID][effectName]
            local elapsedTime = CurTime() - effectData.StartTime
            local remainingTime = effectData.Duration - elapsedTime
            return math.max(remainingTime, 0)
        else
            return 0 
        end
    end

    function ENTITY:ChangeDuration(effectName, time)
        local EntID = self:EntIndex()
        if EntActiveEffects[EntID] and EntActiveEffects[EntID][effectName] then
            local effectData = EntActiveEffects[EntID][effectName]
            effectData.Duration = time

            net.Start("StatusEffectUpdateData")
            net.WriteInt(EntID, 32)
            net.WriteString(effectName)
            net.WriteFloat(time)
            net.Broadcast()
            net.Abort()
        end
    end


    local function FindPlayerByName(name)
        name = string.lower(name)
        for _, ply in ipairs(player.GetAll()) do
            if string.find(string.lower(ply:Nick()), name, 1, true) then
                return ply
            end
        end
        return nil
    end

    -- Komenda do nakładania efektu
    concommand.Add("SEF_GiveEffect", function(ply, cmd, args)
        if #args < 3 then
            print("Usage: SEF_GiveEffect <effectName> <playerName> <time> [<arg1> <arg2> ...]")
            return
        end

        local effectName = args[1]
        local playerName = args[2]
        local time

        if args[3] == "inf" then
            time = math.huge
        else
            time = tonumber(args[3])
        end

        local effectArgs = {}
        for i = 4, #args do
            table.insert(effectArgs, tonumber(args[i]) or args[i])  -- Przekonwertuj na liczby lub zachowaj stringi
        end

        local targetPlayer = FindPlayerByName(playerName)
        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            if #args > 3 then
                targetPlayer:ApplyEffect(effectName, time, unpack(effectArgs))
                print(string.format("[Status Effect Framework] Applied effect '%s' to player '%s' for %d seconds with args: %s", effectName, targetPlayer:Nick(), time, table.concat(effectArgs, ", ")))
            else
                targetPlayer:ApplyEffect(effectName, time)
                print(string.format("[Status Effect Framework] Applied effect '%s' to player '%s' for %d seconds",  effectName, targetPlayer:Nick(), time))
            end
        else
            print("[Status Effect Framework] Player not found or invalid player name:", playerName)
        end
    end)

    concommand.Add("SEF_GivePassive", function(ply, cmd, args)
        if #args < 2 then
            print("Usage: SEF_GivePassive <passiveName> <playerName>")
            return
        end

        local passiveName = args[1]
        local playerName = args[2]

        local targetPlayer = FindPlayerByName(playerName)
        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            if #args > 1 then
                targetPlayer:ApplyPassive(passiveName)
                print(string.format("[Status Effect Framework] Applied Passive Effect '%s' to player '%s'", passiveName, targetPlayer:Nick()))
            end
        else
            print("[Status Effect Framework] Player not found or invalid player name:", playerName)
        end
    end)

    concommand.Add("SEF_RemovePassive", function(ply, cmd, args)
        if #args < 2 then
            print("Usage: SEF_RemovePassive <passiveName> <playerName>")
            return
        end

        local passiveName = args[1]
        local playerName = args[2]

        local targetPlayer = FindPlayerByName(playerName)
        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            if #args > 1 then
                targetPlayer:RemovePassive(passiveName)
                print(string.format("[Status Effect Framework] Removed Passive Effect '%s' from player '%s'", passiveName, targetPlayer:Nick()))
            end
        else
            print("[Status Effect Framework] Player not found or invalid player name:", playerName)
        end
    end)
end