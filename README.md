# Twitter-Simulator


Running the Code:

Server: **c(server).**

Client: **c(client).**

If we were to set up three clients, the common for that would be:

**client:start().
client:start().
client:start().**

To run the test case use simulator.erl as follows:

**Tester:start().**

**Note**: The port of the server is set to 4512. Therefore when running the client on the same machine we need to avoid that port.

The tester needs input arguments for the number of clients, Max allowed subscribers and the
Percentage for dropout test for connectivity.

**What is working:**

We verified the running for up to 50000 users while handling roughly 500000 total requests. We
observed a maximum Request served per second value of roughly 5000.

Functionality and simulation of the following functions are working:

● Registering of an account

● Sending a tweet (With/without hashtags and mentions)




<a name="br2"></a>● Re-tweeting a message

● Subscribing to other Users (With a Zipf distribution)

● Querying tweets subscribed to, tweets with specific hashtags, tweets in which the

user is mentioned.

Data around tweets and users have been stored using tables and maps in Erlang. Each of our
clients is an actor communicating with the server to perform the required actions. Every test
client randomly selects one action and sends the server a request to perform that action.
We use the Tester file to invoke a special instance of the client, the tester. When the simulator is
run we can select the number of test clients, the number of tweets, and the percentage of clients
going offline.

**OBSERVATIONS:**

The tabular observation of the average time for each action can be seen as follows. We observe
that the average time is directly proportional to the number of users, with their corresponding
data increasing accordingly.

|<p>Number</p><p>of users</p>|<p>Average requests</p><p>handled (/s)</p>|<p>Follow/Offline</p><p>/Online</p>|QueryMentions|QueryHashTag|Tweet|ReTweet|
| :- | :- | :- | :- | :- | :- | :- |
|250| |2012| |1.5171| |2.6831| |3.0562| |2.4365| |3.5147|
|1000| |4113| |5.3948| |6.0221| |5.9883| |5.0113| |4.2791|
|2500| |4794| |7.8188| |7.7218| |7.7122| |8.9973| |8.6782|
|5000| |5027| |1301.4530| |1304.8756| |1307.0056| |1123.1453| |1231.6104|
|10000| |4429| |2489.7765| |2209.7923| |2335.6143| |2071.8578| |2397.0441|

**Client-side output:**




<a name="br3"></a>**Server side output:**

**ZIPF VISUALISATIONS:**

ZIPF DISTRIBUTION FOR TWEETS vs USERS




<a name="br4"></a>ZIPF DISTRIBUTION FOR FOLLOWERS vs USERS
