class Minefield
    constructor: (@window, @columns, @rows, @num_mines, @max_mines=1) ->
        # status: 0 if started, -1 if dead, -2 cleared, 1 if ready_to_start
        @game_status = -1

    init_board: ->
        @table = document.createElement('table')
        @table.setAttribute("class", "minetable")

        @flags = ((0 for y in [1..@rows]) for x in [1..@columns])
        @near_flags = ((0 for y in [1..@rows]) for x in [1..@columns])

        @tds = ((null for y in [1..@rows]) for x in [1..@columns])

        for y in [0..(@rows-1)]
            tr = document.createElement('tr')
            for x in [0..(@columns-1)]
                td = document.createElement('td')
                td.setAttribute("id", "x"+x+"y"+y)
                on_click_to = (x_, y_, self) ->
                    ->
                        self.on_click(x_, y_)
                        false
                td.onclick = on_click_to(x, y, this)
                on_rclick_to = (x_, y_, self) ->
                    ->
                        self.on_rclick(x_, y_)
                        false
                td.oncontextmenu = on_rclick_to(x, y, this)

                @tds[x][y] = td
                tr.appendChild(td)

            @table.appendChild(tr)

        @window.appendChild(@table)

    init_mines: ->
        @mines = ((0 for y in [1..@rows]) for x in [1..@columns])
        @near_mines = ((0 for y in [1..@rows]) for x in [1..@columns])

        @remaining = @rows * @columns

        num_mine_created = 0
        while num_mine_created < @num_mines
            # infinite loop with probability 0
            x = Math.floor(Math.random() * @columns)
            y = Math.floor(Math.random() * @rows)
            if @mines[x][y] < @max_mines
                if @mines[x][y] == 0
                    @remaining -= 1
                @mines[x][y] += 1
                for [nx, ny] in @near_positions(x, y)
                    @near_mines[nx][ny] += 1
                num_mine_created += 1
        @game_status = 0

    get_class: (x, y) ->
        td_class = @tds[x][y].getAttribute("class")
        if td_class == null or td_class == ""
            null
        td_class

    set_class: (x, y, val) ->
        if val == null
            @tds[x][y].removeAttribute("class")
        else
            @tds[x][y].setAttribute("class", val)

    near_positions: (x, y) ->
        ret = []
        for nx in [(x-1)..(x+1)]
            for ny in [(y-1)..(y+1)]
                if nx == x and ny == y
                    continue
                if nx >= @columns or nx < 0 or ny >= @rows or ny < 0
                    continue
                ret.push([nx, ny])
        ret

    on_click: (x, y) ->
        if @game_status < 0
            return
        if @game_status == 1
            @start(x, y)

        td_class = @get_class(x, y)
        if td_class != null
            return

        if @expand(x, y) < 0
            @gameover(x, y)

        if @remaining == 0
            @gameclear()

    on_rclick: (x, y) ->
        if @game_status < 0
            return

        @flag(x, y)

    start: (x, y) ->
        # TODO: first click should never die

    flag: (x, y) ->
        td_class = @get_class(x, y)
        if td_class != null and not /^flag/.exec(td_class)
            return

        n = 1
        if @flags[x][y] == @max_mines
            n = -@flags[x][y]

        @flags[x][y] += n
        for [nx, ny] in @near_positions(x, y)
            @near_flags[nx][ny] += n

        if n > 0
            @set_class(x, y, "flag-"+@flags[x][y])
        else
            @set_class(x, y, null)

    press: (x, y) ->
        if @mines[x][y] > 0
            return -1
        else if @get_class(x, y) != null
            return 1

        @remaining -= 1

        if @near_mines[x][y] == 0
            @set_class(x, y, "empty")
        else
            @set_class(x, y, "near-" + @near_mines[x][y])
        return 0

    expand: (start_x, start_y) ->
        if @press(start_x, start_y) < 0
            return -1

        list = [[start_x, start_y]]
        while list.length > 0
            [x, y] = list.pop()
            if @near_mines[x][y] == 0
                for [nx, ny] in @near_positions(x, y)
                    td_class = @get_class(nx, ny)
                    if td_class == null
                        list.push([nx, ny])
                        if @press(nx, ny) < 0
                            return -1
        return 0

    gameover: (fail_x, fail_y) ->
        @game_status = -1
        for y in [0..(@rows-1)]
            for x in [0..(@columns-1)]
                mine = @mines[x][y]
                if mine > 0
                    if /^flag/.exec(@get_class(x, y))
                        continue
                    @set_class(x, y, "mine-" + mine)
                    if fail_x == x and fail_y == y
                        @set_class(x, y, "mine-exploded")
                else
                    if @flags[x][y] > 0
                        @set_class(x, y, "mine-wrong")
                    else if @near_mines[x][y] == 0
                        @set_class(x, y, "empty")
                    else
                        @set_class(x, y, "near-" + @near_mines[x][y])

    gameclear: ->
        @game_status = -2
        # TODO

    stringify: ->
        JSON.stringify(@mines)

window.Minefield = Minefield
