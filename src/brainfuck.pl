% Parses a string to a set of instructions.
% String: Input string.
% Result: Resulting instruction set.
parse(String, Result) :-
	string(String),
	string_codes(String, Characters),
	parse_instructions(Characters, Instructions),
	optimize_instructions(Instructions, Result).

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