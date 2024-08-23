if CLIENT then

    local ply = LocalPlayer()
    ActiveEffects = {}
    ActivePassives = {}
    PlayerEffectStacks = {}
    PlayerPassiveStacks = {}
    AllEntEffects = {}

    surface.CreateFont("SEFFont", {
        font = "Stratum2 Md",
        size = 20,
        weight = 500,
        antialias = true,
        outline = false,
        shadow = true
    })

    surface.CreateFont("SEFFontSmall", {
        font = "Stratum2 Md",
        size = 15,
        weight = 500,
        antialias = true,
        outline = false,
        shadow = true
    })

    CreateClientConVar("SEF_StatusEffectX", 50, true, false, "X position of Status Effects applied on you.", 0, ScrW())
    CreateClientConVar("SEF_StatusEffectY", 925, true, false, "Y position of Status Effects applied on you.", 0, ScrH())
    CreateClientConVar("SEF_ScaleUI", 1, true, false, "Scale UI with this ConVar if you see it too small or too big", 0.1, math.huge)
    CreateClientConVar("SEF_StatusEffectDisplay", 1, true, false, "Shows effects on players/NPCS/Lambdas.", 0, 1)
    local ScaleUI

    local function SplitCamelCase(str)
        return str:gsub("(%l)(%u)", "%1 %2")
    end

    local function DrawStatusEffectTimer(x, y, effectName, effectDesc, duration, startTime)
        local effect = StatusEffects[effectName]
        if not effect then return end

        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
    
        local centerX = x * ScaleUI
        local centerY = y * ScaleUI
        local radius = 22 * ScaleUI
        local innerRadius = 20 * ScaleUI

        if centerX - radius < 0 then centerX = radius end
        if centerY - radius < 0 then centerY = radius end
        if centerX + radius > ScrW() then centerX = ScrW() - radius end
        if centerY + radius > ScrH() then centerY = ScrH() - radius end
    
        surface.SetFont("SEFFont")
    
        local FormattedName = effect.Name or SplitCamelCase(effectName)
    
        local NameW, NameH = surface.GetTextSize(FormattedName)
        local DescW, DescH = 0, 0
        if effectDesc and effectDesc ~= "" then
            DescW, DescH = surface.GetTextSize(effectDesc)
        end
        local DurW, DurH = surface.GetTextSize("Duration: " .. duration .. " seconds")
        local TotalWidth = math.max(NameW, DurW, DescW)
        local TotalHeight = NameH + DurH + DescH
        local StackAmount
        local StackName
        local StackWidth, StackHeight
        local StackNumberWidth, StackNumberHeight
        if PlayerEffectStacks[effectName] then
            StackAmount = PlayerEffectStacks[effectName]
            if effect.StackName then
                StackName = tostring(effect.StackName)
            else
                StackName = "Stacks"
            end
            StackWidth, StackHeight = surface.GetTextSize(StackName)
            StackNumberWidth, StackNumberHeight = surface.GetTextSize(StackAmount)
        else
            StackAmount = 0
            StackName = nil
            StackWidth, StackHeight = nil
            StackNumberWidth, StackNumberHeight = nil
        end
    
        local icon = Material(effect.Icon)
    
        -- Oblicz upływ czasu
        local elapsedTime = CurTime() - startTime
        local fraction = math.Clamp(elapsedTime / duration, 0, 1)
        local startAngle = 270  -- Początkowy kąt (góra)
        local angle = 360 * (1 - fraction)  -- Odwrotność frakcji aby się "opróżniało"
    
        local innerVertices = {}
        table.insert(innerVertices, { x = centerX, y = centerY })
    
        for i = 0, 360, 1 do
            local rad = math.rad(i)
            table.insert(innerVertices, {
                x = centerX + math.cos(rad) * innerRadius,
                y = centerY + math.sin(rad) * innerRadius
            })
        end
    
        if effect.Type == "BUFF" then
            surface.SetDrawColor(9, 73, 0)
        else
            surface.SetDrawColor(53, 0, 0)
        end
        draw.NoTexture()
        surface.DrawPoly(innerVertices)
    
        -- Rysowanie kółka
        local vertices = {}
        table.insert(vertices, { x = centerX, y = centerY })
    
        for i = startAngle, startAngle + angle, 1 do
            local rad = math.rad(i)
            table.insert(vertices, {
                x = centerX + math.cos(rad) * radius,
                y = centerY + math.sin(rad) * radius
            })
        end
    
        if effect.Type == "BUFF" then
            surface.SetDrawColor(30, 255, 0, 255)
            TextColor = Color(30, 255, 0, 255)
        else
            surface.SetDrawColor(255, 0, 0, 255)
            TextColor = Color(255, 0, 0, 255)
        end
        draw.NoTexture()
        surface.DrawPoly(vertices)
    
        surface.SetDrawColor(80, 80, 80)
        surface.SetMaterial(Material("SEF_Icons/StatusEffectCircle.png"))
        surface.DrawTexturedRectRotated(centerX, centerY, 50 * ScaleUI, 50 * ScaleUI, 0)
    
        -- Rysowanie ikony w środku
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(centerX - 16 * ScaleUI, centerY - 16 * ScaleUI, 32 * ScaleUI, 32 * ScaleUI)
    
        local remainingTime = duration - (CurTime() - startTime)
        draw.SimpleText(math.Round(remainingTime), "SEFFont", centerX, centerY + 24 * ScaleUI, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
        if StackAmount > 1 then
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(centerX - StackNumberWidth + 5, centerY + 40 * ScaleUI, StackWidth + StackNumberWidth, StackHeight)
            draw.SimpleText(StackName .. ": " .. StackAmount, "SEFFontSmall", centerX, centerY + 42 * ScaleUI, Color(251, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
        end
    
        if mouseX >= centerX - 16 * ScaleUI and mouseX <= centerX + 16 * ScaleUI and mouseY >= centerY - 16 * ScaleUI and mouseY <= centerY + 16 * ScaleUI then
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(mouseX, mouseY + 30, (TotalWidth + 10), TotalHeight)
            draw.SimpleText(FormattedName, "SEFFont", mouseX + 5, mouseY + 30, Color(255,208,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            if DescH > 0 then
                draw.DrawText(effectDesc, "SEFFont", mouseX + 5, mouseY + 30 + NameH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            draw.SimpleText("Duration: " .. duration .." seconds", "SEFFont", mouseX + 5, mouseY + 45 + DescH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
    

    local function DrawStatusEffectTimerMini(x, y, effectName, duration, startTime)
        local effect = StatusEffects[effectName]
        if not effect then return end

        ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
        local AdjustValue

        if ScaleUI > 2 then
            AdjustValue = ScaleUI * 0.5
        else
            AdjustValue = 1
        end


        local icon = Material(effect.Icon)
        local radius = 11.5 * AdjustValue
        local centerX, centerY = x, y 

    
        -- Oblicz upływ czasu
        local elapsedTime = CurTime() - startTime
        local fraction = math.Clamp(elapsedTime / duration, 0, 1)
        local startAngle = 270  -- Początkowy kąt (góra)
        local angle = 360 * (1 - fraction)  -- Odwrotność frakcji aby się "opróżniało"
    
        -- Rysowanie kółka
        local vertices = {}
        table.insert(vertices, { x = centerX, y = centerY })
    
        for i = startAngle, startAngle + angle, 1 do
            local rad = math.rad(i)
            table.insert(vertices, {
                x = centerX + math.cos(rad) * radius,
                y = centerY + math.sin(rad) * radius
            })
        end
    
        if StatusEffects[effectName].Type == "BUFF" then
            surface.SetDrawColor(30, 255, 0, 255)
        else
            surface.SetDrawColor(255, 0, 0, 255)
        end
        draw.NoTexture()
        surface.DrawPoly(vertices)

        surface.SetDrawColor(80, 80, 80)
        surface.SetMaterial(Material("SEF_Icons/StatusEffectCircle.png"))
        surface.DrawTexturedRectRotated(centerX, centerY, 23 * AdjustValue, 23 * AdjustValue, 0 )
    
        -- Rysowanie ikony w środku
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectRotated(centerX, centerY, 18 * AdjustValue, 18 * AdjustValue, 0)
    end

    local function DrawActivePassive(x, y, passiveName, passiveDesc)
        local effect = PassiveEffects[passiveName]
        if not effect then return end
    
        local mouseX = gui.MouseX()
        local mouseY = gui.MouseY()
        ScaleUI = GetConVar("SEF_ScaleUI"):GetFloat()
    
        -- Przeskalowanie pozycji
        local centerX = x * ScaleUI
        local centerY = y * ScaleUI
    
        surface.SetFont("SEFFont")
    
        local FormattedName = effect.Name or SplitCamelCase(passiveName)
    
        local TextColor = Color(255, 255, 255)
        local NameW, NameH = surface.GetTextSize(FormattedName)
        local DescW, DescH = 0, 0
        if passiveDesc and passiveDesc ~= "" then
            DescW, DescH = surface.GetTextSize(passiveDesc)
        end
        local TotalWidth = math.max(NameW, DescW)
        local TotalHeight = (NameH + DescH)
        local StackAmount
        if PlayerPassiveStacks[effectName] then
            StackAmount = PlayerEffectStacks[effectName]
            if effect.StackName then
                StackName = tostring(effect.StackName)
            else
                StackName = "Stacks"
            end
        else
            StackAmount = 0
            StackName = nil
        end

    
        -- Sprawdzanie granic ekranu
        local halfIconSize = 16 * ScaleUI
        if centerX - halfIconSize < 0 then centerX = halfIconSize end
        if centerY - halfIconSize < 0 then centerY = halfIconSize end
        if centerX + halfIconSize > ScrW() then centerX = ScrW() - halfIconSize end
        if centerY + halfIconSize > ScrH() then centerY = ScrH() - halfIconSize end
    
        local icon = Material(effect.Icon)
    
        -- Rysowanie tła ikony
        surface.SetDrawColor(80, 80, 80)
        surface.SetMaterial(Material("SEF_Icons/PassiveSquare.png"))
        surface.DrawTexturedRectRotated(centerX, centerY, 40 * ScaleUI, 40 * ScaleUI, 0)
    
        -- Rysowanie ikony
        surface.SetMaterial(icon)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(centerX - halfIconSize, centerY - halfIconSize, 32 * ScaleUI, 32 * ScaleUI)

        if StackAmount > 1 then
            draw.SimpleText(StackName .. ": " .. StackAmount, "SEFFontSmall", centerX, centerY + 38 * ScaleUI, Color(251, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
        end
    
        -- Sprawdzanie pozycji myszy
        if mouseX >= centerX - halfIconSize and mouseX <= centerX + halfIconSize and mouseY >= centerY - halfIconSize and mouseY <= centerY + halfIconSize then
            surface.SetDrawColor(0, 0, 0, 155)
            surface.DrawRect(mouseX, mouseY + 30, (TotalWidth + 10), (TotalHeight + 15))
            draw.SimpleText(FormattedName, "SEFFont", mouseX + 5, mouseY + 30, Color(0,162,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("[Passive]", "SEFFont", mouseX + 5, mouseY + 45, Color(0,162,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            if DescH > 0 then
                draw.DrawText(passiveDesc, "SEFFont", mouseX + 5, mouseY + 45 + NameH, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end
    

    local function WithinDistance(A, target, dist)
        local Dist = dist * dist

        return A:GetPos():DistToSqr( target ) < Dist
    end
    

    local function DisplayStatusEffects()
            
        local StatusEffX = GetConVar("SEF_StatusEffectX"):GetInt()
        local StatusEffY = GetConVar("SEF_StatusEffectY"):GetInt()
        local PassiveX = GetConVar("SEF_StatusEffectX"):GetInt()
        local PassiveY = GetConVar("SEF_StatusEffectY"):GetInt() + 25
        local ShowDisplay = GetConVar("SEF_StatusEffectDisplay"):GetBool()
        local THROverHead
        local Margin = 20

        if ConVarExists("THR_OverheadUI") then
            THROverHead = GetConVar("THR_OverheadUI"):GetBool()
        else
            THROverHead = false
        end

        for effectName, effectData in SortedPairsByMemberValue(ActiveEffects, "Duration", true) do

            DrawStatusEffectTimer(StatusEffX , StatusEffY, effectName, effectData.Desc, effectData.Duration, effectData.StartTime)

            StatusEffX = StatusEffX + 50

        end

        for passiveName, passiveData in pairs(ActivePassives) do
            
            DrawActivePassive(PassiveX, PassiveY - 75, passiveName, passiveData)

            PassiveX = PassiveX + 50

        end

        if ShowDisplay then
            for entID, statuseffects in pairs(AllEntEffects) do
                local ent = Entity(entID)
                if IsValid(ent) and entID ~= LocalPlayer():EntIndex() then
                    local PosClient = ent:GetPos() + Vector(0, 0, 80)
                    local screenPos = PosClient:ToScreen()
                    local effectAmount = table.Count(statuseffects)
                    local TotalWidth = (effectAmount - 1) * 25
                    local startX = screenPos.x - (TotalWidth / 2)

                    local tr = util.TraceLine({
                        start = plyEyePos,
                        endpos = EntPos,
                        filter = LocalPlayer()
                    })
    
                    for effectName, effectData in SortedPairsByMemberValue(statuseffects, "Duration", true) do
                        local effectCount = table.Count(statuseffects)
                        if tr.HitPos and WithinDistance(LocalPlayer(), PosClient, 500) then
                            local remainingTime = effectData.Duration - (CurTime() - effectData.StartTime)
                            if remainingTime > 0 then
                                if THROverHead and (ent:IsNPC() or ent:IsNextBot() and not ent.IsLambdaPlayer) then
                                    DrawStatusEffectTimerMini(startX, screenPos.y, effectName, effectData.Duration, effectData.StartTime)
                                elseif THROverHead and ent.IsLambdaPlayer and ent:Team() ~= LocalPlayer():Team() then
                                    DrawStatusEffectTimerMini(startX, screenPos.y, effectName, effectData.Duration, effectData.StartTime)
                                elseif not THROverHead then
                                    DrawStatusEffectTimerMini(startX, screenPos.y, effectName, effectData.Duration, effectData.StartTime)
                                end
                                startX = startX + 25
                            else
                                -- Usuwamy efekt, jeśli czas jego trwania się skończył
                                AllEntEffects[entID][effectName] = nil
                                if table.Count(AllEntEffects[entID]) == 0 then
                                    AllEntEffects[entID] = nil  -- Usuwamy podtabelę, jeśli nie ma już żadnych efektów
                                end
                            end
                        end
                    end
                elseif not IsValid(ent) then
                    print("[Status Effect Framework] Removed data about no longer valid entity.")
                    AllEntEffects[entID] = nil
                end
            end
        end

    end


    net.Receive("SEF_AddEffect", function()
        local EffectName = net.ReadString()
        local Desc = net.ReadString()
        local Duration = net.ReadFloat()
        local StartTime = CurTime()

        local StatusEntry = {
            EffectName = EffectName,
            Desc = Desc,
            Duration = Duration,
            StartTime = StartTime
        }

        ActiveEffects[EffectName] = StatusEntry
    end)

    net.Receive("SEF_RemoveEffect", function()
        local EffectName = net.ReadString()
        ActiveEffects[EffectName] = nil
    end)
    

    net.Receive("SEF_EntityAdd", function()
        local EntID = net.ReadInt(32)
        local EffectName = net.ReadString()
        local Duration = net.ReadFloat()
        local TimeApply = net.ReadFloat()

        if not AllEntEffects[EntID] then
            AllEntEffects[EntID] = {}
        end

        AllEntEffects[EntID][EffectName] = {
            Duration = Duration,
            StartTime = TimeApply
        }
    end)

    net.Receive("SEF_EntityRemove", function()
        local EntID = net.ReadInt(32)
        local EffectName = net.ReadString()

        if AllEntEffects[EntID] and AllEntEffects[EntID][EffectName] then
            AllEntEffects[EntID][EffectName] = nil
            
            -- Usuń podtabelę jeśli nie ma już żadnych efektów
            if next(AllEntEffects[EntID]) == nil then
                AllEntEffects[EntID] = nil
            end
        end
    end)

    net.Receive("SEF_UpdateData", function()
        local EntID = net.ReadInt(32)
        local EffectName = net.ReadString()
        local ChangedTime = net.ReadFloat()

        if AllEntEffects[EntID] and AllEntEffects[EntID][EffectName] then
            AllEntEffects[EntID][EffectName].Duration = ChangedTime
        end

        if EntID == LocalPlayer():EntIndex() then
            if ActiveEffects[EffectName] then
                ActiveEffects[EffectName].Duration = ChangedTime
            end
        end
    end)

    net.Receive("SEF_AddPassive", function() 

        local PassiveName = net.ReadString()
        local PassiveDesc = net.ReadString()
        
        local PassiveEntry = {
            PassiveName = PassiveName,
            PassiveDesc = PassiveDesc
        }

        ActivePassives[PassiveName] = PassiveDesc
    
    end)

    net.Receive("SEF_RemovePassive", function() 
    
        local PassiveName = net.ReadString()
        ActivePassives[PassiveName] = nil
    
    end)

    net.Receive("SEF_StackSystem", function() 
        local command = net.ReadString()
        local effect = net.ReadString()
        local stacks = net.ReadInt(32)
    
        if command == "ADD" then
            if StatusEffects[effect] then
                PlayerEffectStacks[effect] = (PlayerEffectStacks[effect] or 0) + stacks
            elseif PassiveEffects[effect] then
                PlayerPassiveStacks[effect] = (PlayerPassiveStacks[effect] or 0) + stacks
            end
        elseif command == "SET" then
            if StatusEffects[effect] then
                PlayerEffectStacks[effect] = stacks
            elseif PassiveEffects[effect] then
                PlayerPassiveStacks[effect] =  stacks
            end
        elseif command == "REMOVE" then
            if StatusEffects[effect] then
                if PlayerEffectStacks[effect] then
                    PlayerEffectStacks[effect] = PlayerEffectStacks[effect] - stacks
                    if PlayerEffectStacks[effect] <= 0 then
                        PlayerEffectStacks[effect] = nil
                    end
                end
            elseif PassiveEffects[effect] then
                if PlayerPassiveStacks[effect] then
                    PlayerPassiveStacks[effect] = PlayerPassiveStacks[effect] - stacks
                    if PlayerPassiveStacks[effect] <= 0 then
                        PlayerPassiveStacks[effect] = nil
                    end
                end
            end
    
        elseif command == "CLEAR" then
            if StatusEffects[effect] then
                PlayerEffectStacks[effect] = nil
            elseif PassiveEffects[effect] then
                PlayerPassiveStacks[effect] = nil
            end
    
        elseif command == "CLEARALL" then
            PlayerEffectStacks = {}
            PlayerPassiveStacks = {}
        end
    end)

    net.Receive("SEF_UpdateDesc", function()
        local effectName = net.ReadString()
        local newDesc = net.ReadString()

        if ActiveEffects[effectName] then
            ActiveEffects[effectName].Desc = newDesc
        elseif ActivePassives[effectName] then
            ActivePassives[effectName].Desc = newDesc
        end
    end)

    hook.Add("HUDPaint", "DisplayStatusEffectsHUD", DisplayStatusEffects)
end