local json = require('json')

-- variables

local text_input = ''

-- functions

---@param timeToSleepInSeconds number
local function sleep(timeToSleepInSeconds)
  if not coroutine.isyieldable() then
    error("sleep called from outside a coroutine!")
  end

  local wakeUpTime = system.getUtcTime() + timeToSleepInSeconds
  while system.getUtcTime() < wakeUpTime do coroutine.yield() end
end

---@return string
local function getInputText()
  while text_input == '' do
    sleep(0.1)
  end
  local tempS = text_input
  text_input = ''
  return tempS
end


-- main function

local function main()
  industry.stop(true, false)

  if #industry.getOutputs() == 0 then
    system.setScreen('<p style="color: red;font-size: 80px; text-align: center; padding-top: ' ..system.getScreenHeight() / 4 ..'px;">Please set up the ' .. industry.getClass() .. '!</br></br></br></br>Recipe needed!</p>')
    system.showScreen(true)
    sleep(3)
    unit.exit()
    return
  end

  local pItem = industry.getOutputs()[1].id
  local pRecipe = system.getRecipes(pItem)

  for k, v in ipairs(pRecipe) do
    for k1, v1 in ipairs(v.producers) do
      if v1 == industry.getItemId() then
        pRecipe = v
      end
    end
  end

  system.setScreen('<p style="color: beige;font-size: 80px; text-align: center; padding-top: ' ..system.getScreenHeight() / 4 .. 'px;">How much would you like to process?</p>')
  system.showScreen(true)

  local usrInput = getInputText()

  while tonumber(usrInput) == nil do
    system.print(usrInput .. ' is not a number')
    usrInput = getInputText()
  end

  system.showScreen(false)

  local inputQuantity = tonumber(usrInput)
  local timesProcessing = math.ceil(inputQuantity / industry.getOutputs()[1].quantity)

  if (inputQuantity / industry.getOutputs()[1].quantity) == 0 or (inputQuantity / industry.getOutputs()[1].quantity) == 1 then
    
  else
    system.setScreen('<p style="color: beige;font-size: 80px; text-align: center; padding-top: ' ..system.getScreenHeight() / 4 .. 'px;">'.. inputQuantity ..' not possible. Doing '.. timesProcessing*industry.getOutputs()[1].quantity .. ' instead</p>')
    system.showScreen(true)
    sleep(3)
    system.showScreen(false)
  end

  local isRequiredItems = true
  local existingItems = ''

  system.setScreen('<p style="color: orange;font-size: 80px; text-align: center; padding-top: ' ..system.getScreenHeight() / 4 .. 'px;">Waiting for Container update, please wait.</p>')
  system.showScreen(true)
  while input.updateContent() ~= 0 do
    sleep(1)
  end
  system.showScreen(false)

  local content = input.getContent()
  for k, v in ipairs(pRecipe.ingredients) do
    local containerItem = nil
    for k1, v1 in ipairs(content) do
      if v1.id == v.id then
        containerItem = v1
        if v1.quantity < v.quantity * timesProcessing then
          isRequiredItems = false
        end
      end
    end

    if containerItem == nil then
      existingItems = existingItems ..system.getItem(v.id).displayName .. ': ' .. 0 .. '/' .. v.quantity * timesProcessing .. '</br>'
      isRequiredItems = false
    elseif containerItem.quantity < v.quantity * timesProcessing then
      existingItems = existingItems .. system.getItem(v.id).displayName .. ': ' .. containerItem.quantity .. '/' .. v.quantity * timesProcessing ..'</br>'
    end
  end

  system.setScreen('<p style="color: beige;font-size: 25px; text-align: left; padding-top: ' ..system.getScreenHeight() / 8 .. 'px;">' .. existingItems .. '</p>')
  system.showScreen(true)


  while not isRequiredItems do
    isRequiredItems = true

    while input.updateContent() ~= 0 do
      system.setScreen('<p style="color: beige;font-size: 25px; text-align: left; padding-top: ' ..system.getScreenHeight() / 8 .. 'px;">' .. existingItems .. '</p><p style="color: orange;font-size: 25px; text-align: left;">' .. string.format('%.2f', input.updateContent()) .. '</p>')
      sleep(0.01)
    end
    sleep(0.1)
    existingItems = ''
    content = input.getContent()
  for k, v in ipairs(pRecipe.ingredients) do
    local containerItem = nil
    for k1, v1 in ipairs(content) do
      if v1.id == v.id then
        containerItem = v1
        if v1.quantity < v.quantity * timesProcessing then
          isRequiredItems = false
        end
      end
    end

    if containerItem == nil then
      existingItems = existingItems ..system.getItem(v.id).displayName .. ': ' .. 0 .. '/' .. v.quantity * timesProcessing .. '</br>'
      isRequiredItems = false
    elseif containerItem.quantity < v.quantity * timesProcessing then
      existingItems = existingItems .. system.getItem(v.id).displayName .. ': ' .. containerItem.quantity .. '/' .. v.quantity * timesProcessing ..'</br>'
    end
  end

    system.setScreen('<p style="color: beige;font-size: 25px; text-align: left; padding-top: ' ..system.getScreenHeight() / 8 .. 'px;">' .. existingItems .. '</p>')
    system.showScreen(true)
  end

  system.showScreen(false)

  system.setScreen('<p style="color: green;font-size: 80px; text-align: center; padding-top: ' ..system.getScreenHeight() / 4 .. 'px;">All Items supplied</p>')
  system.showScreen(true)

  industry.startFor(timesProcessing)

  sleep(3)

  unit.exit()
end

local co = coroutine.create(main)
coroutine.resume(co)

-- eventhandlers

system:onEvent('onInputText', function(source, text)
  text_input = text
end)

system:onEvent('onUpdate', function(source)
  coroutine.resume(co)
end)
