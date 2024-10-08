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
        EffectBegin = function(ent)
            if not ent.HealingEffectSound then
                EmitSound("Healing.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.HealingEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.HealingEffectSound = nil
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
        DisplayFunction = function(ent)
            if ent:IsValid() then
                local emitter = ParticleEmitter(ent:GetPos())

                if not ent.HealParticleTime then
                    ent.HealParticleTime = CurTime()
                end

                if emitter then
                    -- Losowanie kąta i odległości do umieszczenia cząsteczki wokół encji
                    local angle = math.Rand(0, 360)
                    local distance = math.Rand(0, 25)
                    local offset = Vector(math.cos(math.rad(angle)) * distance, math.sin(math.rad(angle)) * distance, 10)
                    local particlePos = ent:GetPos() + offset
                    local particle = emitter:Add(Material("SEF_Icons/health-normal.png"), particlePos)
                    if particle and CurTime() >= ent.HealParticleTime + 0.3 then
                        particle:SetVelocity(Vector(0, 0, 50))  -- Ustawienie prędkości w górę
                        particle:SetLifeTime(0)
                        particle:SetDieTime(2)
                        particle:SetStartAlpha(255)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(5)
                        particle:SetEndSize(0)
                        particle:SetColor(255, 255, 255)
                        ent.HealParticleTime = CurTime()
                    end
        
                    emitter:Finish()
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

            if not ent.HealthBoostEffectSound then
                EmitSound("Energized.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.HealthBoostEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            if ent.HealthBoostLastAdded then
                BaseStatRemove(ent, "MaxHealth", ent.HealthBoostLastAdded)
                ent.HealthBoostLastAdded = nil
                ent.HealthBoostEffectSound = nil
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
        EffectBegin = function(ent)
            if not ent.EnergizedEffectSound then
                EmitSound("Energized.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.EnergizedEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.EnergizedEffectSound = nil
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
        DisplayFunction = function(ent)
            if ent:IsValid() then
                local emitter = ParticleEmitter(ent:GetPos())

                if not ent.ArmorParticleTime then
                    ent.ArmorParticleTime = CurTime()
                end

                if emitter then
                    -- Losowanie kąta i odległości do umieszczenia cząsteczki wokół encji
                    local angle = math.Rand(0, 360)
                    local distance = math.Rand(0, 25)
                    local offset = Vector(math.cos(math.rad(angle)) * distance, math.sin(math.rad(angle)) * distance, 10)
                    local particlePos = ent:GetPos() + offset
                    local particle = emitter:Add(Material("SEF_Icons/healing-shield.png"), particlePos)
                    if particle and CurTime() >= ent.ArmorParticleTime + 0.3 then
                        particle:SetVelocity(Vector(0, 0, 50))  -- Ustawienie prędkości w górę
                        particle:SetLifeTime(0)
                        particle:SetDieTime(2)
                        particle:SetStartAlpha(255)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(5)
                        particle:SetEndSize(0)
                        particle:SetColor(255, 255, 255)
                        ent.ArmorParticleTime = CurTime()
                    end
        
                    emitter:Finish()
                end
            end
        end
    },
    Broken = {
        Icon = "SEF_Icons/broken.png",
        Type = "DEBUFF",
        Desc = function(maxhealth)
            return string.format("Your health is capped at %d HP.", maxhealth)
        end,
        EffectBegin = function(ent)
            if not ent.BrokenEffectSound then
                EmitSound("broken.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BrokenEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.BrokenEffectSound = nil
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
        EffectBegin = function(ent)
            if not ent.ExposedEffectSound then
                EmitSound("exposed.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.ExposedEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.ExposedEffectSound = nil
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
        EffectBegin = function(ent)
            if not ent.EnduranceEffectSound then
                EmitSound("Endurance.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.EnduranceEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.EnduranceEffectSound = nil
        end,
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

                if not ent.HasteEffectSound then
                    EmitSound("Haste.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                    ent.HasteEffectSound = true
                end
            end
        end,
        EffectEnd = function(ent)
            if ent:IsPlayer() or ent.IsLambdaPlayer then
                if ent.HasteEffectLastAdded then
                    BaseStatRemove(ent, "WalkSpeed", ent.HasteEffectLastAdded)
                    BaseStatRemove(ent, "RunSpeed", ent.HasteEffectLastAdded)
                    ent.HasteEffectLastAdded = nil
                    ent.HasteEffectSound = nil
                end
            end
        end,
        DisplayFunction = function(ent)
            if ent:IsValid() then
                local emitter = ParticleEmitter(ent:GetPos())

                if not ent.HasteParticleTime then
                    ent.HasteParticleTime = CurTime()
                end

                if emitter then
                    local particlePos = ent:GetPos()
                    local particle = emitter:Add("particles/smokey", particlePos)
                    if particle and CurTime() >= ent.HasteParticleTime + 0.05 and ent:GetVelocity():LengthSqr() > 0 and ent:IsOnGround() then
                        particle:SetLifeTime(0)
                        particle:SetDieTime(0.5)
                        particle:SetStartAlpha(255)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(1)
                        particle:SetEndSize(50)
                        particle:SetColor(255, 255, 255)
                        ent.HasteParticleTime = CurTime()
                    end
        
                    emitter:Finish()
                end
            end
        end
    },
    Exhaust = {
        Icon = "SEF_Icons/exhaust.png",
        Type = "DEBUFF",
        Desc = "You are tired. \nYour speed can't be increased.",
        EffectBegin = function(ent)
            if not ent.ExhaustEffectSound then
                EmitSound("Exhaust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.ExhaustEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.ExhaustEffectSound = nil
        end,
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

            if not ent.HinderedEffectSound then
                EmitSound("Exhaust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.HinderedEffectSound = true
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
            elseif ent:IsNPC() and not ent:IsNextBot() and ent:Health() > 0 then
                ent:SetMovementActivity(ent.PreviousMovement)
                ent.PreviousMovement = nil
            end

            ent.HinderedEffectSound = nil
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
        EffectBegin = function(ent)
            if not ent.BleedingEffectSound then
                EmitSound("Bleeding.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BleedingEffectSound = true
            end
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
        EffectEnd = function(ent)
            ent.BleedingEffectDelay = nil
            ent.BleedingEffectSound = nil
        end
    },
    Incapacitated = {
        Icon = "SEF_Icons/incap.png",
        Type = "DEBUFF",
        Desc = "You are unable to use any weapons or tools.",
        EffectBegin = function(ent)
            if not ent.IncapacitatedEffectSound then
                EmitSound("Incapacitated.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.IncapacitatedEffectSound = true
            end
        end,
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
        EffectEnd = function(ent)
            ent.IncapacitatedEffectSound = nil
        end
    },
    Tenacity = {
        Icon = "SEF_Icons/tenacity.png",
        Desc = "You've become immune to negative effects. \n Debuffs are 75% shorter.",
        Type = "BUFF",
        EffectBegin = function(ent)
            if not ent.TenacityEffectSound then
                EmitSound("Tenacity.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.TenacityEffectSound = true
            end
        end,
        Effect = function(ent, time)
            for effectName, effectData in pairs(EntActiveEffects[ent:EntIndex()]) do
                if StatusEffects[effectName].Type == "DEBUFF" and not effectData.TenacityAffected then
                    local NewDuration = EntActiveEffects[ent:EntIndex()][effectName].Duration * 0.25
                    ent:ChangeDuration(effectName, NewDuration)
                    effectData.TenacityAffected = true
                end
            end
        end,
        EffectEnd = function(ent)
            ent.TenacityEffectSound = nil
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
        EffectBegin = function(ent)
            if not ent.BloodlustEffectSound then
                EmitSound("Bloodlust.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BloodlustEffectSound = true
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
        EffectEnd = function(ent)
            ent.BloodlustEffectSound = nil
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
        EffectBegin = function(ent)
            if ent:IsPlayer() then
                ent:DoAnimationEvent(ACT_HL2MP_IDLE_COWER)
                if not ent.StunnedEffectSound then
                    EmitSound("Stunned.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                    ent.StunnedEffectSound = true
                end

            end
        end,
        Effect = function(ent)
            if ent:IsPlayer() then
                ent:SetActiveWeapon(NULL)
            end
        end,
        EffectEnd = function(ent)
            if ent:IsPlayer() then
                ent:DoAnimationEvent(ACT_HL2MP_RUN)
                ent.StunnedEffectSound = nil
            end
        end,
        ClientHooks = {
            {
                HookType = "CalcView",
                HookFunction = function(ply, pos, angles, fov)
                    if IsValid(ply) and ply:HaveEffect("Stunned") then
                        local view = {
                            origin = pos - (angles:Forward() * 100) + Vector(0, 0, 10),
                            angles = angles,
                            fov = fov,
                            drawviewer = true
                        }
                        return view
                    end
                end,
            },
            {
                HookType = "CreateMove",
                HookFunction = function(cmd)
                    local ply = LocalPlayer()
                    if ply:HaveEffect("Stunned") then
                        local angles = cmd:GetViewAngles()
                        cmd:SetViewAngles(angles)
                        cmd:SetForwardMove(0)
                        cmd:SetSideMove(0)
                        cmd:SetUpMove(0)
                        cmd:SetViewAngles(angles)
                    end
                end,
            },
        },
    },
    Wither = {
        Name = "Withering",
        Icon = "SEF_Icons/wither.png",
        Type = "DEBUFF",
        Desc = function(witheramount, delay)
            return string.format("You are losing %d HP each %g sec.", witheramount, delay)
        end,
        EffectBegin = function(ent)
            if not ent.WitherEffectSound then
                EmitSound("Withered.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.WitherEffectSound = true
            end
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
    
                if ent:IsPlayer() and ent:Health() <= 0 and ent:Alive()then
                    ent:Kill()
                elseif not ent:IsPlayer() and ent:Health() <= 0 then
                    ent:TakeDamage(1) 
                end
    
            end
        end,
        EffectEnd = function(ent)
            ent.WitherEffectSound = nil
        end
    },
    Discharge = {
        Icon = "SEF_Icons/discharge.png",
        Type = "DEBUFF",
        Desc = function(dischAmount, delay)
            return string.format("You are losing %d shield each %g sec.", dischAmount, delay)
        end,
        EffectBegin = function(ent)
            if not ent.DischargeEffectSound then
                EmitSound("Discharge.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.DischargeEffectSound = true
            end
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
        end,
        EffectEnd = function(ent)
            ent.DischargeEffectSound = nil
        end
    },
    Blindness = {
        Icon = "SEF_Icons/blind.png",
        Desc = "You are unable to see.", 
        Type = "DEBUFF",
        EffectBegin = function(ent)
            if not ent.BlindnessEffectSound then
                EmitSound("Blindness.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.BlindnessEffectSound = true
            end
        end,
        EffectEnd = function(ent)
            ent.BlindnessEffectSound = nil
        end,  
        ClientHooks = {
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local TimeLeft = ply:GetTimeLeft("Blindness")
    
                    if ply:HaveEffect("Blindness") then
                        local alpha = 255
                        local fadeStartTime = 0.5
    
                        if TimeLeft <= fadeStartTime then
                            alpha = math.max(0, 255 * (TimeLeft / fadeStartTime))
                        end

                        surface.SetDrawColor(0, 0, 0, alpha)
                        surface.DrawRect(0, 0, ScrW(), ScrH())
                    end
                end
            }
        },
        ServerHooks = {},
    },
    Poison = {
        Icon = "SEF_Icons/poison.png",
        Desc = function(damageamount, delay)
            if delay ~= nil and damageamount ~= nil then
                return string.format("You are losing %d HP each %g sec. \nYou can't heal.", damageamount, delay)
            elseif damageamount ~= nil then
                return string.format("You are losing %d HP each 0.3 sec. \nYou can't heal.", damageamount)
            elseif delay == nil and damageamount == nil then
                return string.format("You can't heal.")
            end
        end, 
        Type = "DEBUFF",
        EffectBegin = function(ent)
            ent.PoisonEffectHP = ent:Health()
            if not ent.PoisonEffectSound then
                EmitSound("Poison.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.PoisonEffectSound = true
            end
        end,
        Effect = function(ent, time, damageamount, delay, inf)
            local TimeLeft = ent:GetTimeLeft("Poison")
            if TimeLeft > 0.1 then

                if not ent.PoisonEffectDelay then
                    ent.PoisonEffectDelay  = CurTime()
                end

                local PoisonDelay = delay
                if PoisonDelay == nil then PoisonDelay = 0.3 end
                if damageamount == nil then damageamount = 0 end

                if ent:HaveEffect("Healing") then
                    ent:RemoveEffect("Healing")
                end

                if ent:Health() > ent.PoisonEffectHP then
                    ent:SetHealth(ent.PoisonEffectHP)
                elseif ent:Health() <= ent.PoisonEffectHP then
                    ent.PoisonEffectHP = ent:Health()
                end

                if CurTime() >= ent.PoisonEffectDelay  then
                    if IsValid(inf) then
                        local dmg = DamageInfo()
                        dmg:SetDamage(damageamount)
                        dmg:SetInflictor(inf)
                        dmg:SetAttacker(inf)
                        ent:TakeDamageInfo(dmg)
                    else
                        ent:TakeDamage(damageamount)
                    end

                    if damageamount > 0 then
                        ent:EmitSound("npc/antlion_grub/squashed.wav", 100, math.random(70, 135), 1)
                    end

                    ent.PoisonEffectDelay = CurTime() + PoisonDelay
                end
            end
        end,
        EffectEnd = function(ent)
            ent.PoisonEffectDelay = nil
            ent.PoisonEffectHP = nil
            ent.PoisonEffectSound = nil
        end,
        ClientHooks = {
            {
                HookType = "HUDPaintBackground",
                HookFunction = function()
                    local ply = LocalPlayer()
                    local TimeLeft = ply:GetTimeLeft("Poison")
                    local PoisonMat = Material("SEF_Overlay/SEFPoisonOverlay.png")
            
                    if ply:HaveEffect("Poison") then
                        local alpha = 255
                        local fadeStartTime = 0.5 -- Czas w sekundach, kiedy zaczyna zanikać
            
                        if TimeLeft <= fadeStartTime then
                            alpha = math.max(0, 255 * (TimeLeft / fadeStartTime))
                        end
            
                        surface.SetMaterial(PoisonMat)
                        surface.SetDrawColor(255, 255, 255, alpha)
                        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                    end
                end
            }
        },        
        ServerHooks = {},
    },
    TempShield = {
        Name = "Temporary Shield",
        Icon = "SEF_Icons/shieldcomb.png", 
        Desc = function(amount, max)
           return string.format("Temporary Shield negates 100%% of received damage. \n If Temporary Shield stacks reach 0, Effect expires \n Damage above Shield stacks are transfered to health. \n Buff Shield: %g \n Current Shield: %g", max, amount) 
        end,
        Type = "BUFF",
        Stackable = true,
        StackName = "AHP",
        EffectBegin = function(ent, amount)
            ent:SetSEFStacks("TempShield", amount)
            if not ent.TempShieldEffectSound then
                EmitSound("TempShield.mp3", ent:GetPos(), 0, CHAN_AUTO, 1, 100)
                ent.TempShieldEffectSound = true
            end
        end,
        Effect = function(ent) end,
        EffectEnd = function(ent)
            ent:ResetSEFStacks("TempShield")
            ent.TempShieldEffectSound = nil
        end,
        ClientHooks = {},
        ServerHooks = {
            {
                HookType = "EntityTakeDamage",
                HookFunction = function(ent, dmg, taken)
                    local shieldStacks = ent:GetSEFStacks("TempShield")
                    if shieldStacks and shieldStacks > 0 then
                        local damage = dmg:GetDamage()

                        local effectData = EffectData()
                        effectData:SetEntity(ent)
                        effectData:SetScale(1)
                        effectData:SetMagnitude(4)
                        util.Effect("TeslaHitboxes", effectData)

                        if damage > shieldStacks then
                            local remainingDamage = damage - shieldStacks
    
                            ent:RemoveSEFStacks("TempShield", shieldStacks)

                            ent:RemoveEffect("TempShield")
    
                            dmg:SetDamage(remainingDamage)
                        else
                            ent:RemoveSEFStacks("TempShield", damage)

                            local impactSounds = {
                                "physics/metal/metal_computer_impact_bullet1.wav",
                                "physics/metal/metal_computer_impact_bullet2.wav",
                                "physics/metal/metal_computer_impact_bullet3.wav"
                            }
                            local randomSound = impactSounds[math.random(#impactSounds)]
                            EmitSound(randomSound, ent:GetPos(), 0, CHAN_AUTO, 1, 100)

                            dmg:SetDamage(0)
    
                            if ent:GetSEFStacks("TempShield") <= 0 then
                                ent:SoftRemoveEffect("TempShield")
                            end
                        end

                        if ent:GetSEFStacks("TempShield") <= 0 then
                            ent:EmitSound("hl1/fvox/armor_gone.wav")
                        end
                    end
                end,
            }
        }
    },
}