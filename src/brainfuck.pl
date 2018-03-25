% Parses a string to a set of instructions.
% String: Input string.
% Result: Resulting instruction set.
parse(String, Result) :-
	string(String),
	string_codes(String, Characters),
	parse_instructions(Characters, Instructions),
	optimize_instructions(Instructions, OptimizedInstructions),
	optimize_jumps(OptimizedInstructions, Result).

% Ascii codes:
% . 46
% , 44
% + 43
% - 45
% > 62
% < 60
% [ 91
% ] 93

% Creates the instructions list.
parse_instructions([], []).
parse_instructions([46|Tail], [print|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([44|Tail], [take|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([43|Tail], [add(1)|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([45|Tail], [sub(1)|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([62|Tail], [next(1)|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([60|Tail], [prev(1)|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([91|Tail], [open|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([93|Tail], [close|Result]) :-
	parse_instructions(Tail, Result), !.
parse_instructions([_|Tail], Result) :-
	parse_instructions(Tail, Result), !.

% Optimizes + - > <
optimize_instructions([], []).
optimize_instructions([add(X)|[add(Y)|Tail]], Result) :-
	Z is X + Y,
	optimize_instructions([add(Z)|Tail], Result), !.
optimize_instructions([sub(X)|[sub(Y)|Tail]], Result) :-
	Z is X + Y,
	optimize_instructions([sub(Z)|Tail], Result), !.
optimize_instructions([next(X)|[next(Y)|Tail]], Result) :-
	Z is X + Y,
	optimize_instructions([next(Z)|Tail], Result), !.
optimize_instructions([prev(X)|[prev(Y)|Tail]], Result) :-
	Z is X + Y,
	optimize_instructions([prev(Z)|Tail], Result), !.
optimize_instructions([Head|Tail], [Head|Result]) :-
	optimize_instructions(Tail, Result), !.

% Optimizes [ ]
optimize_jumps(In, Out) :-
	optimize_jumps(In, 0, [], Out).
optimize_jumps([], _, _, []).
optimize_jumps([open|Tail], Index, Jumps, [open(TargetIndex)|Result]) :-
	NewIndex is Index + 1,
	find_forward_match(NewIndex, Tail, 0, TargetIndex),
	optimize_jumps(Tail, NewIndex, [jump(Index, TargetIndex)|Jumps], Result), !.
optimize_jumps([close|Tail], Index, Jumps, [close(TargetIndex)|Result]) :-
	NewIndex is Index + 1,
	find_backwards_match(Index, Jumps, TargetIndex),
	optimize_jumps(Tail, NewIndex, Jumps, Result), !.
optimize_jumps([Head|Tail], Index, Jumps, [Head|Result]) :-
	NewIndex is Index + 1,
	optimize_jumps(Tail, NewIndex, Jumps, Result), !.

% Finds the forward matching bracket.
find_forward_match(Index, [close|_], 0, Index).
find_forward_match(Index, [open|Tail], Counter, TargetIndex) :-
	NewIndex is Index + 1,
	NewCounter is Counter + 1,
	find_forward_match(NewIndex, Tail, NewCounter, TargetIndex), !.
find_forward_match(Index, [close|Tail], Counter, TargetIndex) :-
	Counter > 0,
	NewIndex is Index + 1,
	NewCounter is Counter - 1,
	find_forward_match(NewIndex, Tail, NewCounter, TargetIndex), !.
find_forward_match(Index, [_|Tail], Counter, TargetIndex) :-
	NewIndex is Index + 1,
	find_forward_match(NewIndex, Tail, Counter, TargetIndex), !.

% Finds the backward matching bracket.
find_backwards_match(Index, [jump(TargetIndex, Index)|_], TargetIndex).
find_backwards_match(Index, [_|Tail], TargetIndex) :-
	find_backwards_match(Index, Tail, TargetIndex).
	
