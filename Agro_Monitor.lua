-- QuickApp AGRO MONITORING

-- This QuickApp contains data of accumulated temperature and precipitation, soil temperature and moisture from OpenWeathermap via Agro Monitoring. 

-- Accumulated temperature and precipitation is essential to make a right decision depends on a threshold setting. Temperature quantity index calculated as the sum of daily temperatures. Humidity quantity index expressed as the sum of daily precipitation. Soil temperature and moisture are essential indices that allow your customer to adjust irrigation work and prevent crop roots damage.

-- Current soil data is updated 2 times a day. The soil temperature is provided only in Kelvins and in this quickapp converted to Celsius (C = K - 273.15)


-- IMPORTANT
-- You need an API key and Polygon ID from https://agromonitoring.com
-- You need to create your Api key and Polygon ID at https://agromonitoring.com/dashboard/dashboard-start
   -- After your registration click the "New" button in the top of the "Create polygon" screen.
   -- Click on the polygon icon or square icon on the map.
   -- Draw your polygon. If you choose a polygon shape icon do not forget to merge the first and last points to finish your polygon.
   -- Fill in the "Name" field and click the "Create" button to save your polygon.
-- The API is free up to 60 calls per minute and a total area of polygons	of 1000 ha


-- See: https://agromonitoring.com/dashboard/dashboard-start
-- See: https://openweathermap.medium.com/dashboard-update-current-and-historical-soil-data-24422fc75c5b


-- Version 0.1 (22 May 2021)
-- Initial version


-- Variables (mandatory): 
-- apiKey = Get your free API key from https://agromonitoring.com
-- polygon = Create your Polygon ID at https://agromonitoring.com/dashboard/dashboard-start
-- interval = [number] in seconds time to get the data from the API
-- timeout = [number] in seconds for http timeout
-- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
-- icon = [numbber] User defined icon number (add the icon via an other device and lookup the number)

-- Example response:
-- {"dt":1522108800,"t10":281.96,"moisture":0.175,"t0":279.02}
   -- dt = Time of data calculation (unix time, UTC time zone)
   -- t10 = Temperature on the 10 centimeters depth, Kelvins
   -- moisture = Soil moisture, m³/m³
   -- t0 = Surface temperature, Kelvins


-- No editing of this code is needed 


class 'SoilMoisture'(QuickAppChild)
function SoilMoisture:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("SoilMoisture initiated, deviceId:",self.id)
end
function SoilMoisture:updateValue(data) 
  self:updateProperty("value",tonumber(data.SoilMoisture)) 
  self:updateProperty("unit", "m³/m³")
  self:updateProperty("log", "")
end

class 'SoilTemp'(QuickAppChild)
function SoilTemp:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("SoilTemp initiated, deviceId:",self.id)
end
function SoilTemp:updateValue(data) 
  --self:debug("SoilTemp: ",data.SoilTemp)
  self:updateProperty("value",tonumber(data.SoilTemp))
  self:updateProperty("unit", "°C")
  self:updateProperty("log", "")
end

class 'SurfaceTemp'(QuickAppChild)
function SurfaceTemp:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("SurfaceTemp initiated, deviceId:",self.id)
end
function SurfaceTemp:updateValue(data) 
  --self:debug("SurfaceTemp: ",data.SurfaceTemp)
  self:updateProperty("value",tonumber(data.SurfaceTemp))
  self:updateProperty("unit", "°C")
  self:updateProperty("log", "")
end


-- QuickApp functions


local function getChildVariable(child,varName)
  for _,v in ipairs(child.properties.quickAppVariables or {}) do
    if v.name==varName then return v.value end
  end
  return ""
end


function QuickApp:logging(level,text) -- Logging function for debug
  if tonumber(debugLevel) >= tonumber(level) then 
      self:debug(text)
  end
end


function QuickApp:updateProperties() --Update properties
  self:logging(3,"updateProperties")
  self:updateProperty("log", data.datetime)
end


function QuickApp:updateLabels() -- Update labels
  self:logging(3,"updateLabels")
  local labelText = ""
  if debugLevel == 4 then
    labelText = labelText .."SIMULATION MODE" .."\n\n"
  end
  
  labelText = labelText .."Soil Moisture: " ..data.SoilMoisture .." m³/m³" .."\n"
  labelText = labelText .."Soil Temperature (10cm): " ..data.SoilTemp .." °C" .."\n"
  labelText = labelText .."Surface Temperature: " ..data.SurfaceTemp .." °C" .."\n\n"
  labelText = labelText .."Measured: " ..data.datetime .."\n"
  
  self:logging(2,"labelText: " ..labelText)
  self:updateView("label1", "text", labelText) 
end


function QuickApp:getValues() -- Get the values
  self:logging(3,"getValues")
  data.SoilMoisture = string.format("%.3f",jsonTable.moisture)
  data.SoilTemp = string.format("%.1f",tonumber(jsonTable.t10)-273.15)
  data.SurfaceTemp = string.format("%.1f",tonumber(jsonTable.t0)-273.15)
  data.datetime = jsonTable.dt -- Unix time, UTC time zone

  -- Check timezone and daylight saving time
  --local timezone = os.difftime(os.time(), os.time(os.date("!*t",os.time())))/3600
  --if os.date("*t").isdst then -- Check daylight saving time 
  --  timezone = timezone + 1
  --end
  --self:logging(3,"Timezone + dst: " ..timezone)
  -- Convert time of measurement to local timezone
  --data.datetime = os.date("%d-%m-%Y %X", data.datetime + (timezone*3600))
  data.datetime = os.date("%d-%m-%Y %X", data.datetime)
end


function QuickApp:simData() -- Simulate Ambee API
  self:logging(3,"Simulation mode")
  local apiResult = '{"dt":1522108800,"t10":281.96,"moisture":0.175,"t0":279.02}'
  self:logging(3,"apiResult: " ..apiResult)

  jsonTable = json.decode(apiResult) -- Decode the json string from api to lua-table 
  
  self:getValues()
  self:updateLabels()
  self:updateProperties()

  for id,child in pairs(self.childDevices) do 
    child:updateValue(data) 
  end
  
  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function() 
     self:simData()
  end)
end


function QuickApp:getData()
  self:logging(3,"Start getData")
  self:logging(2,"URL: " ..address)
    
  http:request(address, {
    options = {data = Method, method = "GET", headers = {["Content-Type"] = "application/json",["Accept"] = "application/json",}},
    
      success = function(response)
        self:logging(3,"response status: " ..response.status)
        self:logging(3,"headers: " ..response.headers["Content-Type"])
        self:logging(2,"Response data: " ..response.data)

        if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
          self:warning("Temporarily no data from API")
          return 
          --self:logging(3,"No data SetTimeout " ..interval .." seconds")
          --fibaro.setTimeout(interval*1000, function() 
          --  self:getdata()
          --end)
        end

        jsonTable = json.decode(response.data) -- JSON decode from api to lua-table

        self:getValues()
        self:updateLabels()
        self:updateProperties()

        for id,child in pairs(self.childDevices) do 
          child:updateValue(data) 
        end
      
      end,
      error = function(error)
        self:error('error: ' ..json.encode(error))
        self:updateProperty("log", "error: " ..json.encode(error))
      end
    }) 

  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout((interval)*1000, function() 
     self:getData()
  end)
end


function QuickApp:createVariables() -- Get all Quickapp Variables or create them
  data = {}
  data.SoilMoisture = "0"
  data.SoilTemp = "0"
  data.SurfaceTemp = "0"
  data.datetime = ""
end


function QuickApp:getQuickAppVariables() -- Get all variables 
  apiKey = self:getVariable("apiKey")
  polygon = self:getVariable("polygon")
  interval = tonumber(self:getVariable("interval")) 
  httpTimeout = tonumber(self:getVariable("httpTimeout")) 
  debugLevel = tonumber(self:getVariable("debugLevel"))
  local icon = tonumber(self:getVariable("icon")) 

  if apiKey =="" or apiKey == nil then
    apiKey = "" 
    self:setVariable("apiKey",apiKey)
    self:trace("Added QuickApp variable apiKey")
  end
  if polygon =="" or polygon == nil then
    polygon = "" 
    self:setVariable("polygon",polygon)
    self:trace("Added QuickApp variable polygon")
  end
  if interval == "" or interval == nil then
    interval = "60" 
    self:setVariable("interval",interval)
    self:trace("Added QuickApp variable interval")
    interval = tonumber(interval)
  end  
  if httpTimeout == "" or httpTimeout == nil then
    httpTimeout = "5" -- timeoout in seconds
    self:setVariable("httpTimeout",httpTimeout)
    self:trace("Added QuickApp variable httpTimeout")
    httpTimeout = tonumber(httpTimeout)
  end
  if debugLevel == "" or debugLevel == nil then
    debugLevel = "1" -- Default value for debugLevel response in seconds
    self:setVariable("debugLevel",debugLevel)
    self:trace("Added QuickApp variable debugLevel")
    debugLevel = tonumber(debugLevel)
  end
  if icon == "" or icon == nil then 
    icon = "0" -- Default icon
    self:setVariable("icon",icon)
    self:trace("Added QuickApp variable icon")
    icon = tonumber(icon)
  end
  if icon ~= 0 then 
    self:updateProperty("deviceIcon", icon) -- set user defined icon 
  end

  address = "http://api.agromonitoring.com/agro/1.0/soil?polyid=" ..polygon .."&appid=" ..apiKey -- Combine webaddress and location info

  if apiKey == nil or apiKey == ""  then -- Check mandatory API key 
    self:error("API key is empty! Get your free API key from https://agromonitoring.com")
    self:warning("No API Key: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty API key
  end
  if polygon == nil or polygon == ""  then -- Check mandatory polygon ID
    self:error("Polygon ID is empty! Create your Polygon ID at https://agromonitoring.com/dashboard/dashboard-start")
    self:warning("No Polygon ID: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty Polygon ID
  end

end


function QuickApp:setupChildDevices()
  local cdevs = api.get("/devices?parentId="..self.id) or {} -- Pick up all my children 
  function self:initChildDevices() end -- Null function, else Fibaro calls it after onInit()...

  if #cdevs==0 then -- No children, create children
    local initChildData = { 
      {className="SoilMoisture", name="Soil Moisture", type="com.fibaro.multilevelSensor", value=0},
      {className="SoilTemp", name="Soil Temperature", type="com.fibaro.temperatureSensor", value=0},
      {className="SurfaceTemp", name="Surface Temp", type="com.fibaro.temperatureSensor", value=0},
    }
    for _,c in ipairs(initChildData) do
      local child = self:createChildDevice(
        {name = c.name,
          type=c.type,
          value=c.value,
          unit=c.unit,
          initialInterfaces = {}, 
        },
        _G[c.className] -- Fetch class constructor from class name
      )
      child:setVariable("className",c.className)  -- Save class name so we know when we load it next time
    end   
  else 
    for _,child in ipairs(cdevs) do
      local className = getChildVariable(child,"className") -- Fetch child class name
      local childObject = _G[className](child) -- Create child object from the constructor name
      self.childDevices[child.id]=childObject
      childObject.parent = self -- Setup parent link to device controller 
    end
  end
end


function QuickApp:onInit()
  __TAG = fibaro.getName(plugin.mainDeviceId) .." ID:" ..plugin.mainDeviceId
  self:debug("onInit") 
  
  self:setupChildDevices() -- Setup the Child Devices
  self:getQuickAppVariables() -- Get Quickapp Variables or create them
  self:createVariables() -- Create Variables

  http = net.HTTPClient({timeout=httpTimeout*1000})

  if tonumber(debugLevel) >= 4 then 
    self:simData() -- Go in simulation
  else
    self:getData() -- Get data from API
  end
end

--EOF
