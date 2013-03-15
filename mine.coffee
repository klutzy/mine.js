class Minefield
    constructor: (@window, @columns, @rows, @num_mines, @max_mines=1) ->
        @mines = ((0 for y in [1..@rows]) for x in [1..@columns])
        @tds = ((null for y in [1..@rows]) for x in [1..@columns])

    init_board: ->
        @table = document.createElement('table')
        @table.setAttribute("class", "minetable")

        for y in [0..(@rows-1)]
            tr = document.createElement('tr')
            for x in [0..(@columns-1)]
                @mines[x][y] = 0

                td = document.createElement('td')
                td.setAttribute("id", "x"+x+"y"+y)
                @tds[x][y] = td
                tr.appendChild(td)

            @table.appendChild(tr)

        @window.appendChild(@table)

    init_mines: ->
        num_mine_created = 0
        while num_mine_created < @num_mines
            # infinite loop with probability 0
            x = Math.floor(Math.random() * @columns)
            y = Math.floor(Math.random() * @rows)
            if @mines[x][y] < @max_mines
                @mines[x][y] = 1
                num_mine_created += 1

    stringify: ->
        JSON.stringify(@mines)

window.Minefield = Minefield
