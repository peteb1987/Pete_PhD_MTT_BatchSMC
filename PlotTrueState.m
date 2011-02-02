function f = PlotTrueState( State )
%PLOTTRUESTATE Plots the correct states

global Par;

% Make a figure of the right size
f = figure; hold on
xlim([-Par.Xmax Par.Xmax]), ylim([-Par.Xmax Par.Xmax])

% Loop through tracks
for j = 1:Par.NumTgts
    
    coords = zeros(State{j}.num, 2);
    
    % Compile a list of positions
    for k = 1:State{j}.num
        coords(k, :) = State{j}.state{k}(1:2)';
    end
    
    % Plot it
    plot(coords(:,1), coords(:,2), '-x', 'color', [rand rand 0]);
    
end

pause(0.2);

end

