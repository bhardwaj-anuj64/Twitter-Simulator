-module(tester).
-export[start/0].

start() ->
    io:fwrite("\n\n Test Case tor Running\n\n"),
    
    {ok, [Clients_input]} = io:fread("\nEnter number of clients: ", "~s\n"),
    {ok, [Sub_input]} = io:fread("\nMax subs for each client: ", "~s\n"),
    {ok, [Perc_input]} = io:fread("\nPercentage of connection dropout: ", "~s\n"),

    DisconnectClients = list_to_integer(Perc_input),
    Clients = list_to_integer(Clients_input),
    MaxSubscribers = list_to_integer(Sub_input),
    ClientsToDisconnect = DisconnectClients * (0.01) * Clients,

    Data_table = ets:new(messages, [ordered_set, named_table, public]),
    createClients(1, Clients, MaxSubscribers, Data_table),
    Start_Time = erlang:system_time(millisecond),
    End_Time = erlang:system_time(millisecond),
    io:format("\nTime taken: ~p milliseconds\n", [End_Time - Start_Time]).

    createClients(Count, Clients, Sub_max, Data_table) ->    
        UserName = Count,
        Tweet_nos = round(floor(Sub_max/Count)),
        Sub_nos = round(floor(Sub_max/(Clients-Count+1))) - 1,
    
        PID = spawn(client, sample, [UserName, Tweet_nos, Sub_nos, false]),
    
        ets:insert(Data_table, {UserName, PID}),
        if 
            Count == Clients ->
                ok;
            true ->
                createClients(Count+1, Clients, Sub_max, Data_table)
        end.

active_checker(Clients) ->
    numActive = [{C, C_PID} || {C, C_PID} <- Clients, is_process_alive(C_PID) == true],
    if
        numActive == [] ->
            io:format("\nClients Done: ");
        true ->
            active_checker(numActive)
    end.