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
        end
    },
    HealthBoost = {
        Icon = "SEF_Icons/health-increase.png",
        Type = "BUFF",
        Desc = function(added)
            return string.format("Your max health has been increased by %d HP!", added)
        end,
        EffectBegin = function(ent, healthadd)
            local currentHealthAdd = ent.HealthBoostLastAdded or 0
            if currentHealthAdd > 0 then
                BaseStatRemove(ent, "MaxHealth", currentHealthAdd)
            end
            BaseStatAdd(ent, "MaxHealth", healthadd)
            ent.HealthBoostLastAdded = healthadd
        end,
        EffectEnd = function(ent)
            if ent.HealthBoostLastAdded then
                BaseStatRemove(ent, "MaxHealth", ent.HealthBoostLastAdded)
                ent.HealthBoostLastAdded = nil
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
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    if target and target:HaveEffect("Exposed") then
                        dmginfo:ScaleDamage(2)
                        target:EmitSound("npc/zombie/zombie_hit.wav", 110, 100, 1)
                    end
                end
            }
        }
    },
    Endurance = {
        Icon = "SEF_Icons/endurance.png",
        Type = "BUFF",
        Desc = "Received damage is reduced by 50%.",
        Effect = function(ent, time)
        end,
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(target, dmginfo)
                    if target and target:HaveEffect("Endurance") then
                        dmginfo:ScaleDamage(0.5)
                        target:EmitSound("phx/epicmetal_hard.wav", 110, math.random(75, 125), 1)
                    end
                end
            }
        }
    },
    Haste = {
        Icon = "SEF_Icons/haste.png",
        Type = "BUFF",
        Desc = function(amount)
            return string.format("Your movement speed is increased by %d units.", amount)
        end,
        EffectBegin = function(ent, speedAdd)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                if ent.HasteEffectLastAdded then
                    BaseStatRemove(ent, "WalkSpeed", ent.HasteEffectLastAdded)
                    BaseStatRemove(ent, "RunSpeed", ent.HasteEffectLastAdded)
                end

                BaseStatAdd(ent, "WalkSpeed", speedAdd)
                BaseStatAdd(ent, "RunSpeed", speedAdd)
                ent.HasteEffectLastAdded = speedAdd
            end
        end,
        EffectEnd = function(ent)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                if ent.HasteEffectLastAdded then
                    BaseStatRemove(ent, "WalkSpeed", ent.HasteEffectLastAdded)
                    BaseStatRemove(ent, "RunSpeed", ent.HasteEffectLastAdded)
                    ent.HasteEffectLastAdded = nil
                end
            end
        end
    },
    Exhaust = {
        Icon = "SEF_Icons/exhaust.png",
        Type = "DEBUFF",
        Desc = "You are tired. \nYour speed can't be increased.",
        Effect = function(ent, time)
            local TimeLeft = ent:GetTimeLeft("Exhaust")
    
            if TimeLeft > 0.1 then
                if ent:HaveEffect("Haste") then
                    ent:SoftRemoveEffect("Haste")
                end
                
                if ent:IsPlayer() or ent.IsLambdaPlayer then
                    if ent:GetWalkSpeed() > EntBaseStats[ent].WalkSpeed then
                        local excessWalkSpeed = ent:GetWalkSpeed() - EntBaseStats[ent].WalkSpeed
                        BaseStatRemove(ent, "WalkSpeed", excessWalkSpeed)
                    end
                    if ent:GetRunSpeed() > EntBaseStats[ent].RunSpeed then
                        local excessRunSpeed = ent:GetRunSpeed() - EntBaseStats[ent].RunSpeed
                        BaseStatRemove(ent, "RunSpeed", excessRunSpeed)
                    end
                elseif ent:IsNextBot() and not ent.IsLambdaPlayer then
                    if ent:GetDesiredSpeed() > EntBaseStats[ent].RunSpeed then
                        local excessSpeed = ent:GetDesiredSpeed() - EntBaseStats[ent].RunSpeed
                        BaseStatRemove(ent, "RunSpeed", excessSpeed)
                    end
                end
            end
        end
    },    
    Hindered = {
        Icon = "SEF_Icons/hindered.png",
        Type = "DEBUFF",
        Desc = function(amount)
            return string.format("Your movement speed is decreased by %d units!", amount)
        end,
        EffectBegin = function(ent, speedDecrease)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                -- Zmiana prędkości gracza
                if ent.HinderedEffectLastAdded then
                    BaseStatAdd(ent, "WalkSpeed", ent.HinderedEffectLastAdded)
                    BaseStatAdd(ent, "RunSpeed", ent.HinderedEffectLastAdded)
                end
    
                BaseStatRemove(ent, "WalkSpeed", speedDecrease)
                BaseStatRemove(ent, "RunSpeed", speedDecrease)
    
                ent.HinderedEffectLastAdded = speedDecrease
            end
        end,
        Effect = function(ent, time, speedDecrease)
            if ent:IsNPC() and not ent:IsNextBot() then
                if not ent.PreviousMovement then
                    ent.PreviousMovement = ent:GetMovementActivity()
                end
                ent:SetMovementActivity(ACT_WALK)
            end
        end, 
        EffectEnd = function(ent, speedDecrease)
            if ent:IsPlayer() then
                if ent.HinderedEffectLastAdded then
                    BaseStatAdd(ent, "WalkSpeed", ent.HinderedEffectLastAdded)
                    BaseStatAdd(ent, "RunSpeed", ent.HinderedEffectLastAdded)
                    ent.HinderedEffectLastAdded = nil
                end
            elseif ent:IsNPC() and not ent:IsNextBot() then
                ent:SetMovementActivity(ent.PreviousMovement)
                ent.PreviousMovement = nil
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
        end
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
        end
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
        ServerHooks = {
            {
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
            }
        }

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
        end
    },
    Wither = {
        Name = "Withering",
        Icon = "SEF_Icons/wither.png",
        Type = "DEBUFF",
        Desc = function(witheramount, delay)
            return string.format("You are losing %d HP each %g sec.", witheramount, delay)
        end,
        Effect = function(ent, time, witheramount, delay)
            local TimeLeft = ent:GetTimeLeft("Wither")
            if TimeLeft > 0.1 then
    
                if not ent.WitheringEffectDelay then
                    ent.WitheringEffectDelay = CurTime()
                end
    
                if CurTime() >= ent.WitheringEffectDelay  then
                    ent:SetHealth(math.min(ent:Health() - witheramount, ent:GetMaxHealth()))
                    ent.WitheringEffectDelay = CurTime() + delay
                end
    
                if ent:Health() <= 0 and ent:Alive() then
                    ent:Kill()
                end
    
            end
        end
    },
    Discharge = {
        Icon = "SEF_Icons/discharge.png",
        Type = "DEBUFF",
        Desc = function(dischAmount, delay)
            return string.format("You are losing %d shield each %g sec.", dischAmount, delay)
        end,
        Effect = function(ent, time, dischAmount, delay)
            local TimeLeft = ent:GetTimeLeft("Discharge")
            if TimeLeft > 0.1  then
    
                if not ent.ShieldingEffectDelay then
                    ent.ShieldingEffectDelay = CurTime()
                end
    
                if CurTime() >= ent.ShieldingEffectDelay  then
                    ent:SetArmor(math.min(ent:Armor() - dischAmount))
                    ent.ShieldingEffectDelay = CurTime() + delay
                end
    
                if ent:Armor() <= 0 then
                    ent:RemoveEffect("Discharge")
                end
    
            end
        end
    },
    Template = { --Name and ID of Effect
        Icon = "SEF_Icons/warning.png", --Icon on HUD and displays
        Desc = "", --Optional
        Type = "DEBUFF", --Type 
        EffectBegin = function(ent) end,
        Effect = function(ent, time) end, --Effect on entity/player, function can be expanded by additional arguments,
        EffectEnd = function(ent) end,
        ClientHooks = {},
        ServerHooks = {}
    }
}