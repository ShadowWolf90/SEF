
if SERVER then
    hook.Add("Think", "EntityStatusEffectsThink", function()
        for entID, effects in pairs(EntActiveEffects) do
            local Affected = Entity(entID)
            if IsValid(Affected) and (Affected:IsPlayer() or Affected:IsNPC() or Affected:IsNextBot()) then
                for effectName, effectData in pairs(effects) do
                    local currentTime = CurTime()
                    local TimeLeft = effectData.StartTime + effectData.Duration - currentTime
                    if TimeLeft > 0 then
                        if not effectData.HasBegun or (effectData.HasBegun and effectData.IsReApplied) then
                            if effectData.FunctionBegin then
                                effectData.FunctionBegin(Affected, unpack(effectData.Args))
                            end
                            effectData.HasBegun = true
                            effectData.IsReApplied = nil
                        end

                        if effectData.Function then
                            effectData.Function(Affected, effectData.Duration, unpack(effectData.Args))
                        end
                        
                    else
                        if effectData.FunctionEnd then
                            effectData.FunctionEnd(Affected, unpack(effectData.Args))
                        end
    
                        Affected:RemoveEffect(effectName)
                        if effectData.Stackable then
                            Affected:ResetSEFStacks(effectName)
                        end
                    end
                end
            elseif not IsValid(Affected) then
                EntActiveEffects[entID] = nil
            end
        end
    end)
    
    

    hook.Add("Think", "EntityPassivesEffectThink", function()
        for entID, Passives in pairs(EntActivePassives) do
            local Affected = Entity(entID)
            if IsValid(Affected) and (Affected:IsPlayer() or Affected:IsNPC() or Affected:IsNextBot()) then
                for effectName, PassiveData in pairs(Passives) do
                    if PassiveData.Function then
                        PassiveData.Function(Affected)
                    end
                end
            elseif not IsValid(Affected) then
                EntActivePassives[entID] = nil
            end
        end
    end)


    local function CreateEffectHooks()
        -- Przetwarzanie efektów
        for effect, effectData in pairs(StatusEffects) do
            if effect and effectData.ServerHooks then
                for index, hookData in ipairs(effectData.ServerHooks) do
                    if hookData.HookType then
                        local hookID = "SEF_SERVER_EFFECT_" .. effect .. tostring(index)
                        
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Effect Hook has been created: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Updating Hook Function for: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    
        -- Przetwarzanie efektów pasywnych (jeśli istnieją)
        for passive, PassiveData in pairs(PassiveEffects) do
            if passive and PassiveData.ServerHooks then
                for index, hookData in ipairs(PassiveData.ServerHooks) do
                    if hookData.HookType ~= "" then
                        local hookID = "SEF_SERVER_PASSIVE_" .. passive .. tostring(index)
    
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Passive Hook has been created: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Updating Hook Function for: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    end
    

    hook.Add("PlayerDeath", "RemoveStatusEffects", function(victim, inflictor, attacker)
        if IsValid(victim) and EntActiveEffects[victim:EntIndex()] then
            for effectName, _ in pairs(EntActiveEffects[victim:EntIndex()]) do
                if not StatusEffects[effectName].SoftDelete then
                    victim:RemoveEffect(effectName)
                else
                    victim:SoftRemoveEffect(effectName)
                end
                victim:ClearSEFStacks()
            end
        end
        BaseStatResetAll(victim)
    end)

    hook.Add("LambdaOnKilled", "RemoveStatusEffectsLambda", function(lambda, dmg, isSilent)
        if IsValid(lambda) and EntActiveEffects[lambda:EntIndex()] then
            for effectName, _ in pairs(EntActiveEffects[lambda:EntIndex()]) do
                timer.Simple(0.5, function() lambda:SoftRemoveEffect(effectName) end)
            end
        end
        BaseStatResetAll(lambda)
    end)

    hook.Add("Think", "SEF_UpdateEffectDesc", function()
        for ent, effects in pairs(EntEffectStacks) do
            if IsValid(ent) then
                local hasActiveEffects = false
    
                for effectName, stackCount in pairs(effects) do
                    local effectData = StatusEffects[effectName]
                    if effectData and effectData.Stackable then
                        local previousStack = ent.PreviousEffectStacks and ent.PreviousEffectStacks[effectName] or 0
    
                        if stackCount ~= previousStack then
                            if isfunction(effectData.Desc) then
                                local newDesc = effectData.Desc(stackCount, unpack(EntActiveEffects[ent:EntIndex()][effectName].Args))
    
                                if ent:IsPlayer() then
                                    net.Start("SEF_UpdateDesc")
                                    net.WriteString(effectName)
                                    net.WriteString(newDesc)
                                    net.Send(ent)
                                end
    
                                ent.PreviousEffectStacks = ent.PreviousEffectStacks or {}
                                ent.PreviousEffectStacks[effectName] = stackCount
                            end
                            --print("[SENDED STACK UPDATE FOR: " .. effectName .. " ]")
                        end
    
                        hasActiveEffects = true
                    end
                end
    
                if ent.PreviousEffectStacks then
                    for prevEffectName in pairs(ent.PreviousEffectStacks) do
                        if not effects[prevEffectName] then
                            ent.PreviousEffectStacks[prevEffectName] = nil
                        end
                    end
    
                    if not hasActiveEffects then
                        ent.PreviousEffectStacks = nil
                    end
                end
            end
        end

        for ent, passives in pairs(EntPassiveStacks) do
            if IsValid(ent) then
                local hasActivePassives = false
    
                for passiveName, stackCount in pairs(passives) do
                    local passiveData = PassiveEffects[passiveName]
                    if passiveData and passiveData.Stackable then
                        local previousStack = ent.PreviousPassiveStacks and ent.PreviousPassiveStacks[passiveName] or 0
    
                        if stackCount ~= previousStack then
                            if isfunction(passiveData.Desc) then
                                local newDesc = passiveData.Desc(stackCount, unpack(EntActivePassives[ent:EntIndex()][passiveName].Args))
    
                                if ent:IsPlayer() then
                                    net.Start("SEF_UpdateDesc")
                                    net.WriteString(passiveName)
                                    net.WriteString(newDesc)
                                    net.Send(ent)
                                end
    
                                ent.PreviousPassiveStacks = ent.PreviousPassiveStacks or {}
                                ent.PreviousPassiveStacks[passiveName] = stackCount
                            end
                            --print("[SENDED STACK UPDATE FOR: " .. passiveName .. " ]")
                        end
    
                        hasActivePassives = true
                    end
                end
    
                if ent.PreviousPassiveStacks then
                    for prevPassiveName in pairs(ent.PreviousPassiveStacks) do
                        if not passives[prevPassiveName] then
                            ent.PreviousPassiveStacks[prevPassiveName] = nil
                        end
                    end
    
                    if not hasActivePassives then
                        ent.PreviousPassiveStacks = nil
                    end
                end
            end
        end
    end)
    

    hook.Add("InitPostEntity", "CreateSEFHooks", function() 
        CreateEffectHooks()
    end)

    concommand.Add("SEF_CreateEffectHooks", function(ply, cmd, args)
        CreateEffectHooks()
    end, nil, "Reloads or creates all SEF hooks.")
else
    local function CreateClientEffectHooks()
        for effect, effectData in pairs(StatusEffects) do
            if effect and effectData.ClientHooks then
                for index, hookData in ipairs(effectData.ClientHooks) do
                    if hookData.HookType then
                        local hookID = "SEF_CLIENT_EFFECT_" .. effect .. tostring(index)
                        
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Effect Hook has been created: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Updating Hook Function for: " .. effect .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    
        -- Przetwarzanie efektów pasywnych (jeśli istnieją)
        for passive, PassiveData in pairs(PassiveEffects) do
            if passive and PassiveData.ClientHooks then
                for index, hookData in ipairs(PassiveData.ClientHooks) do
                    if hookData.HookType ~= "" then
                        local hookID = "SEF_CLIENT_PASSIVE_" .. passive .. tostring(index)
    
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Client Passive Hook has been created: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Client Updating Hook Function for: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, hookData.HookFunction)
    
                            hookData.LastHookFunction = hookData.HookFunction
                        end
                    end
                end
            end
        end
    end

    local function CreateDisplayHooks()
        for effect, effectData in pairs(StatusEffects) do
            if effectData.DisplayFunction then
                local hookID = "SEF_DISPLAYHOOK_" .. effect
                
                -- Sprawdź, czy hook został już dodany
                if not effectData.DisplayHookInit then
                    -- Zapisz początkową funkcję hooka
                    effectData.LastDisplayFunction = effectData.DisplayFunction
    
                    -- Dodaj hooka
                    hook.Add("Think", hookID, function()
                        for entID, activeEffects in pairs(AllEntEffects) do
                            local entity = Entity(entID)
                            if activeEffects[effect] then
                                effectData.DisplayFunction(entity)
                            end
                        end
                    end)
    
                    -- Zaznacz, że hook został dodany
                    effectData.DisplayHookInit = true
    
                    print("[Status Effect Framework] Display Hook has been created for: " .. effect .. " Hook: " .. hookID)
                elseif effectData.LastDisplayFunction ~= effectData.DisplayFunction then
                    -- Funkcja hooka została zmieniona, zaktualizuj hooka
                    print("[Status Effect Framework] Updating Display Hook Function for: " .. effect .. " Hook: " .. hookID)
    
                    -- Usunięcie starego hooka, jeśli istnieje
                    hook.Remove("Think", hookID)
    
                    -- Dodanie nowego hooka
                    hook.Add("Think", hookID, function()
                        for entID, activeEffects in pairs(AllEntEffects) do
                            local entity = Entity(entID)
                            if activeEffects[effect] then
                                effectData.DisplayFunction(entity)
                            end
                        end
                    end)
    
                    -- Zaktualizuj zapis funkcji hooka
                    effectData.LastDisplayFunction = effectData.DisplayFunction
                end
            end
        end
    end


    hook.Add("InitPostEntity", "CreateSEFClientHooks", function() 
        CreateClientEffectHooks()
        CreateDisplayHooks()
    end)

    concommand.Add("SEF_CreateClientHooks", function(ply, cmd, args)
        CreateClientEffectHooks()
        CreateDisplayHooks()
    end, nil, "Reloads or creates all SEF hooks for Client.")

end