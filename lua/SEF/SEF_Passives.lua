PassiveEffects = {
    Template = { --Name and ID of Effect
        Icon = "SEF_Icons/warning.png", --Icon on HUD and displays
        Desc = "", --Optional
        Effect = function(ent, time) --Effect on entity/player, function can be expanded by additional arguments
        end,
        HookType = "", --Hook name 
        HookFunction = function() end -- What function should be added to set HookType.
    },
    IronSkin = {
        Icon = "SEF_Icons/endurance.png",
        Desc = "Received damage is reduced by 20%.",
        Effect = function(ent, time)
        end,
        HookType = "EntityTakeDamage",
        HookFunction = function(target, dmginfo)
            if target and target:HavePassive("IronSkin") then
                dmginfo:ScaleDamage(0.8)
                target:EmitSound("phx/epicmetal_hard.wav", 110, math.random(75, 125), 1)
            end
        end
    },
    Fireborn = {
        Icon = "SEF_Icons/bloodlust.png",
        Desc = "You are immune to Fire Damage and it also heals you.",
        Effect = function(ent, time)
        end,
        HookType = "EntityTakeDamage",
        HookFunction = function(target, dmginfo)
            if target:IsPlayer() and target:HavePassive("Fireborn") then
                if dmginfo:IsDamageType(DMG_BURN) then
                    local healAmount = dmginfo:GetDamage()
                    dmginfo:ScaleDamage(0)
                    if healAmount > 0 then
                        target:SetHealth(math.min(target:Health() + healAmount, target:GetMaxHealth()))
                        target:EmitSound("npc/headcrab_poison/ph_rattle1.wav", 110, math.random(75, 125), 1)
                    end
                end
            end
        end
    }
}