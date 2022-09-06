--[[
    [pfcamoplugin]
    something#7597
    
]]--

-- dependencies
local gui = require(script.Parent.rblxgui.initialize)(plugin,"pfcamoplugin")
local SelectionService = game:GetService("Selection")

-- toolbar
Toolbar = plugin:CreateToolbar("pfcamoplugin")

-- button
local b_ToggleWidget = Toolbar:CreateButton("toggle","toggle plugin widget","")

local Widget = gui.PluginWidget.new({
    ID = "pfcamoplugin",
    Enabled = false,
    DockState = Enum.InitialDockState.Float
})

gui.ViewButton.new()

b_ToggleWidget.Click:Connect(function() Widget.Content.Enabled = not Widget.Content.Enabled end)


local MainPage = gui.Page.new({
    Name = "MAIN",
    TitlebarMenu = Widget.TitlebarMenu,
    Open = true
})

local MainPageFrame = gui.ScrollingFrame.new(nil, MainPage.Content)
MainPageFrame:SetMain()

gui.Textbox.new({
    Text = "pfcamoplugin",
    Font = Enum.Font.SourceSansBold,
    Alignment = Enum.TextXAlignment.Center
})

gui.Textbox.new({
    Text = "Select an object or a group of objects to get started",
    Alignment = Enum.TextXAlignment.Center
})

local UseSelectionButton = gui.Button.new({
    Text = "Use Selection",
    ButtonSize = 0.6,
    Disabled = true
})
SelectionService.SelectionChanged:Connect(function()
    if #SelectionService:Get() > 0 then UseSelectionButton:SetDisabled(false)
    else UseSelectionButton:SetDisabled(true) end
end)

local SelectedObjects = gui.InputField.new({
    Placeholder = "Selected objects",
    DisableEditing = true,
    NoDropdown = true,
    InputSize = 0.8,
    ClearText = true
})

UseSelectionButton:Clicked(function()
    SelectedObjects:SetValue({})
    SelectedObjects:SetValue(SelectionService:Get())
end)

gui.ListFrame.new({Height = 10})

local CamoEditorSection = gui.Section.new({Text = "Skin Editor", Open = true})

local FoundObjects = {}
local CamoSlots = 0
local CamoSlotSections = {}

SelectedObjects:Changed(function(Selection)
    if typeof(Selection) ~= "table" then return end
    FoundObjects = {}
    CamoSlots = 0
    for _, v in pairs(Selection) do
        for _, j in pairs(v:GetDescendants()) do
            if j:IsA("IntValue") and string.sub(j.Name, 1, 4) == "Slot" then
                local SlotNum = tonumber(string.sub(j.Name,5))
                if SlotNum > CamoSlots then CamoSlots = SlotNum end
                local CurrentObject = j.Parent.Parent
                local DoesNotContain = true
                for _, l in pairs(FoundObjects) do
                    if l:GetDebugId() == CurrentObject:GetDebugId() then DoesNotContain = false break end
                end
                if DoesNotContain then FoundObjects[#FoundObjects+1] = CurrentObject end
            end
        end
    end
    for i = 1, CamoSlots do
        local SlotSection = gui.Section.new({Text = "Slot "..i, Open = true}, CamoEditorSection.Content)
        local MaterialList = Enum.Material:GetEnumItems()
        table.sort(MaterialList, function(a, b) return a.Name:lower() < b.Name:lower() end)
        local MaterialSelection = gui.Labeled.new({Text = "Material", Object = gui.InputField.new({
            Placeholder = "Material",
            Items = MaterialList
        })}, gui.ListFrame.new(nil,SlotSection.Content).Content)
        local CamoSelection = gui.Labeled.new({Text = "Applied Skin", Object = gui.InputField.new({Placeholder = "Skin"})}, gui.ListFrame.new(nil,SlotSection.Content).Content)

    end
end)



gui.ListFrame.new({Height = 10})
local DumpGUIButton = gui.Button.new({Text = "Dump GUI"})
DumpGUIButton:Clicked(function() gui.GUIUtil.DumpGUI(Widget.Content) end)