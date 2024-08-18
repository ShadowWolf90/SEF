StatusEffects = {
    Healing = {
        Icon = "SEF_Icons/health-normal.png",
        Type = "BUFF",
        Desc = function(healamount, delay)
            if delay == nil then
                return string.format("You are regenerating %d HP each 0.3 sec.", healamount)
            else
                return string.format("You are regenerating %d HP each %g sec.", healamount, delay)
            end
        end,
        Effect = function(ent, time, healamount, delay)
            local TimeLeft = ent:GetTimeLeft("Healing")
            local HealDelay = delay

            if HealDelay == nil then HealDelay = 0.3 end

            if TimeLeft > 0.1 then
                if not ent.HealingEffectDelay then
                    ent.HealingEffectDelay  = CurTime()
                end
                if CurTime() >= ent.HealingEffectDelay  then
                    ent:SetHealth(math.min(ent:Health() + healamount, ent:GetMaxHealth()))
                    ent.HealingEffectDelay = CurTime() + HealDelay
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    HealthBoost = {
        Icon = "SEF_Icons/health-increase.png",
        Type = "BUFF",
        Desc = function(added)
            return string.format("Your max health has been increased by %d HP!", added)
        end,
        Effect = function(ent, time, healthadd)
            local TimeLeft = ent:GetTimeLeft("HealthBoost")

            if not ent.HealthBoostPreBuff then
                ent.HealthBoostPreBuff = ent:GetMaxHealth()
            end

            if TimeLeft > 0.1 then
                ent:SetMaxHealth(ent.HealthBoostPreBuff + healthadd)
            elseif TimeLeft <= 0.1 then
                ent:SetMaxHealth(ent.HealthBoostPreBuff)
                if ent:Health() > ent.HealthBoostPreBuff then
                    ent:SetHealth(ent.HealthBoostPreBuff) 
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Energized = {
        Icon = "SEF_Icons/healing-shield.png",
        Type = "BUFF",
        Desc = function(healamount, delay, maxamount)
            if maxamount != nil and delay == nil then
                return string.format("You are regenerating %d shield each 0.3 sec.\n [Max Armor: %d]", healamount, maxamount)
            elseif maxamount != nil and delay != nil then
                return string.format("You are regenerating %d shield each %g sec.\n [Max Armor: %d]", healamount, delay, maxamount)
            elseif delay != nil and maxamount == nil then
                return string.format("You are regenerating %d shield each %g sec up to your max shield amount.", healamount, delay)
            end
        end,
        Effect = function(ent, time, healamount, delay, maxamount)
            local TimeLeft = ent:GetTimeLeft("Energized")
            if maxamount == nil then maxamount = ent:GetMaxArmor() end
            local HealDelay = delay
            if HealDelay == nil then HealDelay = 0.3 end

            if TimeLeft > 0.1  then
                if not ent.ShieldingEffectDelay then
                    ent.ShieldingEffectDelay = CurTime()
                end
                if CurTime() >= ent.ShieldingEffectDelay  then
                    ent:SetArmor(math.min(ent:Armor() + healamount, maxamount))
                    ent.ShieldingEffectDelay = CurTime() + HealDelay
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Broken = {
        Icon = "SEF_Icons/broken.png",
        Type = "DEBUFF",
        Desc = function(maxhealth)
            return string.format("Your health is capped at %d HP.", maxhealth)
        end,
        Effect = function(ent, time, maxhealth)
            local TimeLeft = ent:GetTimeLeft("Broken")
            if TimeLeft > 0.1  then
                ent.BrokenEffectMaxHealth = maxhealth

                if ent:Health() >= ent.BrokenEffectMaxHealth then
                    ent:SetHealth(ent.BrokenEffectMaxHealth)
                end

                if ent:HaveEffect("Healing") then
                    ent:RemoveEffect("Healing")
                elseif ent:HaveEffect("HealthBoost") then
                    ent:SoftRemoveEffect("HealthBoost")
                end

            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Exposed = {
        Icon = "SEF_Icons/exposed.png",
        Type = "DEBUFF",
        Desc = "Received damage is doubled.",
        Effect = function(ent, time)
        end,
        HookType = "EntityTakeDamage",
        HookFunction = function(target, dmginfo)
            if target and target:HaveEffect("Exposed") then
                dmginfo:ScaleDamage(2)
                target:EmitSound("npc/zombie/zombie_hit.wav", 110, 100, 1)
            end
        end
    },
    Endurance = {
        Icon = "SEF_Icons/endurance.png",
        Type = "BUFF",
        Desc = "Received damage is reduced by 50%.",
        Effect = function(ent, time)
        end,
        HookType = "EntityTakeDamage",
        HookFunction = function(target, dmginfo)
            if target and target:HaveEffect("Endurance") then
                dmginfo:ScaleDamage(0.5)
                target:EmitSound("phx/epicmetal_hard.wav", 110, math.random(75, 125), 1)
            end
        end
    },
    Haste = {
        Icon = "SEF_Icons/haste.png",
        Type = "BUFF",
        Desc = function(amount)
            return string.format("Your movement speed is increased by %d units.", amount)
        end,
        Effect = function(ent, time, amount)
            local TimeLeft = ent:GetTimeLeft("Haste")

            if TimeLeft > 0.5 then
    
                if ent:IsPlayer() then
                    if not ent.HasteEffectSpeedWalk and not ent.HasteEffectSpeedRun then
                        ent.HasteEffectSpeedWalk = ent:GetWalkSpeed()
                        ent.HasteEffectSpeedRun = ent:GetRunSpeed()
                    end
                    ent:SetRunSpeed(ent.HasteEffectSpeedRun  + amount)
                    ent:SetWalkSpeed(ent.HasteEffectSpeedWalk + amount)
                elseif ent.IsLambdaPlayer then
                    local walkingSpeed = GetConVar("lambdaplayers_lambda_walkspeed")
                    local runningSpeed = GetConVar("lambdaplayers_lambda_runspeed")
                    ent:SetRunSpeed(runningSpeed:GetInt() + amount)
                    ent:SetWalkSpeed(walkingSpeed:GetInt() + amount)
                elseif ent:IsNPC() then
                    ent:SoftRemoveEffect("Haste")
                    print("Haste won't work on NPCs.")
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                    if not ent.HasteEffectSpeed then
                        ent.HasteEffectSpeed = ent:GetDesiredSpeed()
                    end
                    ent:SetDesiredSpeed(ent.HasteEffectSpeed + amount)
                end
            elseif TimeLeft <= 0.5 then
    
                if ent:IsPlayer() then
                    ent:SetRunSpeed(ent.HasteEffectSpeedRun)
                    ent:SetWalkSpeed(ent.HasteEffectSpeedWalk)
                elseif ent.IsLambdaPlayer then
                    local walkingSpeed = GetConVar("lambdaplayers_lambda_walkspeed")
                    local runningSpeed = GetConVar("lambdaplayers_lambda_runspeed")
                    ent:SetRunSpeed(runningSpeed:GetInt())
                    ent:SetWalkSpeed(walkingSpeed:GetInt())
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                    ent:SetDesiredSpeed(ent.HasteEffectSpeed)
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Exhaust = {
        Icon = "SEF_Icons/exhaust.png",
        Type = "DEBUFF",
        Desc = "You are tired. \nYour speed can't be increased.",
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("Exhaust")
    
            if (ent:IsPlayer() or ent.IsLambdaPlayer) and not ent.ExhaustedEffectSpeedWalk and not ent.ExhaustedEffectSpeedRun then
                ent.ExhaustedEffectSpeedWalk = ent:GetWalkSpeed()
                ent.ExhaustedEffectSpeedRun = ent:GetRunSpeed()
            elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                ent.ExhaustEffectSpeed = ent:GetDesiredSpeed()
            end

            if ent:HaveEffect("Haste") then
                ent:SoftRemoveEffect("Haste")
                if (ent:IsPlayer() or ent.IsLambdaPlayer) then
                    ent.ExhaustedEffectSpeedWalk = ent.HasteEffectSpeedWalk
                    ent.ExhaustedEffectSpeedRun = ent.HasteEffectSpeedRun
                else
                    ent.ExhaustEffectSpeed = ent.HasteEffectSpeed
                end
            end
    
            if TimeLeft > 0.1 then
                local walkingSpeed = GetConVar("lambdaplayers_lambda_walkspeed"):GetInt()
                local runningSpeed = GetConVar("lambdaplayers_lambda_runspeed"):GetInt()
    
                if ent:IsPlayer() and ent.ExhaustedEffectSpeedWalk and ent.ExhaustedEffectSpeedRun then
                    if ent:GetWalkSpeed() > ent.ExhaustedEffectSpeedWalk then
                        ent:SetWalkSpeed(ent.ExhaustedEffectSpeedWalk)
                    end
                    if ent:GetRunSpeed() > ent.ExhaustedEffectSpeedRun then
                        ent:SetRunSpeed(ent.ExhaustedEffectSpeedRun)
                    end
                elseif ent.IsLambdaPlayer and ent.ExhaustedEffectSpeedWalk and ent.ExhaustedEffectSpeedRun then
                    if ent:GetWalkSpeed() > ent.ExhaustedEffectSpeedWalk then
                        ent:SetWalkSpeed(walkingSpeed)
                    end
                    if ent:GetRunSpeed() > ent.ExhaustedEffectSpeedRun then
                        ent:SetRunSpeed(runningSpeed)
                    end
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer and ent.ExhaustEffectSpeed then
                    if ent:GetDesiredSpeed() > ent.ExhaustEffectSpeed then
                        ent:SetDesiredSpeed(ent.ExhaustEffectSpeed)
                    end
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },    
    Hindered = {
        Icon = "SEF_Icons/hindered.png",
        Type = "DEBUFF",
        Desc = function(amount)
            return string.format("Your movement speed is decreased by %d units!", amount)
        end,
        Effect = function(ent, time, amount)
            local TimeLeft = ent:GetTimeLeft("Hindered")

            if TimeLeft > 0.5 then
                local walkingSpeed = GetConVar("lambdaplayers_lambda_walkspeed")
                local runningSpeed = GetConVar("lambdaplayers_lambda_runspeed")
    
                if ent:IsPlayer() then

                    if not ent.PlayerHinderedSpeedWalk then
                        ent.PlayerHinderedSpeedWalk = ent:GetWalkSpeed()
                        ent.PlayerHinderedSpeedRun = ent:GetRunSpeed()  
                    end

                    ent:SetRunSpeed(ent.PlayerHinderedSpeedRun - amount)
                    ent:SetWalkSpeed(ent.PlayerHinderedSpeedWalk - amount)
                elseif ent.IsLambdaPlayer then
                    ent:SetRunSpeed(runningSpeed:GetInt() - amount)
                    ent:SetWalkSpeed(walkingSpeed:GetInt() - amount)
                elseif ent:IsNPC() then
                    ent:RemoveEffect("Hindered")
                    print("NPCs are not supported")
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                    if not ent.HinderedEffectSpeed then
                        ent.HasteEffectSpeed = ent:GetDesiredSpeed()
                    end
                    ent:SetDesiredSpeed(ent.HasteEffectSpeed - amount)
                end
            elseif TimeLeft <= 0.5 then
                local walkingSpeed = GetConVar("lambdaplayers_lambda_walkspeed")
                local runningSpeed = GetConVar("lambdaplayers_lambda_runspeed")
    
                if ent:IsPlayer() and ent.PlayerHinderedSpeedWalk ~= nil then
                    ent:SetRunSpeed(ent.PlayerHinderedSpeedRun)
                    ent:SetWalkSpeed(ent.PlayerHinderedSpeedWalk)
                    ent.PlayerHinderedSpeedWalk = nil
                    ent.PlayerHinderedSpeedRun = nil  
                elseif ent.IsLambdaPlayer then
                    ent:SetRunSpeed(runningSpeed:GetInt())
                    ent:SetWalkSpeed(walkingSpeed:GetInt())
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                    ent:SetDesiredSpeed(ent.HindredEffectSpeed)
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Bleeding = {
        Icon = "SEF_Icons/bleed.png",
        Type = "DEBUFF",
        Desc = function(damageamount)
            return string.format("You are bleeding.\n You are losing %d HP each 0.3 sec.", damageamount)
        end,
        Effect = function(ent, time, damageamount, delay, inf)
            local TimeLeft = ent:GetTimeLeft("Bleeding")
            if TimeLeft > 0.1 then

                if not ent.BleedingEffectDelay then
                    ent.BleedingEffectDelay  = CurTime()
                end

                local BleedDelay = delay
                if BleedDelay == nil then BleedDelay = 0.3 end

                if CurTime() >= ent.BleedingEffectDelay  then
                    if IsValid(inf) then
                        local dmg = DamageInfo()
                        dmg:SetDamage(damageamount)
                        dmg:SetInflictor(inf)
                        dmg:SetAttacker(inf)
                        ent:TakeDamageInfo(dmg)
                    else
                        ent:TakeDamage(damageamount)
                    end
                    ent.BleedingEffectDelay = CurTime() + BleedDelay
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Incapacitated = {
        Icon = "SEF_Icons/incap.png",
        Type = "DEBUFF",
        Desc = "You are unable to use any weapons or tools.",
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("Incapacitated")
            if TimeLeft > 0.5 then
                if ent:IsPlayer() then
                    if not ent.IncapEffectWeapon then
                        ent.IncapEffectWeapon = ent:GetActiveWeapon():GetClass()
                    end
                    ent:SetActiveWeapon(NULL)
                elseif ent.IsLambdaPlayer then

                    if not ent.IncapEffectWeapon then
                        ent.IncapEffectWeapon = ent.l_Weapon
                    end

                    ent:RetreatFrom()    
                    ent:SwitchWeapon("none")
                elseif ent:IsNPC() then
                    if not ent.IncapEffectWeapon and IsValid(ent:GetActiveWeapon()) then
                        ent.IncapEffectWeapon = ent:GetActiveWeapon():GetClass()
                    end

                    if IsValid(ent:GetActiveWeapon()) then
                        ent:GetActiveWeapon():Remove()
                    end
                end
            elseif TimeLeft <= 0.1 then
                if ent:IsPlayer() then
                    if ent.IncapEffectWeapon ~= nil then
                        ent:SelectWeapon(ent.IncapEffectWeapon)
                    end
                    ent.IncapEffectWeapon = nil
                elseif ent.IsLambdaPlayer then
                    if ent.IncapEffectWeapon ~= nil then
                        ent:SwitchWeapon(ent.IncapEffectWeapon)
                    end
                    ent.IncapEffectWeapon = nil
                elseif ent:IsNPC() then
                    if ent.IncapEffectWeapon ~= nil then
                        ent:Give(ent.IncapEffectWeapon)
                    end
                    ent.IncapEffectWeapon = nil
                end
            end
        end,
        HookType = "",
        HookFunction = function() end
    },
    Tenacity = {
        Icon = "SEF_Icons/tenacity.png",
        Desc = "You've become immune to negative effects. \n Debuffs are 75% shorter.",
        Type = "BUFF",
        Effect = function(ent, time)
            for effectName, effectData in pairs(EntActiveEffects[ent:EntIndex()]) do
                if StatusEffects[effectName].Type == "DEBUFF" and not effectData.TenacityAffected then
                    local NewDuration = EntActiveEffects[ent:EntIndex()][effectName].Duration * 0.25
                    ent:ChangeDuration(effectName, NewDuration)
                    effectData.TenacityAffected = true
                end
            end
        end,
        HookType = "", 
        HookFunction = function() end
    },
    Bloodlust = {
        Icon = "SEF_Icons/bloodlust.png",
        Type = "BUFF",
        Desc = function(dmgincr, lifesteal)
            if lifesteal ~= nil then
                return string.format("You are hungry for blood! \nDamage you deal is increased by %d%%\n %d%% of dealt damage is received as healing.", dmgincr, lifesteal)
            else
                return string.format("You are hungry for blood! \nDamage you deal is increased by %d%%", dmgincr)
            end
        end,
        Effect = function(ent, time, dmgincr, lifesteal)
            if ent:GetTimeLeft("Bloodlust") > 0.1 then
                if lifesteal ~= nil and lifesteal ~= 0 then
                    ent.BloodLustDMGIncrease = dmgincr
                    ent.BloodLustLifeSteal = lifesteal
                else
                    ent.BloodLustDMGIncrease = dmgincr
                end
            end
        end,
        HookType = "EntityTakeDamage",
        HookFunction = function(target, dmginfo)
            local attacker = dmginfo:GetAttacker()
            if target and target ~= attacker and (target:IsNPC() or target:IsPlayer() or target:IsNextBot()) and attacker:HaveEffect("Bloodlust") then
                dmginfo:ScaleDamage(1 + (attacker.BloodLustDMGIncrease / 100))
                target:EmitSound("npc/manhack/grind_flesh1.wav", 110, 100, 1)
                if attacker.BloodLustLifeSteal ~= nil then
                    attacker:SetHealth(math.min(attacker:Health() + (dmginfo:GetDamage() * (attacker.BloodLustLifeSteal / 100)), attacker:GetMaxHealth()))
                    attacker:EmitSound("npc/headcrab_fast/headbite.wav", 110, 100, 1)
                end
            end
        end
    },
    Stunned = { 
        Icon = "SEF_Icons/stunned.png",
        Desc = "You are unable to move or do any action.", 
        Type = "DEBUFF",
        Effect = function(ent, time)
            if ent:IsPlayer() then

                if not ent.PlayerStunnedSpeedWalk then
                    ent.PlayerStunnedSpeedWalk = ent:GetWalkSpeed()
                    ent.PlayerStunnedSpeedRun = ent:GetRunSpeed()
                    ent.PlayerStunnedJumpPower = ent:GetJumpPower()  
                end

                if ent:GetTimeLeft("Stunned") > 0.1 then
                    ent:DoAnimationEvent(ACT_HL2MP_IDLE_COWER)
                    ent:SetWalkSpeed(1)
                    ent:SetRunSpeed(1)
                    ent:SetJumpPower(0)
                    ent:SetActiveWeapon(NULL)
                else
                    ent:DoAnimationEvent(ACT_COWER)
                    if ent.PlayerStunnedSpeedWalk ~= nil then
                        ent:SetWalkSpeed(ent.PlayerStunnedSpeedWalk)
                        ent:SetRunSpeed(ent.PlayerStunnedSpeedRun)
                        ent:SetJumpPower(ent.PlayerStunnedJumpPower)
                        ent.PlayerStunnedSpeedWalk = nil
                        ent.PlayerStunnedSpeedRun = nil
                        ent.PlayerStunnedJumpPower = nil 
                    end
                end
            end
        end,
        HookType = "",
        HookFunction = function() end 
    },
    Template = { --Name and ID of Effect
        Icon = "SEF_Icons/warning.png", --Icon on HUD and displays
        Desc = "", --Optional
        Type = "DEBUFF", --Type 
        Effect = function(ent, time) --Effect on entity/player, function can be expanded by additional arguments
        end,
        HookType = "", --Hook name 
        HookFunction = function() end -- What function should be added to set HookType.
    }
}