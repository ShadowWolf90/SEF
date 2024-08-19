
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


        for effect, effectData in pairs(StatusEffects) do
            if effect and effectData.HookType ~= "" then

                if not effectData.HookInit then

                    effectData.LastHookFunction = effectData.HookFunction

                    print("[Status Effect Framework] Effect Hook has been created: " .. effect ..  " Hook: " .. effect .. "StatusEffectHookManager")

                    hook.Add(effectData.HookType, effect .. "StatusEffectHookManager", function(...)
                        effectData.HookFunction(...)
                    end)


                    effectData.HookInit = true

                elseif effectData.LastHookFunction != effectData.HookFunction then

                    print("[Status Effect Framework] Updating Hook Function for: " .. effect)

                    hook.Add(effectData.HookType, effect .. "StatusEffectHookManager", function(...)
                        effectData.HookFunction(...)
                    end)

                    effectData.LastHookFunction = effectData.HookFunction

                end
            end
        end

        for passive, PassiveData in pairs(PassiveEffects) do
            if passive and PassiveData.HookType ~= "" then

                if not PassiveData.HookInit then

                    PassiveData.LastHookFunction = PassiveData.HookFunction

                    print("[Status Effect Framework] Passive Hook has been created: " .. passive ..  " Hook: " .. passive .. "PassiveEffectHookManager")

                    hook.Add(PassiveData.HookType, passive .. "StatusEffectHookManager", function(...)
                        PassiveData.HookFunction(...)
                    end)


                    PassiveData.HookInit = true

                elseif PassiveData.LastHookFunction != PassiveData.HookFunction then

                    print("[Status Effect Framework] Updating Hook Function for: " .. passive)

                    hook.Add(PassiveData.HookType, passive .. "PassiveEffectHookManager", function(...)
                        PassiveData.HookFunction(...)
                    end)

                    PassiveData.LastHookFunction = PassiveData.HookFunction

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
end