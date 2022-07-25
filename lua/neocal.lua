require 'os'
require 'io'

date = os.date
time = os.time

WSTART = 2
DAYSECONDS = 24 * 60 * 60
CALENDAR_WIDTH = 25

local api = vim.api
local buf, win, start_win
local position = 0

-- defaults
if vim.g.calendar_diary_extension == nil then
    vim.g.calendar_diary_extension = '.md'
end

if vim.g.calendar_diary == nil then
    vim.g.calendar_diary = vim.loop.os_homedir() .. 'diary'
end
--


function get_filename_from_date(day)
    return vim.g.calendar_diary..'/'..date("%Y-%m-%d", day)..vim.g.calendar_diary_extension
end

function file_exists(name)
  -- test if file `name` is readable
  local f = io.open(name,"r")
  if f ~= nil then io.close(f) return true else return false end
end

function calendar_sign(day)
  filename = get_filename_from_date(day)
  return file_exists(filename)
end

local function update_view(direction)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction
  if position < 0 then position = 0 end

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
          if d == today_ts then
              sign = '*'
          elseif vim.g.calendar_sign ~= nil then
              dtable = date("*t", d)
              rval = vim.fn[vim.g.calendar_sign](dtable.day, dtable.month, dtable.year)
              if rval == 1 then
                  sign = '+'
              else
                  sign = ' '
              end
          elseif calendar_sign(d) then
              sign = '+'
          else
              sign = ' '
          end
          week_str = week_str .. sign .. date('%d', d)
      end
      table.insert(cal, week_str)
  end

  -------
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

  if vim.g.calendar_action ~= nil then
    dtable = date("*t", d)
    -- TODO fix `path` / dir
    vim.fn[vim.g.calendar_action](dtable.day, dtable.month, dtable.year, dtable.weekday, 'path')
  else
    filename = get_filename_from_date(day)
    if vim.api.nvim_win_is_valid(start_win) then
      vim.api.nvim_set_current_win(start_win)
    end
    -- if the file doesn't exist, create it from a templating function
    -- TODO factor out as a function
    if calendar_sign(day) == false then
        -- create calendar file from scratch
        filename = get_filename_from_date(day)
        file = io.open(filename, 'a')
        header = '# '..date("%Y-%m-%d", day)..'\n'
        file:write(header)
        file:close()
    end
    api.nvim_command('edit '.. filename)
  end

end


local function set_mappings()
  local mappings = {
    ['['] = 'update_view(-1)',
    [']'] = 'update_view(1)',
    ['<cr>'] = 'open_file()',
    q = 'close_window()',
  }

  for k,v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"neocal".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
end


local function create_win()
  if win ~= nil then
      close_window()
  end
  start_win = vim.api.nvim_get_current_win()

  vim.api.nvim_command('topleft vnew')
  win = vim.api.nvim_get_current_win()
  buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_name(0, 'NeoCal #' .. buf)

  vim.api.nvim_buf_set_option(0, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(0, 'swapfile', false)
  vim.api.nvim_buf_set_option(0, 'filetype', 'calendar')
  vim.api.nvim_buf_set_option(0, 'bufhidden', 'wipe')

  vim.api.nvim_command('setlocal nowrap')
  vim.api.nvim_command('setlocal nocursorline')
  vim.api.nvim_command('setlocal nonumber')
  vim.api.nvim_command('vertical resize '..CALENDAR_WIDTH)
  -- we might want those as well
  -- setlocal norightleft
  -- setlocal nolist
  -- setlocal winfixwidth

  set_mappings()
end


local function neocal()
  position = 0
  create_win()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, {4, 0})
end


return {
  neocal = neocal,
  close = close,
  open_file = open_file,
  open_and_close = open_and_close,
  update_view = update_view,
}
