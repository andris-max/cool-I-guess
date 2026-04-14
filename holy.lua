-- // Settings \\ --
local Settings = {
    Enabled = false,
    TriggerKey = Enum.KeyCode.E,
    Delay = 0.001 -- A tiny delay can prevent the game from flagging instant clicks
}

-- // Variables \\ --
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- // Toggle Logic \\ --
uis.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Settings.TriggerKey then
        Settings.Enabled = not Settings.Enabled
        -- Optional: print("Triggerbot:", Settings.Enabled)
    end
end)

-- // Helper Function \\ --
local function getCharacter(target)
    if not target then return nil end
    -- Check parent and grandparent for a Humanoid
    local character = target.Parent
    if character:FindFirstChildOfClass("Humanoid") then
        return character
    end
    
    character = target.Parent.Parent
    if character:FindFirstChildOfClass("Humanoid") then
        return character
    end
    
    return nil
end

-- // Main Loop \\ --
runService.Heartbeat:Connect(function()
    if not Settings.Enabled then return end

    local target = mouse.Target
    local character = getCharacter(target)

    if character and character.Name ~= player.Name then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if humanoid and humanoid.Health > 0 then
            task.wait(Settings.Delay)
            mouse1press()
            task.wait() -- Minimal wait to ensure the press registers
            mouse1release()
        end
    end
end)
