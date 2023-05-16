-module(server).
-import(maps, []).
-export[start/0].

connect_wait(Receive, Category, Map_Socket) ->
    {ok, Socket} = gen_tcp:accept(Receive),
    ok = gen_tcp:send(Socket, "Someone's knocking"),
    spawn(fun() -> connect_wait(Receive, Category, Map_Socket) end),
    do_recv(Socket, Category, [], Map_Socket).

do_recv(Socket, Category, Bs, Map_Socket) ->
    io:fwrite("---Receive---\n\n"),
    case gen_tcp:recv(Socket, 0) of
        {ok, Data2} ->
            
            Data1 = re:split(Data2, ","),
            Type = binary_to_list(lists:nth(1, Data1)),

            io:format("\n\nDATA: ~p\n\n ", [Data1]),
            io:format("\n\nTYPE: ~p\n\n ", [Type]),

            if 
                Type == "register" ->
                    UserName = binary_to_list(lists:nth(2, Data1)),
                    PID = binary_to_list(lists:nth(3, Data1)),
                    io:format("\nPID:~p\n", [PID]),
                    io:format("\nSocket:~p\n", [Socket]),
                    io:format("Type: ~p\n", [Type]),
                    io:format("\n~p is registering an account.\n", [UserName]),
                    Output = ets:lookup(Category, UserName),
                    io:format("Output: ~p\n", [Output]),
                    if
                        Output == [] ->

                            ets:insert(Category, {UserName, [{"followers", []}, {"tweets", []}]}),      
                            ets:insert(Map_Socket, {UserName, Socket}),                
                            Temp_List = ets:lookup(Category, UserName),
                            io:format("~p", [lists:nth(1, Temp_List)]),

                          
                            ok = gen_tcp:send(Socket, "Registered!"), 
                            io:fwrite("Good to go, Key is not in database\n");
                        true ->
                            ok = gen_tcp:send(Socket, "Username taken"),
                            io:fwrite("Duplicate key!\n")
                    end,
                    do_recv(Socket, Category, [UserName], Map_Socket);

                Type == "tweet" ->
                    UserName = binary_to_list(lists:nth(2, Data1)),
                    Tweet = binary_to_list(lists:nth(3, Data1)),
                    io:format("\n ~p sent you a tweet: ~p", [UserName, Tweet]),
                    
                    X = ets:lookup(Category, UserName),
                    io:format("Output: ~p\n", [X]),
                    X3 = lists:nth(1, X),
                    X2 = element(2, X3),
                    X1 = maps:from_list(X2),
                    {ok, CurrentFollowers} = maps:find("followers",X1),                         
                    {ok, CurrentTweets} = maps:find("tweets",X1),

                    NewTweets = CurrentTweets ++ [Tweet],
                    io:format("~p~n",[NewTweets]),
                    
                    ets:insert(Category, {UserName, [{"followers", CurrentFollowers}, {"tweets", NewTweets}]}),

                    Output_After_Tweet = ets:lookup(Category, UserName),
                    io:format("\nTweet: ~p\n", [Output_After_Tweet]),
                  
                    message_delivery(Socket, Map_Socket, Tweet, CurrentFollowers, UserName),
                    do_recv(Socket, Category, [UserName], Map_Socket);

                Type == "retweet" ->
                    Person_UserName = binary_to_list(lists:nth(2, Data1)),
                    UserName = binary_to_list(lists:nth(3, Data1)),
                    User_sub = string:strip(Person_UserName, right, $\n),
                    io:format("Retweet Username: ~p\n", [User_sub]),
                    Tweet = binary_to_list(lists:nth(4, Data1)),
                    Out = ets:lookup(Category, User_sub),
                    if
                        Out == [] ->
                            io:fwrite("No user found.\n");
                        true ->
                            Out1 = ets:lookup(Category, UserName),
                            X3 = lists:nth(1, Out1), X2 = element(2, X3), X1 = maps:from_list(X2),
                            P_3 = lists:nth(1, Out), P_2 = element(2, P_3), P_1 = maps:from_list(P_2),
                            {ok, CurrentFollowers} = maps:find("followers",X1),
                            {ok, CurrentTweets} = maps:find("tweets",P_1),
                            io:format("Repost Tweet: ~p\n", [Tweet]),
                            CheckTweet = lists:member(Tweet, CurrentTweets),
                            if
                                CheckTweet == true ->
                                    NewTweet = string:concat(string:concat(string:concat("re:",User_sub),"->"),Tweet),
                                    message_delivery(Socket, Map_Socket, NewTweet, CurrentFollowers, UserName);
                                true ->
                                    io:fwrite("Tweet not found.\n")
                            end     
                    end,
                    io:format("\n ~p is retweeting.", [UserName]),
                    do_recv(Socket, Category, [UserName], Map_Socket);

                Type == "subscribe" ->
                    UserName = binary_to_list(lists:nth(2, Data1)),
                    SubscribedUserName = binary_to_list(lists:nth(3, Data1)),
                    User_sub = string:strip(SubscribedUserName, right, $\n),

                    Output1 = ets:lookup(Category, User_sub),
                    if
                        Output1 == [] ->
                            io:fwrite("User not found. \n");
                        true ->

                            X = ets:lookup(Category, User_sub),
                            X3 = lists:nth(1, X),
                            X2 = element(2, X3),

                            X1 = maps:from_list(X2),                            
                            {ok, CurrentFollowers} = maps:find("followers",X1),
                            {ok, CurrentTweets} = maps:find("tweets",X1),

                            NewFollowers = CurrentFollowers ++ [UserName],
                            io:format("~p~n",[NewFollowers]),
                        
                            ets:insert(Category, {User_sub, [{"followers", NewFollowers}, {"tweets", CurrentTweets}]}),

                            Output2 = ets:lookup(Category, User_sub),
                            io:format("\nSubscribe: ~p\n", [Output2]),

                            ok = gen_tcp:send(Socket, "You are subscribed."),

                            do_recv(Socket, Category, [UserName], Map_Socket)
                    end,
                    io:format("\n ~p is subscribing to ~p\n", [UserName, User_sub]),
                    
                    ok = gen_tcp:send(Socket, "You are subscribed."),
                    do_recv(Socket, Category, [UserName], Map_Socket);

                Type == "query" ->
                    Choice = binary_to_list(lists:nth(3, Data1)),
                    UserName = binary_to_list(lists:nth(2, Data1)),
                    io:format("Owned username: ~p\n", [UserName]),
                    if
                        Choice == "1" ->
                            io:fwrite("Mentions:\n");
                        Choice == "2" ->
                            io:fwrite("Hashtags: \n"),
                            Hashtag = binary_to_list(lists:nth(4, Data1)),
                            io:format("Hashtag: ~p\n", [Hashtag]);
                        true ->
                            io:fwrite("Users subscribed to:\n"),
                            Un_Sub = ets:first(Category),
                            User_sub = string:strip(Un_Sub, right, $\n),
                            io:format("Subscriber Name: ~p\n", [User_sub]),
                            X = ets:lookup(Category, User_sub),
                            X3 = lists:nth(1, X),
                            X2 = element(2, X3),
                            X1 = maps:from_list(X2),                            
                            {ok, CurrentTweets} = maps:find("tweets",X1),
                            io:format("\n ~p : ", [User_sub]),
                            io:format("~p~n",[CurrentTweets]),
                            categorySearch(Category, User_sub, UserName)        
                    end,
                    io:format("\n ~p Querying:", [UserName]),
                   
                    do_recv(Socket, Category, [UserName], Map_Socket);
                true ->
                    io:fwrite("\n Choices:")
            end;

        {error, closed} ->
            {ok, list_to_binary(Bs)};
        {error, Reason} ->
            io:fwrite("error"),
            io:fwrite(Reason)
    end.

categorySearch(Category, Key, UserName) ->
    CurrentRow_Key = ets:next(Category, Key),
    X = ets:lookup(Category, CurrentRow_Key),
    X3 = lists:nth(1, X),
    X2 = element(2, X3),
    X1 = maps:from_list(X2),                            
    {ok, CurrentFollowers} = maps:find("followers",X1),
    IsMember = lists:member(UserName, CurrentFollowers),
    if
        IsMember == true ->
            {ok, CurrentTweets} = maps:find("tweets",X1),
            io:format("\n ~p : ", [CurrentRow_Key]),
            io:format("~p~n",[CurrentTweets]),
            categorySearch(Category, CurrentRow_Key, UserName);
        true ->
            io:fwrite("\n End of tweets.\n")
    end,

    io:fwrite("\n Categorically searching...\n").
tweet_search(Symbol, Category_List, Word) ->
    Search = string:concat(Symbol, Word),
    io:format("Search: ~p\n", [Search]),
    [Row_To_Check | Remaining_List ] = Category_List,
    X3 = lists:nth(2, Row_To_Check),
    X2 = element(2, X3),
    X1 = maps:from_list(X2),                            
    {ok, CurrentTweets} = maps:find("tweets",X1),
    io:fwrite("Search Tweets\n"),
    tweet_search(Symbol, Category_List, Word).

message_delivery(Socket, Map_Socket, Tweet, Subscribers, UserName) ->
    if
        Subscribers == [] ->
            io:fwrite("\nFollowers empty.\n");
        true ->
            

            [Client_To_Send | Remaining_List ] = Subscribers,
            io:format("Client to send: ~p\n", [Client_To_Send]),
            io:format("\nRemaining List: ~p~n",[Remaining_List]),
            Client_Socket_Row = ets:lookup(Map_Socket,Client_To_Send),
            X3 = lists:nth(1, Client_Socket_Row),
            Client_Socket = element(2, X3),
            io:format("\nClient Socket: ~p~n",[Client_Socket]),
            
            ok = gen_tcp:send(Client_Socket, ["A tweet has been received.\n",UserName,":",Tweet]),
            ok = gen_tcp:send(Socket, "A tweet has been sent."),
            
            message_delivery(Socket, Map_Socket, Tweet, Remaining_List, UserName)
    end,
    io:fwrite("Messenger:\n").

listToString(L) ->
    listToString(L,[]).

listToString([],Acc) ->
    lists:flatten(["[",
           string:join(lists:reverse(Acc),","),
           "]"]);
listToString([{X,Y}|Rest],Acc) ->
    S = ["{\"x\":\"",X,"\", \"y\":\"",Y,"\"}"],
    listToString(Rest,[S|Acc]).

map_disp(Map) ->
    io:fwrite("-----\n"),
    List1 = maps:to_list(Map),
    io:format("~s~n",[listToString(List1)]),
    io:fwrite("-----\n").

loop_connection(Socket) ->
    io:fwrite("Connecting:\n\n"),
    receive
        {tcp, Socket, Data1} ->
            io:fwrite("...."),
            io:fwrite("\n ~p \n", [Data1]),
            if 
                Data1 == <<"register_account">> ->
                    io:fwrite("Register client"),
                    ok = gen_tcp:send(Socket, "username"), % RESPOND BACK - YES/NO
                    io:fwrite("has been registered");
                true -> 
                    io:fwrite("TRUTH")
            end,
            loop_connection(Socket);
            
        {tcp_closed, Socket} ->
            io:fwrite("I swear I am not here!"),
            closed
    end.

start() ->
    io:fwrite("\n\n----TWITTER ENGINE----\n\n"),
    Category = ets:new(messages, [ordered_set, named_table, public]),
    Map_Socket = ets:new(clients, [ordered_set, named_table, public]),
    Clients = [],
    Map = maps:new(),
    {ok, Socket_Receive} = gen_tcp:listen(4512, [binary, {keepalive, true}, {reuseaddr, true}, {active, false}]),
    connect_wait(Socket_Receive, Category, Map_Socket).
