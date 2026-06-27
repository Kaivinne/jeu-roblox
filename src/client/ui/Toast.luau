--!strict
-- Notifications courtes (info / succès / erreur).
-- Les toasts s'empilent et disparaissent après 3 secondes.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UIUtils = require(script.Parent.UIUtils)

local Toast = {}

local DURATION = 3
local MAX_VISIBLE = 3

local container: Frame? = nil

local function getContainer(): Frame
	if container then
		return container :: Frame
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "ToastGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 200
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "ToastContainer"
	frame.Size = UDim2.new(0.36, 0, 0.5, 0)
	frame.Position = UDim2.new(0.32, 0, 0, 60)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = frame

	container = frame
	return frame
end

local function getColor(kind: string): Color3
	if kind == "success" then
		return UIUtils.Color.Success
	elseif kind == "error" then
		return UIUtils.Color.Crimson
	else
		return UIUtils.Color.Navy
	end
end

function Toast.show(message: string, kind: string?)
	local c = getContainer()
	local toastKind = kind or "info"

	-- Retire le plus ancien si trop de toasts
	local children = c:GetChildren()
	local toastCount = 0
	for _, child in ipairs(children) do
		if child:IsA("Frame") then
			toastCount += 1
		end
	end
	if toastCount >= MAX_VISIBLE then
		for _, child in ipairs(children) do
			if child:IsA("Frame") then
				child:Destroy()
				break
			end
		end
	end

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 44)
	toast.BackgroundColor3 = getColor(toastKind)
	toast.BackgroundTransparency = 1
	toast.BorderSizePixel = 0
	toast.Parent = c
	UIUtils.round(toast, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = UIUtils.Color.White
	label.TextTransparency = 1
	label.Font = UIUtils.Font.Body
	label.TextSize = 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = toast

	-- Fade-in
	local fadeIn = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
	TweenService:Create(toast, fadeIn, { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(label, fadeIn, { TextTransparency = 0 }):Play()

	task.delay(DURATION, function()
		local fadeOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
		local t1 = TweenService:Create(toast, fadeOut, { BackgroundTransparency = 1 })
		local t2 = TweenService:Create(label, fadeOut, { TextTransparency = 1 })
		t1:Play()
		t2:Play()
		t1.Completed:Wait()
		toast:Destroy()
	end)
end

function Toast.info(message: string)
	Toast.show(message, "info")
end

function Toast.success(message: string)
	Toast.show(message, "success")
end

function Toast.error(message: string)
	Toast.show(message, "error")
end

return Toast
