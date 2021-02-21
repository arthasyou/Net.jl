import Sockets

function start(port)
    server = Sockets.listen(port)
    @async begin
        while true
            conn = Sockets.accept(server)
            @async begin
                read(conn)
            end
        end
    end
    "start tcp service success"
end

function read(conn)
    try
        while true
            line = readline(conn)
            write(conn, line)
        end
    catch err
        print("connection ended with error $err")
    end
end
