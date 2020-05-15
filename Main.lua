
-- Import libraries
local GUI = require("GUI")
local system = require("System")
local component = require("component")
local modem = component.get("modem")
local filesystem = require('filesystem')
local event = require('event')
event.interruptingEnabled = true

--------------------------------------------------------------------------------
-- Test Data -------------------------------------------------------------------
--------------------------------------------------------------------------------

local testLayoutData = {
  title = "Test UI",
  numberRows = 3,
  numberCols =3,
  textColor = 0xFFFFFF,
  panelColor = 0x4B4B4B,
  buttonBgColor = 0x5B5B5B,
  buttonTextColor = 0xFFFFFF,
  buttonPressBgColor = 0xFFFFFF,
  buttonPressTextColor = 0x5B5B5B,
  altListColor = 0xD2D2D2,
  altListColor2 = 0xE1E1E1,
  cells = {
    {
        {
            type = 'display', 
            w = 0.3, 
            h = 0.4, 
            gui = 'text', 
            port = 1000,
            value = 'Hello World!'
        }, {
            type= 'display', 
            w = 0.3, 
            h = 0.2, 
            itemSize = 1, 
            gui = 'list', 
            values = { 'test_1', 'test_2' } 
        }, {
            type= 'display', 
            w = 0.3, 
            h = 0.2, 
            xInterval = 1, 
            yInterval = 1,
            xPostfix = 0,
            yPostfix = 0,
            address = '456',
            port = 2000,
            gui = 'chart', 
            value = "hello again"
        }
    }, {
        {
            type = 'input', 
            w = 0.4, 
            h = 0.3, 
            gui = 'input'
        }, {
            type = 'button', 
            w = 0.2, 
            h = 0.3, 
            gui = 'button', 
            value = 'submit',
            address = '123',
            port = 1000,
            message = 'hello world'
        }, {
            type = 'button', 
            w = 0.2, 
            h = 0.3, 
            gui = 'button', 
            value = 'add',
            port = 2000,
            message = 'hello add'
        }
    }, {
        {
            type = 'input', 
            w = 0.4, 
            h = 0.3, 
            gui = 'input'
        }, {
            type = 'button', 
            w = 0.3, 
            h = 0.3, 
            gui = 'button', 
            value = 'submit',
            address = '456',
            port = 1000,
            message = 'hello world'
        },{
            type = 'input', 
            w = 0.3, 
            h = 0.2, 
            gui = 'input'
        }
    }
    
  }
}

local function debug(table)
  if (type(table) ~= 'table') then
    GUI.alert(table)
  else
    for k,v in pairs(table) do
        if (type(v) ~= 'table') then
            GUI.alert(k .. ":".. v)
        else
            debug(v)
        end
    end
  end
end

local function log(message)
    if (not filesystem.exists('log.txt')) then
        filesystem.write('log.txt')
    end
    if (message ~= nil) then
        filesystem.append('log.txt', message .. '\n')
    end
end

--------------------------------------------------------------------------------
-- Globals ---------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Program Logic --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- UI Model --
--------------------------------------------------------------------------------
local WindowItem = {}
WindowItem.__index = WindowItem

function WindowItem:new(w,h)
  local self = {
    width = w,
    height = h
  }
  return setmetatable(self, WindowItem)
end

function WindowItem:addButton(cell)
    local button = GUI.button(2, 2, self.width - 2, self.height - 2, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, cell.value)
    button.onTouch = function()
        if (cell.address == nil) then   
            log('Button: ' .. cell.value .. ' pressed: Broadcasting message "' .. cell.message .. ' on port:"' .. cell.port ..'"')
            modem.open(cell.port)
            modem.broadcast(cell.port, cell.message)
            modem.close()
        else
            log('Button: ' .. cell.value .. ' pressed: Sendind message "' .. cell.message .. '" to "' .. cell.address .. ':' .. cell.port ..'"')
            modem.open(cell.port)
            modem.send(cell.address, cell.port, cell.message)
            modem.close()
        end
    end
    return button
end

function WindowItem:addInput()
    local input = GUI.input(1, 1, self.width, self.height, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", "")
    input.onInputFinished = function()
        if (cell.address == nil) then   
            log('Input Broadcasting message "' .. input.text .. ' on port:"' .. cell.port ..'"')
            modem.open(cell.port)
            modem.broadcast(cell.port, input.text)
            modem.close()
        else
            log('Input Sending message "' .. input.text .. ' to address: ' .. cell.address .. ' on port:"' .. cell.port ..'"')
            modem.open(cell.port)
            modem.send(cell.address, cell.port, input.text)
            modem.close()
        end
    end
    
end

function WindowItem:addList(layoutData, cell)
    local cellList = GUI.list(1,1,self.width,self.height,cell.itemSize,0,layoutData.buttonBgColor, layoutData.buttonTextColor,layoutData.altListColor, layoutData.altListColor2, layoutData.buttonPressBgColor, layoutData.buttonPressTextColor, false )
    for _, item in ipairs(cell.values) do 
        cellList:addItem(item)
    end
    return cellList
end

function  WindowItem:addText(layoutData, cell )
    local text = GUI.text(1,1, layoutData.textColor, cell.value)
    modem.open((cell.port))
    event.addHandler(function(name, localNetworkCard, remoteAddress, port, distance, payload, additonal)
        if name == "modem_message" then
            log('Message recieved! From: ' .. remoteAddress .. ' Port: ' .. port)
            if (payload ~= nil) then
                log("Content: " .. payload)
            end
            if (port == cell.port) then
                log('Signal recieved on specified port. Updating values')
                text.value = payload
            end
        end
    end)
    return text
end

function WindowItem:addChart(layoutData, cell)
    local chart = GUI.chart(1, 1, self.width, self.height, layoutData.altListColor, layoutData.altListColor2, layoutData.altListColor, layoutData.altListColor2, cell.xInterval, cell.yInterval, cell.xPostfix, cell.yPostfix, true, {})
    log('Listening on port: ' .. cell.port)
    modem.open((cell.port))
    event.addHandler(function(name, localNetworkCard, remoteAddress, port, distance, payload, additonal)
        if name == "modem_message" then
            log('Message recieved! From: ' .. remoteAddress .. ' Port: ' .. port)
            if (payload ~= nil) then
                log("Content: " .. payload)
            end
            if (port == cell.port) then
                log('Signal recieved on specified port. Updating values')
                table.insert(chart.values, payload)
            end
        end
    end)
    return chart
end

---------------------------------------------------------------------------------
-- User Interface --
---------------------------------------------------------------------------------

-- UI properties
local currentCell = {row = 1, col = 1}
local layoutData = testLayoutData

-- Add a new window to MineOS workspace
local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 60, 20, 0xE1E1E1))

-- Get localization table dependent of current system language
local localization = system.getCurrentScriptLocalization()

-- Add single cell layout to window
local layout = window:addChild(GUI.layout(1, 3, window.width, window.height - 3, layoutData.numberCols, layoutData.numberRows))

for c_i = 1, layoutData.numberCols do
  for r_i = 1, layoutData.numberRows do
    local cell = layoutData.cells[c_i][r_i]
    local c_w = layout.width * cell.w
    local c_h = layout.height * cell.h
    local model = WindowItem:new(c_w, c_h)
    --debug({w = c_w, h = c_h})
    local cellContainer = GUI.container(1,1, c_w, c_h)
      if (cell.type == 'display') then
        if (cell.gui == 'text') then
          local cellPanel = cellContainer:addChild(GUI.panel(1,1, cellContainer.width, cellContainer.height, layoutData.panelColor))
          local cellText = cellContainer:addChild(model:addText(layoutData, cell))
        elseif (cell.gui == 'list') then
          cellContainer:addChild(model:addList(layoutData, cell))
        elseif (cell.gui == 'chart') then
            cellContainer:addChild(model:addChart(layoutData, cell))
        end
      elseif cell.type == 'input' then
        local cellPanel = cellContainer:addChild(GUI.panel(1,1, cellContainer.width, cellContainer.height, 0x4B4B4B))
        cellContainer:addChild(model:addInput())
      elseif cell.type == 'button' then 
        cellContainer:addChild(GUI.panel(1,1, cellContainer.width, cellContainer.height, 0x4B4B4B))
        cellContainer:addChild(model:addButton(cell))
      end
      layout:setPosition(r_i, c_i, layout:addChild(cellContainer))
  end
end 

-- Add nice gray text object to layout
--layout:addChild(GUI.text(1, 1, 0x4B4B4B, localization.greeting .. system.getUser()))

-- Customize MineOS menu for this application by your will
local contextMenu = menu:addContextMenuItem("File")
contextMenu:addItem("New")
contextMenu:addSeparator()
contextMenu:addItem("Open")
contextMenu:addItem("Save", true)
contextMenu:addItem("Save as")
contextMenu:addSeparator()
contextMenu:addItem("Close").onTouch = function()
  window:remove()
end

-- You can also add items without context menu
menu:addItem("Example item").onTouch = function()
  GUI.alert("It works!")
end

-- Create callback function with resizing rules when window changes its' size
window.onResize = function(newWidth, newHeight)
  window.backgroundPanel.width, window.backgroundPanel.height = newWidth, newHeight
  layout.width, layout.height = newWidth, newHeight
end

---------------------------------------------------------------------------------

-- Draw changes on screen after customizing your window
workspace:draw()
