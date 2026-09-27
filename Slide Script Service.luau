local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LOCAL_PLAYER = Players.LocalPlayer
local REMOTES = ReplicatedStorage:WaitForChild("Remotes")
local SLIDE_REMOTE = REMOTES:WaitForChild("Slide")
local SLIDE_ENDED_REMOTE = REMOTES:WaitForChild("SlideEnded")

local SLIDE_ANIMATION_ID = "rbxassetid://ANIMATION ID HERE"
local SLIDE_DEBOUNCE_TIME = 2
local SLIDE_KEY = Enum.KeyCode.LeftControl
local JUMP_KEY = Enum.KeyCode.Space

local slideAnimation = Instance.new("Animation")
slideAnimation.AnimationId = SLIDE_ANIMATION_ID

local isSliding = false
local isOnCooldown = false
local slideTrack: AnimationTrack? = nil

local function getCharacter(): Model?
	return LOCAL_PLAYER.Character
end

local function getHumanoid(): Humanoid?
	local character = getCharacter()
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(): BasePart?
	local character = getCharacter()
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isSprinting(): boolean
	local character = getCharacter()
	return character ~= nil and character:GetAttribute("IsSprinting") == true
end

local function setSlidingState(state: boolean)
	local character = getCharacter()
	if character then
		character:SetAttribute("IsSliding", state)
	end
end

local function stopSlideAnimation()
	if not slideTrack then
		return
	end

	slideTrack:Stop(0)
	slideTrack:Destroy()
	slideTrack = nil
end

local function playSlideAnimation()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	stopSlideAnimation()

	slideTrack = animator:LoadAnimation(slideAnimation)
	slideTrack.Priority = Enum.AnimationPriority.Action
	slideTrack.Looped = true
	slideTrack:Play(0)
end

local function canStartSlide(): boolean
	if isOnCooldown or isSliding then
		return false
	end

	if not isSprinting() then
		return false
	end

	local humanoid = getHumanoid()
	local rootPart = getRootPart()

	if not humanoid or not rootPart then
		return false
	end

	if humanoid.MoveDirection.Magnitude == 0 then
		return false
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		return false
	end

	return true
end

local function endSlide(shouldJump: boolean)
	if not isSliding then
		return
	end

	isSliding = false
	setSlidingState(false)
	stopSlideAnimation()

	SLIDE_REMOTE:FireServer("Stop")

	if shouldJump then
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.Jump = true
		end
	end
end

local function startSlide()
	if not canStartSlide() then
		return
	end

	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	isSliding = true
	isOnCooldown = true
	setSlidingState(true)

	playSlideAnimation()
	SLIDE_REMOTE:FireServer("Start", rootPart.CFrame.LookVector)

	task.delay(SLIDE_DEBOUNCE_TIME, function()
		isOnCooldown = false
	end)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.KeyCode == SLIDE_KEY then
		startSlide()
	elseif input.KeyCode == JUMP_KEY and isSliding then
		endSlide(true)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.KeyCode == SLIDE_KEY and isSliding then
		endSlide(false)
	end
end)

SLIDE_ENDED_REMOTE.OnClientEvent:Connect(function()
	endSlide(false)
end)

LOCAL_PLAYER.CharacterAdded:Connect(function(character: Model)
	isSliding = false
	isOnCooldown = false

	stopSlideAnimation()

	character:SetAttribute("IsSliding", false)
	character:SetAttribute("IsSprinting", false)
end)