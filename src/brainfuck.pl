% Parses a string to a set of instructions.
% String: Input string.
% Result: Resulting instruction set.
parse(String, Result) :-
	string(String),
	string_codes(String, Characters),
	%reverse(Characters, ReversedCharacters),
	parse_instructions(Characters, [], Instructions),
	optimize_instructions(Instructions, [], Result).

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
parse_instructions([], Acc, Acc).
parse_instructions([46|Tail], Acc, Result) :-
	parse_instructions(Tail, [print|Acc], Result), !.
parse_instructions([44|Tail], Acc, Result) :-
	parse_instructions(Tail, [take|Acc], Result), !.
parse_instructions([43|Tail], Acc, Result) :-
	parse_instructions(Tail, [add(1)|Acc], Result), !.
parse_instructions([45|Tail], Acc, Result) :-
	parse_instructions(Tail, [sub(1)|Acc], Result), !.
parse_instructions([62|Tail], Acc, Result) :-
	parse_instructions(Tail, [next(1)|Acc], Result), !.
parse_instructions([60|Tail], Acc, Result) :-
	parse_instructions(Tail, [prev(1)|Acc], Result), !.
parse_instructions([91|Tail], Acc, Result) :-
	parse_instructions(Tail, [open|Acc], Result), !.
parse_instructions([93|Tail], Acc, Result) :-
	parse_instructions(Tail, [close|Acc], Result), !.
parse_instructions([_|Tail], Acc, Result) :-
	parse_instructions(Tail, Acc, Result), !.

% Optimizes + - > <
optimize_instructions([], Acc, Acc).
optimize_instructions([add(X)|[add(Y)|Tail]], Acc, Result) :-
	Z is X + Y,
	optimize_instructions([add(Z)|Tail], Acc, Result), !.
optimize_instructions([sub(X)|[sub(Y)|Tail]], Acc, Result) :-
	Z is X + Y,
	optimize_instructions([sub(Z)|Tail], Acc, Result), !.
optimize_instructions([next(X)|[next(Y)|Tail]], Acc, Result) :-
	Z is X + Y,
	optimize_instructions([next(Z)|Tail], Acc, Result), !.
optimize_instructions([prev(X)|[prev(Y)|Tail]], Acc, Result) :-
	Z is X + Y,
	optimize_instructions([prev(Z)|Tail], Acc, Result), !.
optimize_instructions([Head|Tail], Acc, Result) :-
	optimize_instructions(Tail, [Head|Acc], Result), !.