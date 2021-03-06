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
parse_instructions([43|Tail], [add_cell(1)|Result]) :-
    parse_instructions(Tail, Result), !.
parse_instructions([45|Tail], [add_cell(-1)|Result]) :-
    parse_instructions(Tail, Result), !.
parse_instructions([62|Tail], [add_ptr(1)|Result]) :-
    parse_instructions(Tail, Result), !.
parse_instructions([60|Tail], [add_ptr(-1)|Result]) :-
    parse_instructions(Tail, Result), !.
parse_instructions([91|Tail], [jump_forwards|Result]) :-
    parse_instructions(Tail, Result), !.
parse_instructions([93|Tail], [jump_backwards|Result]) :-
    parse_instructions(Tail, Result), !.
parse_instructions([_|Tail], Result) :-
    parse_instructions(Tail, Result), !.

% Optimizes + - > <
optimize_instructions([], []).
optimize_instructions([add_cell(X)|[add_cell(Y)|Tail]], Result) :-
    Z is X + Y,
    optimize_instructions([add_cell(Z)|Tail], Result), !.
optimize_instructions([add_ptr(X)|[add_ptr(Y)|Tail]], Result) :-
    Z is X + Y,
    optimize_instructions([add_ptr(Z)|Tail], Result), !.
optimize_instructions([Head|Tail], [Head|Result]) :-
    optimize_instructions(Tail, Result), !.

% Optimizes [ ]
optimize_jumps(In, Out) :-
    optimize_jumps(In, 0, [], Out).
optimize_jumps([], _, _, []).
optimize_jumps([jump_forwards|Tail], Index, Jumps, [jump_forwards(TargetIndex)|Result]) :-
    NewIndex is Index + 1,
    find_forward_match(NewIndex, Tail, 0, TargetIndex),
    optimize_jumps(Tail, NewIndex, [jump(Index, TargetIndex)|Jumps], Result), !.
optimize_jumps([jump_backwards|Tail], Index, Jumps, [jump_backwards(TargetIndex)|Result]) :-
    NewIndex is Index + 1,
    find_backwards_match(Index, Jumps, TargetIndex),
    optimize_jumps(Tail, NewIndex, Jumps, Result), !.
optimize_jumps([Head|Tail], Index, Jumps, [Head|Result]) :-
    NewIndex is Index + 1,
    optimize_jumps(Tail, NewIndex, Jumps, Result), !.

% Finds the forward matching bracket.
find_forward_match(Index, [jump_backwards|_], 0, Index).
find_forward_match(Index, [jump_forwards|Tail], Counter, TargetIndex) :-
    NewIndex is Index + 1,
    NewCounter is Counter + 1,
    find_forward_match(NewIndex, Tail, NewCounter, TargetIndex), !.
find_forward_match(Index, [jump_backwards|Tail], Counter, TargetIndex) :-
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
    
% Interpret brainfuck code.
% String: String to interpret.
% Instructions: Instruction list to interpret.
interpret(String) :-
    string(String),
    parse(String, Instructions),
    interpret(Instructions), !.
interpret(Instructions) :-
    is_list(Instructions),
    create_memory(Memory),
    interpret(Instructions, Instructions, Memory, 0), !.

interpret(_, [], _, _).
interpret(AllInstructions, [add_cell(X)|Tail], Memory, MP) :-
    mutate_memory(add, Memory, MP, X, NewMemory),
    interpret(AllInstructions, Tail, NewMemory, MP), !.
interpret(AllInstructions, [add_ptr(X)|Tail], Memory, MP) :-
    memory_size(Size),
    TempMP is MP + X,
    NewMP is TempMP mod Size,
    interpret(AllInstructions, Tail, Memory, NewMP), !.
interpret(AllInstructions, [jump_forwards(X)|_], Memory, MP) :-
    nth0(MP, Memory, Value),
    Value = 0,
    goto(AllInstructions, X, NewInstructions),
    interpret(AllInstructions, NewInstructions, Memory, MP), !.
interpret(AllInstructions, [jump_forwards(_)|Tail], Memory, MP) :-
    nth0(MP, Memory, Value),
    Value > 0,
    interpret(AllInstructions, Tail, Memory, MP), !.
interpret(AllInstructions, [jump_backwards(X)|_], Memory, MP) :-
    nth0(MP, Memory, Value),
    Value > 0,
    goto(AllInstructions, X, NewInstructions),
    interpret(AllInstructions, NewInstructions, Memory, MP), !.
interpret(AllInstructions, [jump_backwards(_)|Tail], Memory, MP) :-
    nth0(MP, Memory, Value),
    Value = 0,
    interpret(AllInstructions, Tail, Memory, MP), !.
interpret(AllInstructions, [print|Tail], Memory, MP) :-
    nth0(MP, Memory, Code),
    char_code(Char, Code),
    write(Char),
    interpret(AllInstructions, Tail, Memory, MP), !.
interpret(AllInstructions, [take|Tail], Memory, MP) :-
    get_char(Char),
    char_code(Char, Code),
    mutate_memory(set, Memory, MP, Code, NewMemory),
    interpret(AllInstructions, Tail, NewMemory, MP), !.

% Memory constants.
memory_size(30000).
cell_size(256).

% Creates empty memory.
create_memory(Memory) :-
    memory_size(Size),
    length(Memory, Size),
    maplist(=(0), Memory).

% Updates memory.
mutate_memory(add, [Head|Tail], 0, Value, [NewValue|Tail]) :-
    TempValue is Head + Value,
    cell_size(CellSize),
    Max is CellSize - 1,
    NewValue is TempValue mod Max.
mutate_memory(set, [_|Tail], 0, Value, [Value|Tail]).
mutate_memory(Type, [Head|Tail], Index, Value, [Head|Result]) :-
    Index > 0,
    NewIndex is Index - 1,
    mutate_memory(Type, Tail, NewIndex, Value, Result).

% Jump to index in memory.
goto(Instructions, 0, Instructions).
goto([_|Tail], Index, Result) :-
    Index > 0,
    NewIndex is Index - 1,
    goto(Tail, NewIndex, Result).
