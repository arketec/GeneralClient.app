local c = require('component')
local modem = c.get("modem")

modem.broadcast(2000, "hello")