
if SERVER then
    hook.Add("Think", "EntityStatusEffectsThink", function()
        for entID, effects in pairs(EntActiveEffects) do
            local Affected = Entity(entID)
            if IsValid(Affected) and (Affected:IsPlayer() or Affected:IsNPC() or Affected:IsNextBot()) then
                for effectName, effectData in pairs(effects) do
                    local currentTime = CurTime()
                    local TimeLeft = effectData.StartTime + effectData.Duration - currentTime
                    if TimeLeft > 0 then
                        -- Jeśli efekt jest nowy lub został ponownie nałożony
                        if not effectData.HasBegun or (effectData.HasBegun and effectData.IsReApplied) then
                            -- Wywołanie funkcji EffectBegin
                            if effectData.FunctionBegin then
                                effectData.FunctionBegin(Affected, unpack(effectData.Args))
                            end
                            effectData.HasBegun = true
                            effectData.IsReApplied = nil -- Resetowanie flagi przy pierwszym wywołaniu
                        end

                        if effectData.Function then
                            effectData.Function(Affected, effectData.Duration, unpack(effectData.Args))
                        end
                        
                    else
                        -- Wywołanie funkcji EffectEnd przed usunięciem efektu
                        if effectData.FunctionEnd then
                            effectData.FunctionEnd(Affected, unpack(effectData.Args))
                        end
    
                        Affected:RemoveEffect(effectName)
                    end
                end
            elseif not IsValid(Affected) then
                EntActiveEffects[entID] = nil
            end
        end
    end)
    
    

    hook.Add("Think", "EntityPassivesEffectThink", function()
        for entID, effects in pairs(EntActivePassives) do
            local Affected = Entity(entID)
            if IsValid(Affected) and (Affected:IsPlayer() or Affected:IsNPC() or Affected:IsNextBot()) then
                for effectName, PassiveData in pairs(effects) do
                    PassiveData.Function(Affected)
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
                        local hookID = effect .. "ServerStatusEffectHookManager" .. tostring(index)
                        
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
                        local hookID = passive .. "ServerPassiveEffectHookManager" .. tostring(index)
    
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
                victim:SoftRemoveEffect(effectName)
            end
        end
    end)

    hook.Add("LambdaOnKilled", "RemoveStatusEffectsLambda", function(lambda, dmg, isSilent)
        if IsValid(lambda) and EntActiveEffects[lambda:EntIndex()] then
            for effectName, _ in pairs(EntActiveEffects[lambda:EntIndex()]) do
                timer.Simple(0.5, function() lambda:SoftRemoveEffect(effectName) end)
            end
        end
    end)

    hook.Add("InitPostEntity", "LoadSEFDataIntoServer", function() 
        CreateEffectHooks()
    end)

    concommand.Add("SEF_CreateEffectHooks", function(ply, cmd, args)
        CreateEffectHooks()
    end, nil, "Reloads or creates all SEF hooks.")
else
    local function CreateClientEffectHooks()
        -- Przetwarzanie efektów
        for effect, effectData in pairs(StatusEffects) do
            if effect and effectData.ClientHooks then
                for index, hookData in ipairs(effectData.ClientHooks) do
                    if hookData.HookType then
                        local hookID = effect .. "ClientStatusEffectHookManager" .. tostring(index)
                        
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
            if passive and PassiveData.ClientHooks then
                for index, hookData in ipairs(PassiveData.ClientHooks) do
                    if hookData.HookType ~= "" then
                        local hookID = passive .. "ClientPassiveEffectHookManager" .. tostring(index)
    
                        if not hookData.HookInit then
                            hookData.LastHookFunction = hookData.HookFunction
    
                            print("[Status Effect Framework] Client Passive Hook has been created: " .. passive .. " Hook: " .. hookID)
    
                            hook.Add(hookData.HookType, hookID, function(...)
                                hookData.HookFunction(...)
                            end)
    
                            hookData.HookInit = true
                        elseif hookData.LastHookFunction ~= hookData.HookFunction then
                            print("[Status Effect Framework] Client Updating Hook Function for: " .. passive .. " Hook: " .. hookID)
    
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
    

    hook.Add("InitPostEntity", "LoadClientSEFDataIntoServer", function() 
        CreateClientEffectHooks()
    end)

    concommand.Add("SEF_CreateClientEffectHooks", function(ply, cmd, args)
        CreateClientEffectHooks()
    end, nil, "Reloads or creates all SEF hooks for Client.")
end