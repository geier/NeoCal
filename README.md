# NeoCal

An incomplete and bug ridden re-implementation of
[calendar.vim](https://github.com/mattn/calendar-vim/) in lua for neovim.

<img width="682" alt="image" src="https://user-images.githubusercontent.com/275330/178367564-6c2d06d1-cb3a-4911-ac63-56f95a2b2177.png">

## Installation
Install with your favorite plugin manager, e.g.
[packer](https://github.com/wbthomason/packer.nvim): `use 'geier/NeoCal'`

## Usage
Create a vsplit with a calendar based on today's date

```
:NeoCal
```

## Configuration

NeoCal supports some calendar hooks so it should work out of the box with
existing plugins such as [vimwiki](https://github.com/vimwiki/vimwiki) and
[riv](https://github.com/gu-fan/riv.vim) (`g.calendar_action` and
`g.calendar_sign` are currently supported).

Some configuration options are also supported, e.g. `g.calendar_diary_extension`
and `g.calendar_diary`.
