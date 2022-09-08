--[[
    [pfcamoplugin]
    something#7597
    
]]--

-- dependencies
local gui = require(script.Parent.rblxgui.initialize)(plugin,"pfcamoplugin")
local SelectionService = game:GetService("Selection")
local HttpService = game:GetService("HttpService")

-- toolbar
Toolbar = plugin:CreateToolbar("pfcamoplugin")

-- button
local b_ToggleWidget = Toolbar:CreateButton("toggle","toggle plugin widget","")

local Widget = gui.PluginWidget.new({
    ID = "pfcamoplugin",
    Enabled = false,
    DockState = Enum.InitialDockState.Float
})

local ImportedCamoSaveID = "ImportedCamos"
local TexturePrefix = "PF"

--HttpService.HttpEnabled = true
local Camos = HttpService:JSONDecode(plugin:GetSetting(ImportedCamoSaveID) or "{}")

local FileMenu = plugin:CreatePluginMenu(math.random(), "File Menu")
FileMenu.Name = "FileMenu"
FileMenu:AddNewAction("Import Camos", "Import Camos", "")
FileMenu:AddNewAction("Clear Imported Camos", "Clear Imported Camos", "")
local FileButton = gui.TitlebarButton.new({Name = "FILE", PluginMenu = FileMenu})

FileButton:SelectedAction(function(Action)
    if not Action then return end
    if Action.Text == "Import Camos" then
        local ImportCamoPrompt = gui.TextPrompt.new({Title = "Import Camos", Text = "Select your camo script(s) and press OK", Buttons = {"OK", "Cancel"}})
        SelectionService:Set({})
        ImportCamoPrompt:Clicked(function(p)
            if p == 2 then return end
            local Selection = SelectionService:Get()
            if typeof(Selection) == "table" then
                for _,v in pairs(Selection) do
                    if v:IsA("ModuleScript") then
                        local ImportedScript = require(v)
                        for i,j in ImportedScript do
                            print("Imported " .. tostring(i))
                            Camos[i] = j
                        end
                    end
                end
            end
        end)
    elseif Action.Text == "Clear Imported Camos" then
        Camos = {}
        plugin:SetSetting("{}", Camos)
    end
end)

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
    Text = "Select an model or a group of models to get started",
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

local SelectedModels = gui.InputField.new({
    Placeholder = "Selected models",
    DisableEditing = true,
    NoDropdown = true,
    InputSize = 0.8,
    ClearText = true
})

UseSelectionButton:Clicked(function()
    SelectedModels:SetValue({})
    SelectedModels:SetValue(SelectionService:Get())
end)

gui.ListFrame.new({Height = 10})

local CamoEditorSection = gui.Section.new({Text = "Skin Editor", Open = true})

local Models = {}
local CamoSlotInfo = {}
local Meshes = {}

local function SetMeshProperty(Slot, Property, Value)
    for _, v in pairs(Meshes[Slot]) do
        v[Property] = Value
    end
end
local function SetTexture(Slot, Item)
    for _, v in pairs(Meshes[Slot]) do
        if Item.Value.BrickColor then SetMeshProperty(Slot, "BrickColor", BrickColor.new(Item.Value.BrickColor)) end
        local TextureName = v:FindFirstChild("TextureName")
        if not TextureName then
            TextureName = Instance.new("StringValue", v)
            TextureName.Name = "TextureName"
        end
        local ReqiredFaces = {["Front"] = "", ["Back"] = "", ["Bottom"] = "", ["Top"] = "", ["Left"] = "", ["Right"] = ""}
        TextureName.Value = Item.Name
        for _, j in pairs(v:GetChildren()) do
            if j:IsA("Texture") and string.sub(j.Name,1, string.len(TexturePrefix)) == TexturePrefix then
                local Face = string.sub(j.Name, string.len(TexturePrefix) + 1)
                j.Texture = "rbxassetid://" .. Item.Value.Texture
                ReqiredFaces[Face] = nil
            end
        end
        for i, _ in pairs(ReqiredFaces) do
            local TextureInstance = Instance.new("Texture", v)
            TextureInstance.Name = TexturePrefix .. i
            TextureInstance.Face = Enum.NormalId[i]
            TextureInstance.Texture = "rbxassetid://" .. Item.Value.Texture
        end
    end
end
local function SetTextureProperty(Slot, Property, Value)
    for _, v in pairs(Meshes[Slot]) do
        for _, j in pairs(v:GetChildren()) do
            if j:IsA("Texture") and string.sub(j.Name,1, string.len(TexturePrefix)) == TexturePrefix then
                j[Property] = Value
            end
        end
    end
end

local function UpdateEditor()
    for _, v in pairs(CamoEditorSection.Content:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for i, v in pairs(CamoSlotInfo) do
        local SlotSection = gui.Section.new({Text = "Slot "..i, Open = true}, CamoEditorSection.Content)
        -- Texture Selection
        local CamoSelection = gui.Labeled.new({Text = "Applied Skin", Object = gui.InputField.new({Placeholder = "Texture", CurrentItem = v.Texture})}, gui.ListFrame.new(nil,SlotSection.Content).Content)
        for k,j in pairs(Camos) do
            if not j.TextureId then return end
            local PresetBrickColor
            if j.BrickPreset and j.BrickPreset.BrickColor then PresetBrickColor = j.BrickPreset.BrickColor end
            CamoSelection.Object:AddItem({Name = k, Value = {Texture = j.TextureId, BrickColor = PresetBrickColor}})
        end
        local EditMesh = gui.Section.new({Text = "Edit Mesh", Open = true}, SlotSection.Content)
        local EditTexture = gui.Section.new({Text = "Edit Texture", Open = true}, SlotSection.Content)
        -- Material Editing
        local MaterialList = Enum.Material:GetEnumItems()
        table.sort(MaterialList, function(a, b) return a.Name:lower() < b.Name:lower() end)
        local MaterialSelection = gui.Labeled.new({Text = "Material", Object = gui.InputField.new({
            Placeholder = "Material",
            Items = MaterialList,
            CurrentItem = v.Material
        })}, gui.ListFrame.new(nil,EditMesh.Content).Content)
        MaterialSelection.Object:MouseEnterItem(function(p)
            task.wait(0)
            if typeof(p) ~= "EnumItem" then return end
            SetMeshProperty(i, "Material", p)
        end)
        MaterialSelection.Object:MouseLeaveItem(function()
            if typeof(MaterialSelection.Object.Value) ~= "EnumItem" then return end
            SetMeshProperty(i, "Material", MaterialSelection.Object.Value)
        end)
        MaterialSelection.Object:Changed(function(p)
            if typeof(p) ~= "EnumItem" then return end
            SetMeshProperty(i, "Material", p)
        end)
        local MeshColor = gui.Labeled.new({Text = "Mesh Color", LabelSize = UDim.new(0,90), Object = gui.ColorInput.new({Value = v.Color})}, gui.ListFrame.new(nil,EditMesh.Content).Content)
        MeshColor.Object:Changed(function(p)
            if typeof(p) ~= "Color3" then return end
            SetMeshProperty(i, "Color", p)
        end)
        CamoSelection.Object:Changed(function(p)
            SetTexture(i, {Name = CamoSelection.Object.Input.Text, Value = p})
            if p.BrickColor then MeshColor.Object:SetValue(BrickColor.new(p.BrickColor).Color) end
        end)
        local TextureColor = gui.Labeled.new({Text = "Texture Color", LabelSize = UDim.new(0,90), Object = gui.ColorInput.new({Value = v.Color3})}, gui.ListFrame.new(nil,EditTexture.Content).Content)
        TextureColor.Object:Changed(function(p)
            if typeof(p) ~= "Color3" then return end
            SetTextureProperty(i, "Color3", p)
        end)
        local ReflectanceSlider = gui.Labeled.new({Text = "Reflectance", LabelSize = UDim.new(0,90), Object = gui.Slider.new({Min = 0, Max = 1, Increment = 0.05, Value = v.Reflectance})}, gui.ListFrame.new(nil,EditMesh.Content).Content)
        ReflectanceSlider.Object:Changed(function(p)
            SetMeshProperty(i, "Reflectance", p)
        end)
        local TransparencySlider = gui.Labeled.new({Text = "Transparency", LabelSize = UDim.new(0,90), Object = gui.Slider.new({Min = 0, Max = 1, Increment = 0.05, Value = v.Transparency})}, gui.ListFrame.new(nil,EditTexture.Content).Content)
        TransparencySlider.Object:Changed(function(p)
            SetTextureProperty(i, "Transparency", p)
        end)
        local StudsPerTileU = gui.Labeled.new({Text = "StudsPerTileU", LabelSize = UDim.new(0,90), Object = gui.Slider.new({Min = 0, Max = 5, Increment = 0.05, Value = v.StudsPerTileU or 1})}, gui.ListFrame.new(nil,EditTexture.Content).Content)
        StudsPerTileU.Object:Changed(function(p)
            SetTextureProperty(i, "StudsPerTileU", p)
        end)
        local StudsPerTileV = gui.Labeled.new({Text = "StudsPerTileV", LabelSize = UDim.new(0,90), Object = gui.Slider.new({Min = 0, Max = 5, Increment = 0.05, Value = v.StudsPerTileV or 1})}, gui.ListFrame.new(nil,EditTexture.Content).Content)
        StudsPerTileV.Object:Changed(function(p)
            SetTextureProperty(i, "StudsPerTileV", p)
        end)
        local OffsetStudsU = gui.Labeled.new({Text = "OffsetStudsU", LabelSize = UDim.new(0,90), Object = gui.Slider.new({Min = 0, Max = 4, Increment = 0.05, Value = v.OffsetStudsU})}, gui.ListFrame.new(nil,EditTexture.Content).Content)
        OffsetStudsU.Object:Changed(function(p)
            SetTextureProperty(i, "OffsetStudsU", p)
        end)
        local OffsetStudsV = gui.Labeled.new({Text = "OffsetStudsV", LabelSize = UDim.new(0,90), Object = gui.Slider.new({Min = 0, Max = 4, Increment = 0.05, Value = v.OffsetStudsV})}, gui.ListFrame.new(nil,EditTexture.Content).Content)
        OffsetStudsV.Object:Changed(function(p)
            SetTextureProperty(i, "OffsetStudsV", p)
        end)
    end
    gui.ListFrame.new({Height = 15}, CamoEditorSection.Content)
    local ResetButton = gui.Button.new({Text = "Reset Models", ButtonSize = 0.6}, gui.ListFrame.new(nil, CamoEditorSection.Content).Content)
    ResetButton:Clicked(function()
        for i, v in pairs(Meshes) do
            for _, j in pairs(v) do
                local OriginalColor = j:FindFirstChild("OriginalColor")
                if OriginalColor then SetMeshProperty(i, "Color", OriginalColor.Value) OriginalColor:Destroy() end
                local TextureName = j:FindFirstChild("TextureName")
                if TextureName then TextureName:Destroy() end
                for _, k in pairs(j:GetChildren()) do
                    if k:IsA("Texture") and string.sub(k.Name,1, string.len(TexturePrefix)) == TexturePrefix then
                        k:Destroy()
                    end
                end
            end
        end
        for _, v in pairs(CamoEditorSection.Content:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    end)
end

SelectedModels:Changed(function(Selection)
    Models = {}
    CamoSlotInfo = {}
    Meshes = {}
    if typeof(Selection) == "table" then
        for _, v in pairs(Selection) do
            for _, j in pairs(v:GetDescendants()) do
                if j:IsA("IntValue") and string.sub(j.Name, 1, 4) == "Slot" then
                    local CurrentMesh = j.Parent
                    local CurrentModel = CurrentMesh.Parent
                    local SlotNum = tonumber(string.sub(j.Name,5))
                    Meshes[SlotNum] = Meshes[SlotNum] or {}
                    Meshes[SlotNum][#Meshes[SlotNum]+1] = CurrentMesh
                    if not CurrentMesh:FindFirstChild("OriginalColor") then
                        local OriginalColor = Instance.new("Color3Value", CurrentMesh)
                        OriginalColor.Name = "OriginalColor"
                        OriginalColor.Value = CurrentMesh.Color
                    end
                    if not CamoSlotInfo[SlotNum] then
                        CamoSlotInfo[SlotNum] = {Material = CurrentMesh.Material, Color = CurrentMesh.Color, Reflectance = CurrentMesh.Reflectance}
                    end
                    local MeshTexture = CurrentMesh:FindFirstChildWhichIsA("Texture")
                    if MeshTexture and string.sub(MeshTexture.Name,1,string.len(TexturePrefix)) == TexturePrefix then
                        local TextureName = CurrentMesh:FindFirstChild("TextureName")
                        if TextureName then TextureName = TextureName.Value end
                        CamoSlotInfo[SlotNum].Texture = {Value = MeshTexture.Texture, Name = TextureName}
                        local RequiredProperties = {"Transparency", "OffsetStudsV", "OffsetStudsU", "StudsPerTileV", "StudsPerTileU","Color3"}
                        for _, k in pairs(RequiredProperties) do
                            CamoSlotInfo[SlotNum][k] = MeshTexture[k]
                        end
                    end
                    local DoesNotContain = true
                    for _, l in pairs(Models) do
                        if l:GetDebugId() == CurrentModel:GetDebugId() then DoesNotContain = false break end
                    end
                    if DoesNotContain then Models[#Models+1] = CurrentModel end
                end
            end
        end
    end
    UpdateEditor()
end)

gui.ListFrame.new({Height = 10})
local DumpGUIButton = gui.Button.new({Text = "Dump GUI"})
DumpGUIButton:Clicked(function() gui.GUIUtil.DumpGUI(Widget.Content) end)


plugin.Unloading:Connect(function()
    plugin:SetSetting(ImportedCamoSaveID, HttpService:JSONEncode(Camos))
end)