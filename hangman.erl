-module(hangman).
-export([play/0]).

-define(LIVES, 6).

play() ->
    Dict = create_dictionary(),
    game_loop(Dict).
    
game_loop(Dict) ->
    Game = game_setup(Dict),
    play(Game),

    PlayAgain = play_again(),
    case PlayAgain of
        yes -> game_loop(Dict);
        no  -> ok
    end.

play_again() ->
    PlayAgain = string:strip(io:get_line("Play again? (y/n) "), right, $\n),

    case PlayAgain of
        "y" -> yes;
        "n" -> no;
        _   -> 
            io:format("\n"),
            play_again()
    end.

game_setup(Dict) ->
    Word = get_word(Dict),
    HiddenWord = obfuscate_word(Word),
    Lives = ?LIVES,
    {Word, HiddenWord, Lives, []}.

%% DictionaryWord = dog
%% GuessedWord = d--
play(Game = {DictWord, GuessWord, Lives, PrevGuesses}) ->
    GameOver = check_game_over(Game),
    io:format("Current guess : ~s~n", [GuessWord]),
    io:format("Lives left : \t~w~n~n", [Lives]),
    case GameOver of
        win ->
            io:format("You win!\n");
        lose ->
            io:format("You lose!\n"),
            io:format("Word was : ~s\n", [DictWord]);
        _ ->
            Guess = get_guess(PrevGuesses),
            UpdatedGame = update_game(Game, Guess),
            play(UpdatedGame)
    end.

get_guess(PrevGuesses) ->
    Input = get_input(),
    Guess = parse_input(Input),
    
    %% if guess is empty or already tried, guess again
    case Guess of
        empty ->
            get_guess(PrevGuesses);
        _ ->
            AlreadyGuessed = lists:member(Guess, PrevGuesses),
            if
                AlreadyGuessed ->
                    get_guess(PrevGuesses);
                true ->
                    Guess
            end
    end.

%% remove newline from end of input
get_input() ->
    string:strip(io:get_line("Enter guess : \t"), right, $\n).

%% need to check if empty list before pattern matching
parse_input(Input) ->
    if
        length(Input) == 0 ->
            empty;
        true ->
            [ Guess | _ ] = Input,
            Guess
    end.

%% add the guessed letter to the guessed word
%% or lose a life
update_game({DictWord, GuessWord, Lives, PrevGuesses}, Guess) ->
    Correct = in_word(Guess, DictWord),
    case Correct of
        true ->
            {DictWord, replace(DictWord, GuessWord, Guess), Lives, [Guess | PrevGuesses]};
        false ->
            {DictWord, GuessWord, Lives-1, [Guess | PrevGuesses]}
    end.

check_game_over({DictWord, GuessWord, Lives, _}) ->
    WordGuessed = string:equal(DictWord, GuessWord),
    LivesUp = Lives == 0,
    if
       WordGuessed ->
           win;
       LivesUp ->
           lose;
       true ->
           other
    end.  

%% returns a list of strings
create_dictionary() ->
    {ok, File} = file:open("dictionary.txt", read),
    io:format("Loading dictionary...~n"),
    create_dictionary(File, []).

%% loop through file of words
create_dictionary(File, WordList) ->
    case io:get_line(File, "") of
        eof ->
            file:close(File),
            WordList;
        Word ->
            RemNewline = string:strip(Word, right, $\n), % get word without newline
            create_dictionary(File, [RemNewline | WordList])
    end.

get_word(Dict) ->
    random:seed(now()),
    lists:nth(random:uniform(length(Dict)), Dict).

%% replace word chars with dashes
%% dog -> ---
obfuscate_word(Word) ->
    lists:duplicate(length(Word), $-).

%% where the letter chosen matches in the original word
%% replace the dash in the obfuscated  word with that letter
replace(DictWord, GuessWord, GuessedLetter) ->
    Match = fun(DLetter, GLetter) ->
                case DLetter of % each letter of dictionary word
                    GuessedLetter -> % guessed letter matches DictWord letter
                        DLetter;
                    _ -> % otherwise GuessWord letter is left the same
                        GLetter 
                end
            end,
    lists:zipwith(Match, DictWord, GuessWord).

in_word(Letter, Word) ->
    lists:any(fun(X) -> X == Letter end, Word).
