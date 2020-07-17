--- crow utilities
-- script uploader & param synchronization
--
-- @module crowutil
-- @release v0.1.0
-- @author trentgill

local crowutil = {}

crowutil.params = {} -- are these functions??
crowutil.public = {} -- where the params are stored


--- upload
-- @arg crow script filepath
-- @arg if present/true, save to crow's internal flash
function crowutil.upload(file, save_to_flash)

  local function delay(seconds)
    -- TODO use clock system for async delay
    local t = util.time()
    while (util.time()-t) < seconds do end
  end

  local function writelines(f)
    for line in io.lines(f) do
      crow.send(line)
      delay(0.01)
    end
  end

  local f = util.file_exists(file)
  if not f then
    print("can't find file: "..file)
    return true -- error
  else
    -- upload routine
    print("loading to crow: ".. file)
    --print("TODO calibrate delay times")
    -- TODO wrap the following in a coroutine using clock system for async behavoiur
    crow.send("^^s")
    delay(0.2)
    writelines(file)
    delay(0.2)
    crow.send(save_to_flash and "^^w" or "^^e")

    --- param synchronization
    -- first clear the public table as we have a potentially new script & need a new UI
    crowutil.public = {}
    -- query the remote device's published params
    crow.send 'params.internal.discover()'
  end
end


--- parameter sync
-- TODO this goes in the crow system library
function norns.crow.pub(...)
  crowutil.pub(...)
end

function crowutil.pub(...)
  local t = {...}
  if t[1] == '_done' then
    crowutil.params.ready()
  else
    -- TODO capture additional type info / metadata
    table.insert( crowutil.public, {name=t[1],value=t[2]}) -- save the key value pair in indexed order
  end
end

function crowutil.params.inc(index,z)
  local p = crowutil.public[index]
  -- TODO apply type/metadata logic here (scaling / limits / increment values)
  p.value = p.value + z*0.1
  -- update crow
  crow.send( 'params.' .. p.name .. '=' .. p.value )
end

function crowutil.get_paramcount(max_count)
  local count = #crowutil.public
  return (count > max_count) and max_count or count
end

function crowutil.get_params(max_count)
  local cp = {} -- table copy
  local count = crowutil.get_paramcount(max_count)
  if count < 1 then return cp end
  
  local cup = crowutil.public --alias
  for i=1,count do
    cp[i] = { name  = cup[i].name
            , value = cup[i].value
            }
  end
  return cp
end


-- user event callback to be redefined
-- means the params have been populated & are accessible with get_params / get_paramcount
function crowutil.params.ready()
  print 'crow.params ready.'
end

return crowutil
