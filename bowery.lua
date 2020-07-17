--- bowery
-- script manager / loader for crow
--
-- E2 select script (scrolling)
-- K2 load script

local fileselect = require 'fileselect'
local crowutil = include('lib/crowutil')

local bowerydir = 'home/we/dust/code/bowery/lib/bowery/'
local filenames = {}
selected_file = 1
loading = 0

param_index = 0

function is_luafile( filename )
  local dot = string.find( string.reverse(filename), '%.')
  local ext = string.sub( filename, 1-dot )
  return ext == 'lua'
end

function filter( predicatefn, t )
  for k,v in pairs(t) do
    if not predicatefn(v) then table.remove(t,k) end
  end
  return t
end

function init()
  filenames = util.scandir(bowerydir)
  if #filenames == 0 then
    print'bowery not found'
  else
    filenames = filter( is_luafile, filenames )
  end
  redraw()
end


---------------------------------------------
--- drawing helpers

function draw_loading()
  for i=1,7 do
    screen.level(i)
    screen.rect(0,24+(i*2), 128,2)
    screen.fill()
  end
end

function draw_script_selection( name )
  screen.move(1,38)
  screen.level(15)
  screen.aa(1)
  screen.font_face(11) -- Roboto Light Italic
  screen.font_size(12)
  screen.text(string.sub(name,1,-5))
end

function draw_script_list( names )
  for i=1,#filenames do
    --screen.font_face(1) -- default
    --screen.move(i*4,8*i)
    --screen.text(filenames[i])
  end
end

function draw_crow_params()
  -- get a copy of the first up-to-8 params
  local cparams = crowutil.get_params(8)
  
  if #cparams > 0 then
    screen.font_face(1) -- default
    screen.font_size(8)

    -- ensure param selection is in range
    param_index = util.clamp(param_index,1,#cparams)
    
    for i=1,#cparams do
      screen.level( i==param_index and 15 or 8 )
      -- name
      screen.move(64,i*8)
      screen.text(cparams[i].name)
      -- value
      screen.move(127,i*8)
      screen.text_right(cparams[i].value)
    end
    
    -- draw param selection
    screen.move(59,param_index*8)
    screen.text('~')
  end
end

function redraw()
  screen.clear()
  screen.line_width(1)

  if loading == 1 then draw_loading() end
  draw_script_selection( filenames[selected_file] )
  draw_script_list(filenames)
  draw_crow_params()
  screen.update()
end

function key(n,z)
  if n==2 then
    loading = z
    if z == 1 then
      -- upon completion, will call crowutil.ready
      crowutil.upload(bowerydir .. filenames[selected_file])
    end
    redraw()
  end
end

function enc(n,z)
  if n==1 then
    selected_file = util.clamp(selected_file + z, 1, #filenames)
    redraw()
  elseif n==2 then -- choose param
    param_index = util.clamp( param_index + z, 1
                            , crowutil.get_paramcount(8))
    redraw()
  elseif n==3 then -- set param
    crowutil.params.inc(param_index,z)
    redraw()
  end
end

function crowutil.params.ready()
  print 'ready to go!'
  redraw()
end
