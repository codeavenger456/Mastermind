classdef mastermind < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        Title             matlab.ui.control.Label
        ButtonRestart     matlab.ui.control.Button
        UITablePlayer     matlab.ui.control.Table
        Rule              matlab.ui.control.Label
        ButtonSubmit      matlab.ui.control.Button
        Label_2           matlab.ui.control.Label
        EditFieldPlayer   matlab.ui.control.NumericEditField
        ButtonTerminate   matlab.ui.control.Button
        SwitchOption      matlab.ui.control.Switch
        LabelA            matlab.ui.control.Label
        LabelB            matlab.ui.control.Label
        EditFieldAI       matlab.ui.control.EditField
        UITableAI         matlab.ui.control.Table
        SpinnerA          matlab.ui.control.Spinner
        SpinnerB          matlab.ui.control.Spinner
        ButtonLanguage    matlab.ui.control.StateButton
        ImageInformation  matlab.ui.control.Image
    end

    methods (Static)
        function permutation = generate(limit)
            % generate a sercet number for player component
            if (limit <= 10) && (limit > 0)
                combination = '';
                array = randperm(10, limit) - 1; % randperm guarantees no repetitions
                for i = 1:limit
                    combination = strcat(combination, int2str(array(i)));
                end
                permutation = combination;
            else
                errordlg('logical error in MAX', 'WARNING');
            end
        end
        
        function possible = solutions(limit)
            % number of for loops = limit which is MAX (number of digits of the game)
            % generate a set of possible solutions for AI component
            if (limit <= 10) && (limit > 0)
                % capacity = 10! / 6! deduct from possibilities
                % 10*9*8*7
                capacity = factorial(10) / factorial(6);
                possibilities = cell(1, capacity);
                DIGITS = ['0' '1' '2' '3' '4' '5' '6' '7' '8' '9'];
                index = 1;
                for i = 1:length(DIGITS)
                    for j = 1:length(DIGITS)
                        for k = 1:length(DIGITS)
                            for l = 1:length(DIGITS)
                                possibility = strcat(DIGITS(i), DIGITS(j), DIGITS(k), DIGITS(l));
                                if limit == length(unique(possibility))
                                    possibilities{index} = possibility;
                                    index = index + 1;
                                end
                            end
                        end
                    end
                end
                possible = possibilities;
            else
                % limit cannot exceed 10 since the digits cannot repeat
                errordlg('logical error in MAX', 'WARNING');
            end
        end
        
    end
    
    properties (Constant)
        MAX = 4; % assume 4 digits only
        POSSIBILITIES = app1.solutions(app1.MAX); % all possible solutions
    end
    properties(Access=private)
        answerPlayer = app1.generate(app1.MAX); % secret number for player component
        shortestPlayer = intmax; % smallest number of tries 
        possibilitiesAI = app1.POSSIBILITIES(1:length(app1.POSSIBILITIES)); % all possible solutions
        FeedbacksAI = []; % set of user's hints 
        guessedAI = {}; % set of all guessed combinations
        guessedInitialAI = boolean(zeros(1,10)); % to determine which digits haven't been guessed (only useful in first 2 guesses)
        mustDigitsAI = ''; % set of digits that our last_guessed must have
        possibleDigitsAI = '0123456789'; % set of digits that our last_guessed might have
    end
    
    methods (Access = private)
        function guessingAI(app, target)
            % remove the target from the set of possible solutions
            % since the target is been guessed
            app.EditFieldAI.Value = target;
            app.guessedAI{length(app.guessedAI) + 1} = target;
            index_guessed = find(strcmp(app.possibilitiesAI, target));
            app.possibilitiesAI([index_guessed length(app.possibilitiesAI)]) = app.possibilitiesAI([length(app.possibilitiesAI) index_guessed]);
            app.possibilitiesAI = app.possibilitiesAI(1:(length(app.possibilitiesAI) - 1));
            app.SpinnerA.Value = 0;
            app.SpinnerB.Value = 0;
        end
        
        function nonZeroFilter(app)
            % filter the set of possible solutions given number of A and B
            last_guessed = app.guessedAI{length(app.guessedAI)}; % last guessed combination
            filter = cell(1, length(app.possibilitiesAI));
            index = 1;
            % nchoosek generate a matrix
            % each row indicates all possible places of a or b
            a = nchoosek(1:1:app.MAX, app.SpinnerA.Value); 
            b = nchoosek(1:1:app.MAX, app.SpinnerB.Value);
            for i = 1:length(a)
                for j = 1:length(b)
                    if ~any(ismember(a(i), b(j)))
                        % if the row of a and row of b don't have common
                        % elements
                        for k = 1:length(app.possibilitiesAI)
                            % in order to be in the set of possible
                            % solutions, possibility should meet all requirements of
                            % A and B
                            pointerA = 1;
                            pointerB = 1;
                            requirementA = boolean(zeros(1, length(a(i, :))));
                            requirementB = boolean(zeros(1, length(b(j, :))));
                            while pointerA <= length(a(i, :)) && ~all(requirementA)
                                if app.possibilitiesAI{k}(a(i, pointerA)) == last_guessed(a(i, pointerA))
                                    % if possibility contains last_guessed digits
                                    % and they are at the same place
                                    requirementA(pointerA) = true;
                                end
                                pointerA = pointerA + 1;
                            end
                            if all(requirementA)
                                while pointerB <= length(b(j, :)) && ~all(requirementB)
                                    if app.possibilitiesAI{k}(b(j, pointerB)) ~= last_guessed(b(j, pointerB)) && contains(app.possibilitiesAI{k}, last_guessed(b(j, pointerB)))
                                        % if possibility contains last_guessed digits
                                        % and they are not at the same
                                        % place
                                        requirementB(pointerB) = true;
                                    end
                                    pointerB = pointerB + 1;
                                end
                                if all(requirementB)
                                    % meet requirement of a and b
                                    filter{index} = app.possibilitiesAI{k};
                                    index = index + 1;
                                end
                            end
                        end
                    end
                end
            end
            app.possibilitiesAI = filter(1:index - 1);
        end
        
        function zeroFilter(app, a, b)
            % if a is zero, a = true
            last_guessed = app.guessedAI{length(app.guessedAI)};
            filter = cell(1, length(app.possibilitiesAI));
            index = 1;
            if a && b
                for i = 1:length(app.possibilitiesAI)
                    if ~any(ismember(app.possibilitiesAI{i}, last_guessed))
                        % if possibility doesn't contain any digits of last_guessed
                        filter{index} = app.possibilitiesAI{i};
                        index = index + 1;
                    end
                end
                app.possibilitiesAI = filter(1:index - 1);
                for j = 1:app.MAX
                    % erase those digits from possible digits
                    app.possibleDigitsAI = erase(app.possibleDigitsAI, last_guessed(j));
                end
            else
                if a
                    %possible positions of b
                    permutation = nchoosek(1:1:app.MAX, app.SpinnerB.Value);
                    total = app.SpinnerB.Value;
                else
                    %possible positions of a
                    permutation = nchoosek(1:1:app.MAX, app.SpinnerA.Value);
                    total = app.SpinnerA.Value;
                end
                for i = 1:length(app.possibilitiesAI)
                    % occurrence is the number of common digits between
                    % possibility and last_guessed
                    occurrence = sum(ismember(app.possibilitiesAI{i}, last_guessed));
                    if occurrence == total
                        row_pointer = 1;
                        requirementA = boolean(zeros(1, length(permutation(row_pointer, :))));
                        requirementB = boolean(zeros(1, length(permutation(row_pointer, :))));
                        while row_pointer <= length(permutation) && ~all(requirementA) && ~all(requirementB)
                            % in order to be in the set of possible
                            % solutions, possibility needs to meet one of
                            % the requirement
                            for j = 1:length(permutation(row_pointer, :))
                                if a
                                    if contains(app.possibilitiesAI{i}, last_guessed(permutation(row_pointer, j))) && app.possibilitiesAI{i}(permutation(row_pointer, j)) ~= last_guessed(permutation(row_pointer, j))
                                        % if possibility contains digits of
                                        % last_guessed and they are not at
                                        % the same place
                                        requirementB(j) = true;
                                    else
                                        requirementB(j) = false;
                                    end
                                else
                                    if app.possibilitiesAI{i}(permutation(row_pointer, j)) == last_guessed(permutation(row_pointer, j))
                                        % if possibility contains last_guessed digits
                                        % and they are at the same place
                                        requirementA(j) = true;
                                    else 
                                        requirementA(j) = false;
                                    end
                                end
                            end
                            row_pointer = row_pointer + 1;
                        end
                        if all(requirementA) || all(requirementB)
                            % meet one of the requirement
                            filter{index} = app.possibilitiesAI{i};
                            index = index + 1;
                        end
                    end
                end
                app.possibilitiesAI = filter(1:index - 1);
            end
        end
        
        function target = randomGuessed(app)
            % guess a combination in possibilities
            r = randperm(length(app.possibilitiesAI));
            target = app.possibilitiesAI{r};
        end
        
        function mustDigitsFilter(app)
            % whenever mustDigits changed, we update set of solutions
            garbage = '';
            for i = 1:length(app.UITableAI)
                % go through the table
                if sum(ismember(app.guessedAI{i}, app.mustDigitsAI)) == length(app.mustDigitsAI) && sum(app.FeedbacksAI(i, :)) == length(app.mustDigitsAI)
                    % if the guessed combination contains all mustDigits
                    % and sum of hint = length of mustDigits
                    % then rest of digits in guessed combination are
                    % garbage
                    for j = 1:length(app.guessedAI{i})
                        if ~contains(app.mustDigitsAI, app.guessedAI{i}(j))
                            garbage = strcat(garbage, app.guessedAI{i}(j));
                        end
                    end
                elseif sum(app.FeedbacksAI(i, :)) + length(app.mustDigitsAI) == app.MAX && ~any(ismember(app.guessedAI{i}, app.mustDigitsAI))
                    % if sum of hint add length of mustdigits = 4
                    % and the guessed combination doesn't contain any
                    % mustDigits then the repeated digits between the guessed
                    % combination and possibleDigits is possibleDigits
                    % other non repeated digits are garbage
                    shorter_possibilities = '';
                    for j = 1:length(app.possibleDigitsAI)
                        if contains(app.guessedAI{i}, app.possibleDigitsAI(j))
                            shorter_possibilities = strcat(shorter_possibilities, app.possibleDigitsAI(j));
                        else
                            garbage = strcat(garbage, app.possibleDigitsAI(j));
                        end
                    end
                    app.possibleDigitsAI = shorter_possibilities;
                end
            end 
            garbage = unique(garbage);
            filter = cell(1, length(app.possibilitiesAI));
            index = 1;
            for i = 1:length(app.possibilitiesAI)
                % for every possibility
                if sum(ismember(app.possibilitiesAI{i}, app.mustDigitsAI)) == length(app.mustDigitsAI) && ~any(ismember(app.possibilitiesAI{i}, garbage))
                    % if possibility contains all digits of mustDigits
                    filter{index} = app.possibilitiesAI{i};
                    index = index + 1;
                end
            end
            app.possibilitiesAI = filter(1: index - 1);
            for j = 1:length(app.mustDigitsAI)
                % update possibleDigits
                app.possibleDigitsAI = erase(app.possibleDigitsAI, app.mustDigitsAI(j));
            end
        end
        
        function possibleDigitsFilter(app, garbage)
            must = '';
            for i = 1:length(app.UITableAI)
                if sum(ismember(app.guessedAI{i}, garbage)) == length(garbage) 
                    if sum(app.FeedbacksAI(i, :)) + length(garbage) == app.MAX
                    % if the guessed combination contains all digits of
                    % garbage then rest of the digits in guessed
                    % combination are in must
                        for j = 1:length(app.guessedAI{i})
                            if ~contains(garbage, app.guessedAI{i}(j))
                                must = strcat(must, app.guessedAI{i}(j));
                            end
                        end
                    end
                end
            end
            filter = cell(1, length(app.possibilitiesAI));
            index = 1;
            must = unique(must);
            if sum(ismember(app.mustDigitsAI, must)) ~= length(must)
                % must have digits that app.mustDigitsAI don't
                for i = 1:length(app.possibilitiesAI)
                    if sum(ismember(app.possibilitiesAI{i}, must)) == length(must) && ~any(ismember(app.possibilitiesAI{i}, garbage))
                        filter{index} = app.possibilitiesAI{i};
                        index = index + 1;
                    end
                end
                for j = 1:length(must)
                    if ~contains(app.mustDigitsAI, must(j))
                        app.mustDigitsAI = strcat(app.mustDigitsAI, must(j));
                    end
                end
            else
                for i = 1:length(app.possibilitiesAI)
                    if ~any(ismember(app.possibilitiesAI{i}, garbage))
                        filter{index} = app.possibilitiesAI{i};
                        index = index + 1;
                    end
                end
            end
            app.possibilitiesAI = filter(1:index - 1);
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.guessingAI(app.randomGuessed());
            switch app.SwitchOption.Value
                case 'Player'
                    app.Label_2.Visible = 'on';
                    app.EditFieldPlayer.Visible = 'on';
                    app.SpinnerA.Visible = 'off';
                    app.SpinnerB.Visible = 'off';
                    app.LabelA.Visible = 'off';
                    app.LabelB.Visible = 'off';
                    app.EditFieldAI.Visible = 'off';
                    app.UITablePlayer.Visible = 'on';
                    app.UITableAI.Visible = 'off';
                case 'AI'
                    app.EditFieldPlayer.Visible = 'off';
                    app.Label_2.Visible = 'off';
                    app.SpinnerA.Visible = 'on';
                    app.SpinnerB.Visible = 'on';
                    app.LabelA.Visible = 'on';
                    app.LabelB.Visible = 'on';
                    app.EditFieldAI.Visible = 'on';
                    app.EditFieldAI.Editable = 'off';
                    app.UITablePlayer.Visible = 'off';
                    app.UITableAI.Visible = 'on';
            end
        end

        % Button pushed function: ButtonRestart
        function ButtonRestartPushed(app, event)
            switch app.SwitchOption.Value
                case 'Player'
                    app.answerPlayer = app1.generate(app.MAX);
                    app.UITablePlayer.Data = [];
                    app.EditFieldPlayer.Value = 0;
                case 'AI'
                    app.UITableAI.Data = [];
                    app.possibilitiesAI = app.POSSIBILITIES(1:length(app.POSSIBILITIES));
                    app.FeedbacksAI = [];
                    app.guessedAI = {};
                    app.guessingAI(app.randomGuessed());
                    app.possibleDigitsAI = '0123456789';
                    app.mustDigitsAI = '';
                    app.guessedInitialAI = boolean(zeros(1,10));
            end
        end

        % Button pushed function: ButtonSubmit
        function ButtonSubmitPushed(app, event)
            switch app.SwitchOption.Value
                case 'Player'
                    input = app.EditFieldPlayer.Value;
                    digits = num2str(input, '%04.f');
                    if (input >= 0) && (input <= 9999)
                        a = 0; 
                        b = 0;
                        for i = 1:length(digits)
                            if contains(app.answerPlayer, digits(i))
                                if app.answerPlayer(i) == digits(i)
                                    a = a + 1;
                                else 
                                    b = b + 1;
                                end
                            end
                        end
                        state = strcat(int2str(a), 'A', int2str(b), 'B');
                        newData = {digits state};
                        app.UITablePlayer.Data = [app.UITablePlayer.Data; newData];
                        if a == app.MAX && length(app.UITablePlayer.Data) < app.shortestPlayer
                            if app.ButtonLanguage.Value
                                if length(app.UITablePlayer.Data) == 1
                                    message = strcat('Congratulations, you only use', int2str(length(app.UITablePlayer.Data)), 'guess');
                                else
                                    message = strcat('Congratulations, you only use', int2str(length(app.UITablePlayer.Data)), 'guesses');
                                end
                                record = msgbox(message, 'RECORD!');
                            else
                                message = strcat('ÿÿÿÿ', int2str(length(app.UITablePlayer.Data)), 'ÿÿÿÿÿ');
                                record = msgbox(message, 'ÿÿÿ!');
                            end
                            set(record, 'position', [230 209 160 67]);
                            app.shortestPlayer = length(app.UITablePlayer.Data);
                            app.ButtonRestartPushed;
                        elseif a == app.MAX
                            if app.ButtonLanguage.Value
                                success = msgbox('Correct!');
                            else
                                success = msgbox('ÿÿÿ');
                            end
                            set(success, 'position', [230 209 160 67]);
                            app.ButtonRestartPushed;
                        end
                    else
                        if app.ButtonLanguage.Value
                            errordlg('4 Non-repeating digits', 'WARNING');
                        else
                            errordlg('4ÿÿÿÿÿÿ', 'ÿÿ');
                        end
                    end
                case 'AI'
                    if app.SpinnerA.Value + app.SpinnerB.Value > app.MAX
                        % cannot give hints exceeding the limit
                        if app.ButtonLanguage.Value
                           errordlg('Sum of hint cannot exceed 4', 'WARNING');
                        else
                            errordlg('ÿÿÿÿ', 'ÿÿ');
                        end
                    else
                        if length(app.possibilitiesAI) ~= 1
                            % possibilities must be more than 1
                            % since we need to filter it and guess a
                            % combination
                            app.FeedbacksAI = [app.FeedbacksAI; app.SpinnerA.Value app.SpinnerB.Value];
                            state = strcat(int2str(app.SpinnerA.Value), 'A', int2str(app.SpinnerB.Value), 'B');
                            last_guessed = app.guessedAI{length(app.guessedAI)};
                            app.UITableAI.Data = [app.UITableAI.Data; {last_guessed state}];
                            if app.SpinnerA.Value == 4
                                app.possibilitiesAI = {app.guessedAI};
                                if app.ButtonLanguage.Value
                                    success = msgbox('Success!', 'GOTCHU');
                                else
                                    success = msgbox('ÿÿ!', 'ÿÿÿ');
                                end
                                set(success, 'position', [230 209 160 67]);
                                app.ButtonRestartPushed();
                            else
                                if app.SpinnerA.Value + app.SpinnerB.Value == app.MAX
                                    % sum of hint = max
                                    if length(app.mustDigitsAI) ~= app.MAX
                                        % filter possibilties so that every
                                        % element contains mustDigits
                                        filter = cell(1, length(app.possibilitiesAI));
                                        index = 1;
                                        for i = 1:length(app.possibilitiesAI)
                                            if all(ismember(app.possibilitiesAI{i}, last_guessed))
                                                filter{index} = app.possibilitiesAI{i};
                                                index = index + 1;
                                            end
                                        end
                                        app.possibilitiesAI = filter(1:index - 1);
                                        app.mustDigitsAI = last_guessed;
                                        app.possibleDigitsAI = '';
                                    end
                                    filter = cell(1, length(app.possibilitiesAI));
                                    index = 1;
                                    requirementC = false; % if it has been changed or not
                                    % this for loop filter the positions of
                                    % possibilities
                                    for i = 1:length(app.possibilitiesAI)
                                        % for every element of
                                        % possibilities
                                        requirementA = true;
                                        requirementB = true;
                                        pointer_table = 1;
                                        while pointer_table <= length(app.UITableAI)
                                            % for each guessed combination
                                            if app.FeedbacksAI(pointer_table, 1) % if A == 0
                                                for j = 1:app.FeedbacksAI(pointer_table, 1)
                                                    pointer_digits = 1;
                                                    while pointer_digits <= app.MAX && requirementA
                                                        % each digit must
                                                        % fullfil
                                                        % requirement
                                                        if contains(app.mustDigitsAI,app.guessedAI{pointer_table}(pointer_digits))
                                                            if app.possibilitiesAI{i}(pointer_digits) ~= app.guessedAI{pointer_table}(pointer_digits)
                                                                % the
                                                                % digit
                                                                % doesn't
                                                                % fullfil
                                                                % requirement
                                                                % of A
                                                                requirementA = false;
                                                            end
                                                        end
                                                        pointer_digits = pointer_digits + 1;
                                                    end
                                                end
                                            end
                                            if app.FeedbacksAI(pointer_table, 2) % if B == 0
                                                for j = 1:app.FeedbacksAI(pointer_table, 2)
                                                    pointer_digits = 1;
                                                    while pointer_digits <= app.MAX && requirementB
                                                        if contains(app.mustDigitsAI, app.guessedAI{pointer_table}(pointer_digits))
                                                            if app.possibilitiesAI{i}(pointer_digits) == app.guessedAI{pointer_table}(pointer_digits)
                                                                requirementB = false;
                                                            end
                                                        end
                                                        pointer_digits = pointer_digits + 1;
                                                    end
                                                end
                                            end
                                            if requirementA && requirementB
                                                % both requirements meet
                                                filter{index} = app.possibilitiesAI{i};
                                                index = index + 1; 
                                                requirementC = true;
                                            end
                                            pointer_table = pointer_table + 1;
                                        end
                                    end
                                    if requirementC
                                        % if possibilities changed
                                        app.possibilitiesAI = filter(1:index - 1);
                                    end
                                    app.guessingAI(app.randomGuessed);
                                    return
                                else
                                    % case where sum of hint is not 4
                                    filter = cell(1, length(app.possibilitiesAI));
                                    index = 1;
                                    for i = 1:length(app.possibilitiesAI)
                                        if ~all(ismember(app.possibilitiesAI{i}, last_guessed))
                                            % possibility that contains the
                                            % 4 digits of last guessed will
                                            % be removed
                                            filter{index} = app.possibilitiesAI{i};
                                            index = index + 1;
                                        end
                                    end
                                    app.possibilitiesAI = filter(1:index - 1);
                                    if app.SpinnerA.Value == 0
                                        if app.SpinnerB.Value == 0
                                            app.zeroFilter(true, true);
                                        else
                                            app.zeroFilter(true, false);
                                        end
                                    else
                                        if app.SpinnerB.Value == 0
                                            app.zeroFilter(false, true);
                                        else
                                            app.nonZeroFilter();
                                        end
                                    end
                                    if length(app.guessedAI) <= 2
                                        for i = 1:length(last_guessed)
                                            % determine which digits have
                                            % been guessed
                                            app.guessedInitialAI(str2double(last_guessed(i)) + 1) = true;
                                        end
                                        if length(app.guessedAI) == 1
                                            % guessing digits that haven't
                                            % been guessed
                                            random_places = randperm(10);
                                            target = '';
                                            while true
                                                for i = 1:length(random_places)
                                                    if ~app.guessedInitialAI(random_places(i))
                                                        target = strcat(target, int2str(random_places(i) - 1));
                                                        if length(target) == 4
                                                            app.guessingAI(target);
                                                            return
                                                        end
                                                    end
                                                end
                                            end
                                        else
                                            remain = '';
                                            garbage = '';
                                            for i = 1:length(app.guessedInitialAI)
                                                if ~app.guessedInitialAI(i)
                                                    if sum(app.FeedbacksAI(1, :)) + sum(app.FeedbacksAI(2, :)) == 2
                                                        % if the sum of
                                                        % previous 2 hints
                                                        % equal to 2 then
                                                        % the digits that
                                                        % haven't been
                                                        % guessed is in
                                                        % mustDigits
                                                        app.mustDigitsAI = strcat(app.mustDigitsAI, int2str(i - 1));
                                                    elseif sum(app.FeedbacksAI(1, :)) + sum(app.FeedbacksAI(2, :)) == 3
                                                        % we need to guess
                                                        % at least one
                                                        % digit that
                                                        % haven't been
                                                        % guessed
                                                        remain = strcat(remain, int2str(i - 1));
                                                    else
                                                        % the digits that
                                                        % haven't been
                                                        % guessed are
                                                        % garbage
                                                        app.possibleDigitsAI = erase(app.possibleDigitsAI, int2str(i - 1));
                                                        garbage = strcat(garbage, int2str(i - 1));
                                                    end
                                                end
                                            end
                                            if app.mustDigitsAI
                                                app.mustDigitsFilter();
                                            end
                                            if garbage
                                                app.possibleDigitsFilter(garbage);
                                            end
                                            if remain
                                                while true
                                                    target = app.randomGuessed();
                                                    if any(ismember(target, remain))
                                                        app.guessingAI(target);
                                                        return
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    garbage = '';
                                    if app.SpinnerA.Value + app.SpinnerB.Value == 3
                                        % case where sum of last guessed
                                        % hint gives 3
                                        for i = 1:length(app.UITableAI) - 1
                                            if sum(app.FeedbacksAI(i, :)) == 3 && sum(ismember(app.guessedAI{i}, last_guessed)) == 3
                                                % if sum of previous
                                                % hint is 3 and the
                                                % previous guessed
                                                % combination contains 3
                                                % same digits then those
                                                % digits are mustDigits,
                                                % the rest are garbage
                                                for j = 1:length(app.guessedAI{i})
                                                    if ~contains(last_guessed, app.guessedAI{i}(j))
                                                        app.possibleDigitsAI = erase(app.possibleDigitsAI, app.guessedAI{i}(j));
                                                        garbage = strcat(garbage, last_guessed(j));
                                                    else
                                                        app.mustDigitsAI = strcat(app.mustDigitsAI, app.guessedAI{i}(j));
                                                    end
                                                    if ~contains(app.guessedAI{i}, last_guessed(j))
                                                        app.possibleDigitsAI = erase(app.possibleDigitsAI, last_guessed(j));
                                                        garbage = strcat(garbage, last_guessed(j));
                                                    end
                                                end
                                                app.mustDigitsAI = unique(app.mustDigitsAI);
                                                app.mustDigitsFilter();
                                            elseif sum(app.FeedbacksAI(i, :)) == 1 && ~any(ismember(app.guessedAI{i}, last_guessed))
                                                % if the sum of previous
                                                % hint is 1 and the
                                                % previous guess doesn't
                                                % contain any mustDigits
                                                % then the repeated digits
                                                % between possibleDigits
                                                % and previous guessed
                                                % combination is
                                                % possibleDigits
                                                shorter_possibilities = '';
                                                for j = 1:length(app.possibleDigitsAI)
                                                    if contains(app.guessedAI{i}, app.possibleDigitsAI(j))
                                                        shorter_possibilities = strcat(shorter_possibilities, app.possibleDigitsAI(j));
                                                    else
                                                        garbage = strcat(garbage, app.possibleDigitsAI(j));
                                                    end
                                                end
                                                app.possibleDigitsAI = shorter_possibilities;
                                            end
                                        end
                                        if garbage
                                            garbage = unique(garbage);
                                            app.possibleDigitsFilter(garbage);
                                        end
                                        app.guessingAI(app.randomGuessed);
                                        return
                                    else
                                        app.guessingAI(app.randomGuessed);
                                        return
                                    end
                                end
                            end
                        else
                           if app.ButtonLanguage.Value
                              errordlg('Cannot change combination during the game', 'WARNING');
                           else
                               errordlg('ÿÿÿÿÿÿÿ', 'ÿÿ');
                           end
                           app.ButtonRestartPushed();
                       end
                   end
            end
        end

        % Button pushed function: ButtonTerminate
        function ButtonTerminatePushed(app, event)
            closereq;
        end

        % Value changed function: SwitchOption
        function SwitchOptionValueChanged(app, event)
            switch app.SwitchOption.Value
                case 'Player'
                    app.EditFieldPlayer.Visible = 'on';
                    app.Label_2.Visible = 'on';
                    app.SpinnerA.Visible = 'off';
                    app.SpinnerB.Visible = 'off';
                    app.LabelA.Visible = 'off';
                    app.LabelB.Visible = 'off';
                    app.EditFieldAI.Visible = 'off';
                    app.UITablePlayer.Visible = 'on';
                    app.UITableAI.Visible = 'off';
                case 'AI'
                    app.EditFieldPlayer.Visible = 'off';
                    app.Label_2.Visible = 'off';
                    app.SpinnerA.Visible = 'on';
                    app.SpinnerB.Visible = 'on';
                    app.LabelA.Visible = 'on';
                    app.LabelB.Visible = 'on';
                    app.EditFieldAI.Visible = 'on';
                    app.UITablePlayer.Visible = 'off';
                    app.UITableAI.Visible = 'on';
            end
        end

        % Value changed function: ButtonLanguage
        function ButtonLanguageValueChanged(app, event)
            if app.ButtonLanguage.Value
                app.ButtonLanguage.Text = 'ÿ';
                app.Title.Text = 'Mastermind';
                app.Rule.Text = '4 Non-repeating Digits';
                app.ButtonSubmit.Text = 'Submit';
                app.ButtonTerminate.Text = 'Quit';
                app.ButtonRestart.Text = 'Restart';
                app.UITableAI.ColumnName = {'Combination'; 'State'};
            else
                app.ButtonLanguage.Text = 'English';
                app.Title.Text = '1A2B';
                app.Rule.Text = '4ÿÿÿÿÿÿÿ';
                app.ButtonSubmit.Text = 'ÿÿ';
                app.ButtonTerminate.Text = 'ÿÿ';
                app.ButtonRestart.Text = 'ÿÿÿÿ';
                app.UITableAI.ColumnName = {'ÿÿ'; 'ÿ Aÿ B'};
            end
        end

        % Image clicked function: ImageInformation
        function ImageInformationClicked(app, event)
            if app.ButtonLanguage.Value
                message = sprintf('Number of A indicates number of correct digits at the right place\nNumber of B indicates number of correct digits at the wrong place\nThe goal is to reach 4A0B\nIf the switch is at Player side then guess the secret combination\nOtherwise AI will guess your number');
                information = msgbox(message, 'Information');
                set(information, 'position', [173 176 341 129]);
            else
                message = sprintf('    AÿÿÿÿÿÿÿÿÿBÿÿÿÿÿÿÿÿ\n    ÿÿÿÿÿÿ4A0B\n    ÿÿÿÿÿPlayerÿÿÿÿÿÿÿÿÿ\n    ÿÿÿÿÿÿÿÿÿÿÿ\n');
                information = msgbox(message, 'Information');
                set(information, 'position', [230 181 229 129]);
            end
            larger = findall(information, 'Type', 'Text');
            larger.FontSize = 11;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create Title
            app.Title = uilabel(app.UIFigure);
            app.Title.FontSize = 20;
            app.Title.Position = [124 355 132 26];
            app.Title.Text = '1A2B';

            % Create ButtonRestart
            app.ButtonRestart = uibutton(app.UIFigure, 'push');
            app.ButtonRestart.ButtonPushedFcn = createCallbackFcn(app, @ButtonRestartPushed, true);
            app.ButtonRestart.Position = [36 119 95 33];
            app.ButtonRestart.Text = 'ÿÿÿÿ';

            % Create UITablePlayer
            app.UITablePlayer = uitable(app.UIFigure);
            app.UITablePlayer.ColumnName = {'ÿÿ'; 'ÿ Aÿ B'};
            app.UITablePlayer.RowName = {};
            app.UITablePlayer.FontSize = 15;
            app.UITablePlayer.Position = [356 110 280 166];

            % Create Rule
            app.Rule = uilabel(app.UIFigure);
            app.Rule.FontSize = 20;
            app.Rule.Position = [374 354 237 26];
            app.Rule.Text = '4ÿÿÿÿÿÿÿ';

            % Create ButtonSubmit
            app.ButtonSubmit = uibutton(app.UIFigure, 'push');
            app.ButtonSubmit.ButtonPushedFcn = createCallbackFcn(app, @ButtonSubmitPushed, true);
            app.ButtonSubmit.Position = [142 119 80 33];
            app.ButtonSubmit.Text = 'ÿÿ';

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.FontSize = 15;
            app.Label_2.Position = [74 230 35 22];
            app.Label_2.Text = 'ÿÿ';

            % Create EditFieldPlayer
            app.EditFieldPlayer = uieditfield(app.UIFigure, 'numeric');
            app.EditFieldPlayer.FontSize = 15;
            app.EditFieldPlayer.Position = [113 230 100 22];

            % Create ButtonTerminate
            app.ButtonTerminate = uibutton(app.UIFigure, 'push');
            app.ButtonTerminate.ButtonPushedFcn = createCallbackFcn(app, @ButtonTerminatePushed, true);
            app.ButtonTerminate.Position = [245 119 85 33];
            app.ButtonTerminate.Text = 'ÿÿ';

            % Create SwitchOption
            app.SwitchOption = uiswitch(app.UIFigure, 'slider');
            app.SwitchOption.Items = {'Player', 'AI'};
            app.SwitchOption.ValueChangedFcn = createCallbackFcn(app, @SwitchOptionValueChanged, true);
            app.SwitchOption.FontSize = 20;
            app.SwitchOption.Position = [285 308 72 32];
            app.SwitchOption.Value = 'AI';

            % Create LabelA
            app.LabelA = uilabel(app.UIFigure);
            app.LabelA.FontSize = 20;
            app.LabelA.Position = [130 181 25 24];
            app.LabelA.Text = 'A';

            % Create LabelB
            app.LabelB = uilabel(app.UIFigure);
            app.LabelB.FontSize = 20;
            app.LabelB.Position = [206 181 25 24];
            app.LabelB.Text = 'B';

            % Create EditFieldAI
            app.EditFieldAI = uieditfield(app.UIFigure, 'text');
            app.EditFieldAI.HorizontalAlignment = 'right';
            app.EditFieldAI.FontSize = 15;
            app.EditFieldAI.Position = [113 229.666666030884 100 22.3333339691162];

            % Create UITableAI
            app.UITableAI = uitable(app.UIFigure);
            app.UITableAI.ColumnName = {'ÿÿ'; 'ÿ Aÿ B'};
            app.UITableAI.RowName = {};
            app.UITableAI.FontSize = 15;
            app.UITableAI.Position = [356 110 280 166];

            % Create SpinnerA
            app.SpinnerA = uispinner(app.UIFigure);
            app.SpinnerA.Limits = [0 4];
            app.SpinnerA.FontSize = 15;
            app.SpinnerA.Position = [85 182 40 22];

            % Create SpinnerB
            app.SpinnerB = uispinner(app.UIFigure);
            app.SpinnerB.Limits = [0 4];
            app.SpinnerB.FontSize = 15;
            app.SpinnerB.Position = [153 182 40 22];

            % Create ButtonLanguage
            app.ButtonLanguage = uibutton(app.UIFigure, 'state');
            app.ButtonLanguage.ValueChangedFcn = createCallbackFcn(app, @ButtonLanguageValueChanged, true);
            app.ButtonLanguage.Text = 'English';
            app.ButtonLanguage.FontSize = 15;
            app.ButtonLanguage.Position = [513 398 64 32];

            % Create ImageInformation
            app.ImageInformation = uiimage(app.UIFigure);
            app.ImageInformation.ImageClickedFcn = createCallbackFcn(app, @ImageInformationClicked, true);
            app.ImageInformation.Position = [581 398 30 32];
            app.ImageInformation.ImageSource = 'information_icon.png';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = mastermind

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end