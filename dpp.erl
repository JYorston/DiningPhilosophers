
-module(dpp).
-compile([export_all]).



% Spawn some Forks
% and some philosophers
% assign fork positions to philosophers
college() ->
  F1 = spawn(?MODULE,fork,[1]),
  F2 = spawn(?MODULE,fork,[2]),
  F3 = spawn(?MODULE,fork,[3]),
  F4 = spawn(?MODULE,fork,[4]),
  F5 = spawn(?MODULE,fork,[5]),
  spawn(?MODULE, philosopher,["Plato",{F5,F1}]),
  spawn(?MODULE, philosopher,["Aristotle",{F1,F2}]),
  spawn(?MODULE, philosopher,["Socrates",{F2,F3}]),
  spawn(?MODULE, philosopher,["Confucious",{F3,F4}]),
  spawn(?MODULE, philosopher,["Descartes",{F4,F5}]).


% A fork process
% Forks are numbered 1 - 5 inclusive
% Has a Position
% Once a fork has been picked up
% Spawns a forkInUse process
% That new process waits for a message and updates the fork
% If fork gets put down then recurse
fork(Position) ->
  receive
    {pickup, P} ->  P ! pickup,
    receive
      Msg -> FIN = spawn(?MODULE,forkInUse,[self(),Position]),
            FIN ! Msg,
      receive
        ok -> fork(Position)
      end
    end
  end.

% Created when a fork is in use
% If fork is put down then updates the parent fork
% Otherwise the fork is in use by someone else
forkInUse(F,Position) ->
receive
  putdown -> F ! ok;
  {_, P}  -> io:format("Fork ~w in use ~n",[Position]),
            P ! {inUse, self()}, forkInUse(F,Position)
end.

% Philosopher has a name and a tuple of 2 Forks
% Philosopher transitions between 3 sates
% Needs both forks to eat
% Recurse once the philospher has eaten
philosopher(Name,Forks) ->

  F1 = element(1,Forks),
  F2 = element(2,Forks),

  % Think a bit
  io:format("~s is thinking.~n", [Name]),
  timer:sleep(round(rand:uniform()*1000)),

  % Getting peckish
  io:format("~s is hungry~n", [Name]),

  % Try and pickup both forks
  spawn(?MODULE, tryPickUp, [Name,F1,F2,self()]),

  % Once we have both forks then we eat for a bit
  % put both forks down and recurse
  receive
    gotBothForks -> io:format("~s is eating~n", [Name]),
                    timer:sleep(round(rand:uniform()*1000)),
                    F1 ! putdown,
                    F2 ! putdown,
                    philosopher(Name,Forks)
  end.


% Try and pickup both forks adjacent to a philosopher
% if the fork is in use then wait a bit and try again
% If we get a fork then print out to console
% Once we get both forks report back to philosopher
% so they can eat
tryPickUp(Name,F1,F2,P) ->

  F1 ! {pickup, self()},

  receive
    pickup -> io:format("~s got right fork ~n", [Name]);
    {inUse, FIN1}  -> timer:sleep(round(rand:uniform()*1000)),
              tryPickUp(Name,FIN1,F2,P)
  end,

  F2 ! {pickup, self()},

  receive
    pickup -> io:format("~s got left fork ~n", [Name]);
    {inUse, FIN2}  -> timer:sleep(round(rand:uniform()*1000)),
              tryPickUp(Name,F1,FIN2,P)
  end,

  P ! gotBothForks.
