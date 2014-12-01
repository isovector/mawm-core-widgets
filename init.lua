-- hold all prompts created
prompt = nil
prompts = { }

local function add_image(container, img)
    if img then
        container:add(wibox.widget.imagebox(img))
    end
end

function widgets.clock(...)
    -- TODO: This doesn't use the format() function. Is that a bad thing?
    local args = { ... }
    return function(context)

        local box = context.oriented_container()
        add_image(box, beautiful.widget_clock)

        box:add(awful.widget.textclock(unpack(args)))
        return box
    end
end

function widgets.spacer()
    return wibox.widget.textbox(" ")
end

widgets.systray = wibox.widget.systray

function widgets.tags(context)
    return awful.widget.taglist(
        context.screen,
        awful.widget.taglist.filter.all,
        awful.util.table.join(
            rawbutton("1", awful.tag.viewonly),
            rawbutton("mod+1", awful.client.movetotag),
            rawbutton("3", awful.tag.viewtoggle),
            rawbutton("mod+3", awful.client.toggletag),
            rawbutton("4", function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
            rawbutton("5", function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
        ),
        nil,
        nil,
        context.oriented_container()
    )
end

function widgets.prompt(id)
    if id == nil then
        id = "default"
    end

    prompts[id] = awful.widget.prompt()

    if id == "default" then
        -- install global prompt
        prompt = prompts.default
    end

    return function()
        return prompts[id]
    end
end

function widgets.tasks(context)
    return awful.widget.tasklist(
        context.screen,
        awful.widget.tasklist.filter.currenttags,
        awful.util.table.join(
            rawbutton("1", function (c)
                    if c == client.focus then
                        c.minimized = true
                    else
                        -- Without this, the following
                        -- :isvisible() makes no sense
                        c.minimized = false
                        if not c:isvisible() then
                            awful.tag.viewonly(c:tags()[1])
                        end
                        -- This will also un-minimize
                        -- the client, if needed
                        client.focus = c
                        c:raise()
                    end
            end),
            rawbutton("3", function ()
                    if instance then
                        instance:hide()
                        instance = nil
                    else
                        instance = awful.menu.clients({
                                theme = { width = 250 }
                        })
                    end
            end),
            rawbutton("4", function ()
                    awful.client.focus.byidx(1)
                    if client.focus then client.focus:raise() end
            end),
            rawbutton("5", function ()
                    awful.client.focus.byidx(-1)
                    if client.focus then client.focus:raise() end
            end)
        ),
        nil,
        nil,
        context.oriented_container()
    )
end

function widgets.layouts(context)
    local box = awful.widget.layoutbox(context.screen)
    box:buttons(awful.util.table.join(
            rawbutton("1", function () awful.layout.inc(awful.layout.layouts, 1) end),
            rawbutton("3", function () awful.layout.inc(awful.layout.layouts, -1) end),
            rawbutton("4", function () awful.layout.inc(awful.layout.layouts,  1) end),
            rawbutton("5", function () awful.layout.inc(awful.layout.layouts, -1) end)
        )
    )
    return box
end

function widgets.image(image)
    return function()
        wibox.widget.imagebox(image)
    end
end

register_signal("battery")
function widgets.battery(battery)
    local file = string.format("/sys/class/power_supply/%s/capacity", battery)

    local monitor = wibox.widget.textbox("")
    local lastPerc
    local function update_battery()
        local perc = tonumber(first_line(file))

        local color = beautiful.widget_bat_full
        if perc < 15 then
            color = beautiful.widget_bat_low
        elseif perc < 50 then
            color = beautiful.widget_bat_med
        end

        if lastPerc and perc ~= lastPerc then
            emit("battery", perc)
        end
        lastPerc = perc

        color = color or beautiful.fg_normal
        monitor:set_markup(html(color, perc .. "%"))
    end

    return function(context)
        local box = context.oriented_container()
        add_image(box, beautiful.widget_bat)

        update_battery()
        box:add(monitor)

        local updater = timer({ timeout = 60 })
        updater:connect_signal("timeout", update_battery)
        updater:start()

        return box
    end
end

local alsa
commands.alsa = {
    louder = function()
        system("amixer -q set Master 2dB+")
        alsa.update()
    end,
    softer = function()
        system("amixer -q set Master 2dB-")
        alsa.update()
    end,
    -- TODO: we should have a mute here
}

function widgets.alsa(context)
    local monitor = wibox.widget.textbox("")
    local color = beautiful.widget_alsa_fg or beautiful.fg_normal
    local function update_volume()
        local f = assert(io.popen("amixer get Master"))
        local mixer = f:read("*all")
        f:close()

        local perc = string.match(mixer, "([%d]+)%%")

        monitor:set_markup(html(color, perc .. "%"))
    end

    local box = context.oriented_container()
    add_image(box, beautiful.widget_vol)

    update_volume()
    box:add(monitor)

    local updater = timer({ timeout = 3 })
    updater:connect_signal("timeout", update_volume)
    updater:start()

    monitor.update = update_volume
    alsa = monitor

    return box
end

function widgets.network(iface)
    local path = string.format("/sys/class/net/%s/statistics", iface)

    local downmon = wibox.widget.textbox("")
    local upmon = wibox.widget.textbox("")
    local timeout = 3
    local unit = 1024

    local down_color = beautiful.fg_net_down or beautiful.fg_normal
    local up_color = beautiful.fg_net_up or beautiful.fg_normal

    local last_t, last_r = 0, 0
    local function update_network()
        local now_t = first_line(path .. "/tx_bytes") or 0
        local now_r = first_line(path .. "/rx_bytes") or 0

        local dt, dr = now_t - last_t, now_r - last_r
        last_t, last_r = now_t, now_r

        local sent = dt / timeout / unit
        local recv = dr / timeout / unit

        downmon:set_markup(html(down_color, string.format("%.1f", recv)))
        upmon:set_markup(html(up_color, string.format("%.1f", sent)))
    end

    return function(context)
        local box = context.oriented_container()
        add_image(box, beautiful.widget_net_down)
        box:add(downmon)

        add_image(box, beautiful.widget_net_up)
        box:add(upmon)

        update_network()
        update_network()

        local updater = timer({ timeout = timeout })
        updater:connect_signal("timeout", update_network)
        updater:start()

        return box
    end
end

register_signal("cmus")

local cmus
local function cmus_cmd(which)
    return function()
        system("cmus-remote --" .. which)
        if cmus then
            cmus.update()
        end
    end
end

commands.cmus = {
    play = cmus_cmd("play"),
    pause = cmus_cmd("pause"),
    next = cmus_cmd("next"),
    prev = cmus_cmd("prev"),
    stop = cmus_cmd("stop"),
    filter = function(query)
        system("cmus-remote -C \"live-filter " .. query .. "\"")
    end
}

function widgets.cmus(formatter)
    local parsers = {
         ["([%w]+)[%s]([%w]+)$"] = {
             status = true,
             duration = true,
             position = true
         },

         ["tag[%s]([%w]+)[%s](.[^,[(]*)"] = {
             title = true,
             artist = true,
             albumartist = true
         },

         ["tag[%s]([%w]+)[%s](.*)$"] = {
             status = true,
             date = true,
             album = true,
             genre = true
         }
    }

    local checkTags = { "title", "artist" }

    local last = { }

    local monitor = wibox.widget.textbox("")
    local function update_cmus()
        local cmus_state = { }

        local f = io.popen("cmus-remote -Q")
        for line in f:lines() do
            for parser, tags in pairs(parsers) do
                for k, v in string.gmatch(line, parser) do
                    if tags[k] then
                        cmus_state[k] = v:gsub("&", "&amp;")
                    end
                end
            end
        end
        f:close()

        monitor:set_markup(formatter(cmus_state))

        local different = false
        for _, tag in ipairs(checkTags) do
            if last[tag] ~= cmus_state[tag] then
                different = true
                last[tag] = cmus_state[tag]
            end
        end

        if different then
            emit("cmus", cmus_state)
        end
    end

    return function(context)
        local box = context.oriented_container()
        add_image(box, beautiful.widget_note_on)
        box:add(monitor)
        update_cmus()

        local updater = timer({ timeout = 2 })
        updater:connect_signal("timeout", update_cmus)
        updater:start()

        cmus = box
        cmus.update = update_cmus

        return box
    end
end

