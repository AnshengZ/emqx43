%%--------------------------------------------------------------------
%% Copyright (c) 2015-2017 Feng Lee <feng@emqtt.io>.
%%
%% Modified by Ramez Hanna <rhanna@iotblue.net>
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_plugin_kafka).

% -include("emqx_plugin_kafka.hrl").

% -include_lib("emqx/include/emqx.hrl").

-include("emqx.hrl").
-include_lib("kernel/include/logger.hrl").

-export([load/1, unload/0]).

%% Client Lifecircle Hooks
-export([on_client_connect/3
  , on_client_connack/4
  , on_client_connected/3
  , on_client_disconnected/4
  , on_client_authenticate/3
  , on_client_check_acl/5
  , on_client_subscribe/4
  , on_client_unsubscribe/4
]).

%% Session Lifecircle Hooks
-export([on_session_created/3
  , on_session_subscribed/4
  , on_session_unsubscribed/4
  , on_session_resumed/3
  , on_session_discarded/3
  , on_session_takeovered/3
  , on_session_terminated/4
]).

%% Message Pubsub Hooks
-export([on_message_publish/2
  , on_message_delivered/3
  , on_message_acked/3
  , on_message_dropped/4
]).


%% Called when the plugin application start
load(Env) ->
  brod_load([Env]),
  emqx:hook('client.connect', {?MODULE, on_client_connect, [Env]}),
  emqx:hook('client.connack', {?MODULE, on_client_connack, [Env]}),
  emqx:hook('client.connected', {?MODULE, on_client_connected, [Env]}),
  emqx:hook('client.disconnected', {?MODULE, on_client_disconnected, [Env]}),
  emqx:hook('client.authenticate', {?MODULE, on_client_authenticate, [Env]}),
  emqx:hook('client.check_acl', {?MODULE, on_client_check_acl, [Env]}),
  emqx:hook('client.subscribe', {?MODULE, on_client_subscribe, [Env]}),
  emqx:hook('client.unsubscribe', {?MODULE, on_client_unsubscribe, [Env]}),
  emqx:hook('session.created', {?MODULE, on_session_created, [Env]}),
  emqx:hook('session.subscribed', {?MODULE, on_session_subscribed, [Env]}),
  emqx:hook('session.unsubscribed', {?MODULE, on_session_unsubscribed, [Env]}),
  emqx:hook('session.resumed', {?MODULE, on_session_resumed, [Env]}),
  emqx:hook('session.discarded', {?MODULE, on_session_discarded, [Env]}),
  emqx:hook('session.takeovered', {?MODULE, on_session_takeovered, [Env]}),
  emqx:hook('session.terminated', {?MODULE, on_session_terminated, [Env]}),
  emqx:hook('message.publish', {?MODULE, on_message_publish, [Env]}),
  emqx:hook('message.delivered', {?MODULE, on_message_delivered, [Env]}),
  emqx:hook('message.acked', {?MODULE, on_message_acked, [Env]}),
  emqx:hook('message.dropped', {?MODULE, on_message_dropped, [Env]}).

%%--------------------------------------------------------------------
%% Client Lifecircle Hooks
%%--------------------------------------------------------------------

on_client_connect(ConnInfo = #{clientid := ClientId}, Props, _Env) ->
    io:format("Client(~s) connect, ConnInfo: ~p, Props: ~p~n",
        [ClientId, ConnInfo, Props]),
    {ok, Props}.

on_client_connack(ConnInfo = #{clientid := ClientId}, Rc, Props, _Env) ->
    io:format("Client(~s) connack, ConnInfo: ~p, Rc: ~p, Props: ~p~n",
        [ClientId, ConnInfo, Rc, Props]),
    {ok, Props}.

on_client_connected(ClientInfo = #{clientid := ClientId}, ConnInfo, _Env) ->
    io:format("Client(~s) connected, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
        [ClientId, ClientInfo, ConnInfo]).

on_client_disconnected(ClientInfo = #{clientid := ClientId}, ReasonCode, ConnInfo, _Env) ->
    io:format("Client(~s) disconnected due to ~p, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
        [ClientId, ReasonCode, ClientInfo, ConnInfo]).

on_client_authenticate(_ClientInfo = #{clientid := ClientId}, Result, _Env) ->
    io:format("Client(~s) authenticate, Result:~n~p~n", [ClientId, Result]),
    {ok, Result}.

on_client_check_acl(_ClientInfo = #{clientid := ClientId}, Topic, PubSub, Result, _Env) ->
    io:format("Client(~s) check_acl, PubSub:~p, Topic:~p, Result:~p~n",
        [ClientId, PubSub, Topic, Result]),
    {ok, Result}.

on_client_subscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
    io:format("Client(~s) will subscribe: ~p~n", [ClientId, TopicFilters]),
    {ok, TopicFilters}.

on_client_unsubscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
    io:format("Client(~s) will unsubscribe ~p~n", [ClientId, TopicFilters]),
    {ok, TopicFilters}.

%%--------------------------------------------------------------------
%% Session Lifecircle Hooks
%%--------------------------------------------------------------------

on_session_created(#{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) created, Session Info:~n~p~n", [ClientId, SessInfo]).

on_session_subscribed(#{clientid := ClientId}, Topic, SubOpts, _Env) ->
    io:format("Session(~s) subscribed ~s with subopts: ~p~n", [ClientId, Topic, SubOpts]).

on_session_unsubscribed(#{clientid := ClientId}, Topic, Opts, _Env) ->
    io:format("Session(~s) unsubscribed ~s with opts: ~p~n", [ClientId, Topic, Opts]).

on_session_resumed(#{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) resumed, Session Info:~n~p~n", [ClientId, SessInfo]).

on_session_discarded(_ClientInfo = #{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) is discarded. Session Info: ~p~n", [ClientId, SessInfo]).

on_session_takeovered(_ClientInfo = #{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) is takeovered. Session Info: ~p~n", [ClientId, SessInfo]).

on_session_terminated(_ClientInfo = #{clientid := ClientId}, Reason, SessInfo, _Env) ->
    io:format("Session(~s) is terminated due to ~p~nSession Info: ~p~n",
        [ClientId, Reason, SessInfo]).

%%--------------------------------------------------------------------
%% Message PubSub Hooks
%%--------------------------------------------------------------------

%% Transform message and return
on_message_publish(Message = #message{topic = <<"$SYS/", _/binary>>}, _Env) ->
    {ok, Message};

on_message_publish(Message, Env) ->
    #message{id = Id, qos = QoS, topic = Topic, from = From, flags = Flags, headers = Headers, payload = Payload, timestamp = Timestamp} = Message,
    Content = [
        {qos, QoS},
        {topic, Topic},
        {from, From},
        {payload, bin2hexstr_a_f(Payload)},
        {timestamp, Timestamp}
    ],
    Msg = [
      {ct,Timestamp},
      {rt,0},
      {count,0},
      {data,Content}
    ],
    {ok, BrokerValues} = application:get_env(emqx_plugin_kafka, broker),
    getTopic(From),
    KafkaTopic = proplists:get_value(payloadtopic, BrokerValues),
    produce_kafka_message(list_to_binary(KafkaTopic), Msg, From, Env),
    {ok, Message}.

on_message_dropped(#message{topic = <<"$SYS/", _/binary>>}, _By, _Reason, _Env) ->
    ok;
on_message_dropped(Message, _By = #{node := Node}, Reason, _Env) ->
    io:format("Message dropped by node ~s due to ~s: ~s~n",
        [Node, Reason, emqx_message:format(Message)]).

on_message_delivered(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
    io:format("Message delivered to client(~s): ~s~n",
        [ClientId, emqx_message:format(Message)]),
    {ok, Message}.

on_message_acked(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
    io:format("Message acked by client(~s): ~s~n",
        [ClientId, emqx_message:format(Message)]).

%% Called when the plugin application stop
unload() ->
%%  brod_unload(),
    emqx:unhook('client.connect', {?MODULE, on_client_connect}),
    emqx:unhook('client.connack', {?MODULE, on_client_connack}),
    emqx:unhook('client.connected', {?MODULE, on_client_connected}),
    emqx:unhook('client.disconnected', {?MODULE, on_client_disconnected}),
    emqx:unhook('client.authenticate', {?MODULE, on_client_authenticate}),
    emqx:unhook('client.check_acl', {?MODULE, on_client_check_acl}),
    emqx:unhook('client.subscribe', {?MODULE, on_client_subscribe}),
    emqx:unhook('client.unsubscribe', {?MODULE, on_client_unsubscribe}),
    emqx:unhook('session.created', {?MODULE, on_session_created}),
    emqx:unhook('session.subscribed', {?MODULE, on_session_subscribed}),
    emqx:unhook('session.unsubscribed', {?MODULE, on_session_unsubscribed}),
    emqx:unhook('session.resumed', {?MODULE, on_session_resumed}),
    emqx:unhook('session.discarded', {?MODULE, on_session_discarded}),
    emqx:unhook('session.takeovered', {?MODULE, on_session_takeovered}),
    emqx:unhook('session.terminated', {?MODULE, on_session_terminated}),
    emqx:unhook('message.publish', {?MODULE, on_message_publish}),
    emqx:unhook('message.delivered', {?MODULE, on_message_delivered}),
    emqx:unhook('message.acked', {?MODULE, on_message_acked}),
    emqx:unhook('message.dropped', {?MODULE, on_message_dropped}).

brod_load(_Env) ->
    {ok, _} = application:ensure_all_started(gproc),
    {ok, _} = application:ensure_all_started(brod),
    {ok, BrokerValues} = application:get_env(emqx_plugin_kafka, broker),
    Endpoints = proplists:get_value(host, BrokerValues),
    Fun = fun(S) ->
        case string:tokens(S, ":") of
            [Domain] -> {Domain, 9092};
            [Domain, Port] -> {Domain, list_to_integer(Port)}
        end
          end,
    EndpointList = string:tokens(Endpoints, ","),
    KafkaBootstrapEndpoints = [Fun(E) || E <- EndpointList],
    ClientConfig = [{auto_start_producers, true}, {default_producer_config, []}, {reconnect_cool_down_seconds, 10}, {reconnect_cool_down_seconds, 10}],
    ok = brod:start_client(KafkaBootstrapEndpoints, brod_client_1, ClientConfig),
    % emqx_metrics:inc('bridge.kafka.connected'),
    io:format("load brod with ~p~n", [KafkaBootstrapEndpoints]).

brod_unload() ->
    application:stop(brod),
    % emqx_metrics:inc('bridge.kafka.disconnected'),
    io:format("unload brod~n"),
    ok.

getPartition(Key) ->
    {ok, BrokerValues} = application:get_env(emqx_plugin_kafka, broker),
    PartitionNum = proplists:get_value(partitionworkers, BrokerValues),
    <<Fix:120, Match:8>> = crypto:hash(md5, Key),
    abs(Match) rem PartitionNum.

getTopic(ClientId) ->
    Key = iolist_to_binary(ClientId),
    {ok, BrokerValues} = application:get_env(emqx_plugin_kafka, broker),
    KafkaTopic = proplists:get_value(payloadtopic, BrokerValues),
    topics = jsx:decode(iolist_to_binary(KafkaTopic)),
    io:format("topics:~s",[topics]).
%    <<Fix:120, Match:8>> = crypto:hash(md5, Key),
%    index = abs(Match) rem lens.



bin2hexstr_A_F(B) when is_binary(B) ->
    << <<(int2hexchar(H, upper)), (int2hexchar(L, upper))>> || <<H:4, L:4>> <= B>>.

bin2hexstr_a_f(B) when is_binary(B) ->
    << <<(int2hexchar(H, lower)), (int2hexchar(L, lower))>> || <<H:4, L:4>> <= B>>.

int2hexchar(I, _) when I >= 0 andalso I < 10 -> I + $0;
int2hexchar(I, upper) -> I - 10 + $A;
int2hexchar(I, lower) -> I - 10 + $a.

produce_kafka_message(Topic, Message, ClientId, Env) ->
    Key = iolist_to_binary(ClientId),
    Partition = getPartition(Key),
    JsonStr = jsx:encode(Message),
    {ok, BrokerValues} = application:get_env(emqx_plugin_kafka, broker),
    IsAsyncProducer = proplists:get_value(isAsync, BrokerValues),
    if
        IsAsyncProducer == false ->
            brod:produce_sync(brod_client_1, Topic, Partition, ClientId, JsonStr);
        true ->
            brod:produce_no_ack(brod_client_1, Topic, Partition, ClientId, JsonStr)
%%      brod:produce(brod_client_1, Topic, Partition, ClientId, JsonStr)
    end,
    ok.