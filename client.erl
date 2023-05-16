-module(client).
-export[start/0, sample/4].

sample(UserName, Tweet_Nos, Sub_Nos, false) ->
    io:fwrite("\n----INITIATE----\n"),
    Port = 4512,
    IP = "localhost",
    {ok, Socket_1} = gen_tcp:connect(IP, Port, [binary, {packet, 0}]),
    
    register_new_user(Socket_1, UserName),
    receive
        {tcp, Socket_1, Data} ->
            io:format("User ~p registered on an account", [Data])
    end,

    sample_check(Socket_1, UserName, Tweet_Nos, Sub_Nos).

sample_check(Socket_1, UserName, Tweet_Nos, Sub_Nos) ->
        if 
        Sub_Nos > 0 ->
            Subs = makeSubs(1, Sub_Nos, []),
            sub_dist(Socket_1, UserName, Subs)
    end,

    User_Mentioned = rand:uniform(list_to_integer(UserName)),
    tweet_delivery(Socket_1, UserName, {"~p has mentioned @~p",[UserName, User_Mentioned]}),
    
    tweet_delivery(Socket_1, UserName, {"~p has tweeted",[UserName]}).

makeSubs(Count, Sub_Nos, List) ->
        if
            (Count == Sub_Nos) ->
                [count | List];
            true ->
                makeSubs(Count+1, Sub_Nos, [Count | List])
        end.

sub_dist(Socket_1, UserName, Subs) ->

    [{SubscribeUserName}|RemainingList] = Subs,
    userSub(Socket_1, UserName, SubscribeUserName),
    sub_dist(Socket_1, UserName, RemainingList).

start() ->
    io:fwrite("\n\n New client \n\n"),
    Port = 4512,
    IP = "localhost",
    {ok, Socket_1} = gen_tcp:connect(IP, Port, [binary, {packet, 0}]),
    io:fwrite("\n\n Connection request sent\n\n"),
    loop(Socket_1, "_").

loop(Socket_1, UserName) ->
    receive
        {tcp, Socket_1, Data} ->
            io:fwrite(Data),
            UserName1 = input_check(Socket_1, UserName),
            loop(Socket_1, UserName1);
        {tcp, closed, Socket_1} ->
            io:fwrite("----Connection CLOSED----") 
        end.

input_check(Socket_1, UserName) ->
        {ok, [Instruction]} = io:fread("\nWhat would you like to do? ", "~s\n"),
    io:fwrite(Instruction),

    if 
        Instruction == "register" ->
            % Input user-name
            {ok, [UserName2]} = io:fread("\nUsername: ", "~s\n"),
            UserName1 = register_new_user(Socket_1, UserName2);
        Instruction == "tweet" ->
            if
                UserName == "_" ->
                    io:fwrite("Unregistered user\n"),
                    UserName1 = input_check(Socket_1, UserName);
                true ->
                    Tweet = io:get_line("\nTweet:"),
                    tweet_delivery(Socket_1,UserName, Tweet),
                    UserName1 = UserName
            end;
        Instruction == "retweet" ->
            if
                UserName == "_" ->
                    io:fwrite("Unregistered user\n"),
                    UserName1 = input_check(Socket_1, UserName);
                true ->
                    {ok, [Person_UserName]} = io:fread("\nRetweet username: ", "~s\n"),
                    Tweet = io:get_line("\nTweet to be reposted: "),
                    retweet(Socket_1, UserName, Person_UserName, Tweet),
                    UserName1 = UserName
            end;
        Instruction == "subscribe" ->
            if
                UserName == "_" ->
                    io:fwrite("Unregistered user.\n"),
                    UserName1 = input_check(Socket_1, UserName);
                true ->
                    SubscribeUserName = io:get_line("\nSubscribe username:"),
                    userSub(Socket_1, UserName, SubscribeUserName),
                    UserName1 = UserName
            end;
        Instruction == "query" ->
            if
                UserName == "_" ->
                    io:fwrite("Unregistered user\n"),
                    UserName1 = input_check(Socket_1, UserName);
                true ->
                    io:fwrite("\n Navigation:\n"),
                    io:fwrite("\n 1. Mentions\n"),
                    io:fwrite("\n 2. Hashtags\n"),
                    io:fwrite("\n 3. Subscribers\n"),
                    {ok, [Option]} = io:fread("\nSpecify the task number you want to perform: ", "~s\n"),
                    tweetQuery(Socket_1, UserName, Option),
                    UserName1 = UserName
            end;
        true ->
            io:fwrite("Unrecognized instruction\n"),
            UserName1 = input_check(Socket_1, UserName)
    end,
    UserName1.


register_new_user(Socket_1, UserName) ->
    % send the server request
    io:format("SELF: ~p\n", [self()]),
    ok = gen_tcp:send(Socket_1, [["register", ",", UserName, ",", pid_to_list(self())]]),
    io:fwrite("\nRegistered\n"),
    UserName.

tweet_delivery(Socket_1,UserName, Tweet) ->
    ok = gen_tcp:send(Socket_1, ["tweet", "," ,UserName, ",", Tweet]),
    io:fwrite("\nTweet Sent to user.\n").

retweet(Socket, UserName,Person_UserName, Tweet) ->
    ok = gen_tcp:send(Socket, ["retweet", "," ,Person_UserName, ",", UserName,",",Tweet]),
    io:fwrite("\nRetweeted on TL.\n").

userSub(Socket_1, UserName, SubscribeUserName) ->
    ok = gen_tcp:send(Socket_1, ["subscribe", "," ,UserName, ",", SubscribeUserName]),
    io:fwrite("\nSubscribed to user.\n").

tweetQuery(Socket_1, UserName, Option) ->
    if
        Option == "1" ->
            ok = gen_tcp:send(Socket_1, ["query", "," ,UserName, ",", "1"]);
        Option == "2" ->
            Hashtag = io:get_line("\nEnter the hahstag you want to search: "),
            ok = gen_tcp:send(Socket_1, ["query", "," ,UserName, ",","2",",", Hashtag]);
        true ->
            ok = gen_tcp:send(Socket_1, ["query", "," ,UserName, ",", "3"])
    end,
    io:fwrite("Related tweet form").

