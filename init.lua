function widgets.clock(...)
    local args = { ... }
    return function()
        return awful.widget.textclock(unpack(args))
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
            rawbutton("1", function () awful.layout.inc( 1) end),
            rawbutton("3", function () awful.layout.inc(-1) end),
            rawbutton("4", function () awful.layout.inc( 1) end),
            rawbutton("5", function () awful.layout.inc(-1) end)
        )
    )
    return box
end

