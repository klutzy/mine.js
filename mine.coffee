class Minefield
    constructor: (@window, @game_status_changed_func=null) ->
        # status: 0 if started, -1 if dead, -2 cleared, 1 if ready_to_start
        @game_status = -1
        @table = null

    new_table: ->
        ((0 for y in [1..@rows]) for x in [1..@columns])

    init_board: (@columns, @rows, @num_mines, @max_mines=1) ->
        @reset_board()

    reset_board: ->
        if @table
            @window.removeChild(@table)
            @game_status = -1
            @table = null

        @table = document.createElement('table')
        @table.setAttribute("class", "minetable")

        @flags = @new_table()
        @near_flags = @new_table()
        @tds = @new_table()

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

        @init_mines()
        @on_game_status_changed() # 0 -> 1

    init_mines: ->
        @mines = @new_table()

        @remaining = @rows * @columns

        num_mine_created = 0
        while num_mine_created < @num_mines
            # infinite loop with probability 0
            x = Math.floor(Math.random() * @columns)
            y = Math.floor(Math.random() * @rows)
            if @mines[x][y] < @max_mines
                n_max = @max_mines - @mines[x][y]
                n_max = Math.min(n_max, @num_mines - num_mine_created)
                n = Math.floor(Math.random() * n_max) + 1
                if @mines[x][y] == 0
                    @remaining -= 1
                @mines[x][y] += n
                num_mine_created += n
        @near_mines = @generate_near_mines(@mines)
        @game_status = 1

    generate_near_mines: (mines) ->
        near_mines = @new_table()
        for x in [0..(@columns-1)]
            for y in [0..(@rows-1)]
                for [nx, ny] in @near_positions(x, y)
                    near_mines[nx][ny] += mines[x][y]
        near_mines

    shift_table: (table, dx, dy) ->
        new_table = @new_table()
        for ny in [0..(@rows-1)]
            for nx in [0..(@columns-1)]
                new_x = (nx + dx + 2*@columns) % @columns
                new_y = (ny + dy + 2*@rows) % @rows
                new_table[new_x][new_y] = table[nx][ny]

        new_table

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
        old_game_status = @game_status
        if @game_status < 0
            return
        if @game_status == 1
            @start(x, y)

        td_class = @get_class(x, y)

        if @expand(x, y) < 0
            @gameover(x, y)

        if @remaining == 0
            @gameclear()

        if old_game_status != @game_status
            @on_game_status_changed()

    on_rclick: (x, y) ->
        old_game_status = @game_status
        if @game_status < 0
            return

        if @game_status == 1
            @game_status = 0

        @flag(x, y)

        if old_game_status != @game_status
            @on_game_status_changed()

    on_game_status_changed: ->
        if @game_status_changed_func
            @game_status_changed_func(@game_status)

    start: (x, y) ->
        @game_status = 0
        if @mines[x][y] == 0
            return

        for nx in [0..(@columns-1)]
            for ny in [0..(@rows-1)]
                if @mines[nx][ny] == 0
                    @mines = @shift_table(@mines, x - nx, y - ny)
                    @near_mines = @generate_near_mines(@mines)

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
        start_mines = @near_mines[start_x][start_y]
        start_flags = @near_flags[start_x][start_y]
        if td_class != null and start_mines == start_flags
            for [nx, ny] in @near_positions(start_x, start_y)
                td_class = @get_class(nx, ny)
                if td_class == null
                    list.push([nx, ny])
                    if @press(nx, ny) < 0
                        return -1

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

    stringify: ->
        JSON.stringify(@mines)

window.Minefield = Minefield
