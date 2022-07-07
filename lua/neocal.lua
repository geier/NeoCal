require 'os'
require 'io'

date = os.date
time = os.time

WSTART = 2

DAYSECONDS = 24 * 60 * 60

local api = vim.api
local buf, win
local position = 0


function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function open_window()
  buf = api.nvim_create_buf(false, true)
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe') -- if the buffer is hidden, delete it
  api.nvim_buf_set_option(buf, 'filetype', 'Calendar')

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it

  -- we can add title already here, because first line will never change
  --api.nvim_buf_set_lines(buf, 0, -1, false, { center('What have i done?'), '', ''})
  --api.nvim_buf_add_highlight(buf, -1, 'NeoCalHeader', 0, 0, -1)
end

local function update_view(direction)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction
  if position < 0 then position = 0 end

  --local result = vim.fn.systemlist('git diff-tree --no-commit-id --name-only -r  HEAD~'..position)
  --if #result == 0 then table.insert(result, '') end -- add  an empty line to preserve layout if there is no results
  --for k,v in pairs(result) do
  --  result[k] = '  '..result[k]
  --end

  -- Build the table of dates
  today_ts = time()
  today = date("*t", today_ts)
  offset = today.wday - WSTART

  weeks = {}
  first_day_current_week = today_ts - (offset * DAYSECONDS)
  first_day = first_day_current_week - (49 * DAYSECONDS)
  for w=1,20 do
      week = {}
      for i=0,6 do
          week[i + 1] = first_day + i * DAYSECONDS
      end
      first_day = first_day + 7 * DAYSECONDS
      table.insert(weeks, week)
  end

  -- convert into formated tables of strings
  cal = {}
  table.insert(cal, '    Mo Tu We Th Fr Sa Su')
  for i,w in pairs(weeks) do
      month = '   '
      for j, d in pairs(w) do
          if date('*t', d).day == 1 then
              month = date('%b', d)
          end
      end
      week_str = month
      for j, d in pairs(w) do
          filename = get_filename_from_date(d)
          if d == today_ts then
              sign = '*'
          elseif file_exists(filename) then
              sign = '+'
          else
              sign = ' '
          end
          week_str = week_str .. sign .. date('%d', d)
      end
      table.insert(cal, week_str)
  end

  -------
  --api.nvim_buf_set_lines(buf, 1, 2, false, {center('HEAD~'..position)})
  api.nvim_buf_set_lines(buf, 1, -1, false, cal)

  api.nvim_buf_add_highlight(buf, -1, 'NeoCalSubHeader', 1, 0, -1)
  api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_window()
  api.nvim_win_close(win, true)
end

local function open_file()
  local r, c = unpack(vim.api.nvim_win_get_cursor(0))
  r_offset = 2
  c_offset = 3
  if r < r_offset or c < c_offset then
      return
  end
  day_index = math.floor((c - c_offset) / 3 + 1)
  day = weeks[r - r_offset][day_index]

  filename = get_filename_from_date(day)
  close_window()
  api.nvim_command('edit '.. filename)
end

local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end


function file_exists(name)
  -- test if file `name` is readable
  local f = io.open(name,"r")
  if f ~= nil then io.close(f) return true else return false end
end

function get_filename_from_date(day)
    return "/Users/cg/workspace/wiki/diary/" .. date("%Y-%m-%d", day) .. ".md"
end


local function set_mappings()
  local mappings = {
    ['['] = 'update_view(-1)',
    [']'] = 'update_view(1)',
    ['<cr>'] = 'open_file()',
    h = 'update_view(-1)',
    l = 'update_view(1)',
    q = 'close_window()',
    k = 'move_cursor()'
  }

  for k,v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"neocal".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

local function neocal()
  position = 0
  open_window()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, {4, 0})
end

return {
  neocal = neocal,
  update_view = update_view,
  open_file = open_file,
  move_cursor = move_cursor,
  close_window = close_window
}

