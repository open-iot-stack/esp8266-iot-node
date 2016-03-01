cfg={}
cfg.mode = wifi.SOFTAP -- both station and access point

-- put module in AP mode
wifi.setmode(cfg.mode)
print("Stratus Print Wifi Node")
print("ESP8266 mode is: " .. wifi.getmode())

-- Set the SSID of the module in AP mode and access password
cfg.ap={}
cfg.ap.ssid="STRATUS_PRINT_NODE_"..node.chipid()

print("SSID: STRATUS_PRINT_NODE_"..node.chipid())

cfg.ap.pwd="alfanetwork"

cfg.ipconfig = {}
cfg.ipconfig.ip = "192.168.1.1"
cfg.ipconfig.netmask = "255.255.255.0"
cfg.ipconfig.gateway = "192.168.1.1"

cfg.stationconfig = {}
cfg.stationconfig.ssid = "Internet"   -- Name of the WiFi network you want to join
cfg.stationconfig.pwd =  "password"   -- Password for the WiFi network

-- Now you should see an SSID wireless router named STRATUS_PRINT_NODE_###... when you scan for available WIFI networks
if (wifi.getmode() == wifi.SOFTAP) then
  wifi.ap.config(cfg.ap)
  wifi.ap.setip(cfg.ipconfig)
elseif (wifi.getmode() == wifi.STATION) then
  print(cfg.stationconfig.ssid)
  wifi.sta.config(cfg.stationconfig.ssid,cfg.stationconfig.pwd)
end
ap_mac = wifi.ap.getmac()

led1 = 3 --GPIO0
led2 = 4 --GPIO2
gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive", function(client,request)
    local buf = "";
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
    if(method == nil)then
      _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
    end
    local _GET = {}
    if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
        _GET[k] = v
      end
    end
    buf = buf.."<h1>Stratus Print Node Configuration</h1>";
    buf = buf.."<h2>Wifi Credentials</h2>";
    buf = buf.."<form method=\"get\">";
    buf = buf.."SSID: <input type=\"text\" name=\"ssid\"><br>";
    buf = buf.."Network Key: <input type=\"text\" name=\"nkey\"><br>";
    buf = buf.."<input type=\"submit\" value=\"Submit\"></form>";

    client:send(buf);
    client:close();
    collectgarbage();
    local _on,_off = "",""
    if(_GET.ssid and _GET.nkey) then
      local joinCounter = 0
      local joinMaxAttempts = 6
      cfg.stationconfig.ssid = _GET.ssid        -- Name of the WiFi network you want to join
      cfg.stationconfig.pwd =  _GET.nkey                -- Password for the WiFi network
      srv:close()
      --close the server and set the module to STATION mode
      cfg.mode=wifi.STATION
      wifi.setmode(cfg.mode)
      wifi.sta.config(cfg.stationconfig.ssid,cfg.stationconfig.pwd)
      tmr.alarm(0, 3000, 1, function()
        wifi.sta.config("RPiAP","alfanetwork")
        local ip = wifi.sta.getip()
        if ip == nil and joinCounter < joinMaxAttempts then
          print('Connecting to WiFi Access Point ...')
          joinCounter = joinCounter +1
        else
          if joinCounter == joinMaxAttempts then
            print('Failed to connect to WiFi Access Point.')
          else
            print("Setting up ESP8266 for station mode…Please wait.")
            print("STRATUS PRINT NODE IP now is: " .. wifi.sta.getip())

            print("STRATUS PRINT AP IP now is: " .. wifi.ap.getip())
          end
          tmr.stop(0)
          joinCounter = nil
          joinMaxAttempts = nil
          collectgarbage()
        end
      end)

    elseif(_GET.ssid) then
      buf = buf.."<font color=\"RED\"> Enter Network Key!</font>"
    end
    collectgarbage();
  end)
end)
