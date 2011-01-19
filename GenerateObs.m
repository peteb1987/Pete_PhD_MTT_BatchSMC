function [ Observs ] = GenerateObs( TrueState )
%GENERATEOBS Generate a set of observations from a set of known tracks

global Par;

% Simple Observation Generator - Observe target with probability PDetect and
% Gaussian observation noise ObsNoiseVar. Poisson clutter.

% Make some local variables for convenience
T = Par.T;               % Number of frames

% Create a structure to store observations
Observs = repmat(struct('N', 0, 'r', []), T, 1);

% Loop over time
for t = 1:T
    
    % Draw number of clutter obs from a poisson dist
    num_clut = poissrnd(Par.ExpClutObs);
    
    % Count the number of targets present in this frame
    num_tgts = 0;
    for j = 1:Par.NumTgts
        if TrueState{j}.Present(t)
            num_tgts = num_tgts + 1;
        end
    end
    
    Observs(t).N = num_tgts+num_clut;
    
    % Initialise cell array for time instant with max required size
    Observs(t).r = zeros(Observs(t).N, 2);
    
    % Initialise observation counter
    i = 1;
    
    % Generate target observations
    for j = 1:Par.NumTgts
        if TrueState{j}.Present(t)
            state = TrueState{j}.GetState(t);
            
            if Par.FLAG_ObsMod == 0
                % Gaussian noise only
                Observs(t).r(i, :) = mvnrnd(state(1:2)', Par.ObsNoiseVar*ones(1,2));
                
            elseif Par.FLAG_ObsMod == 1
                % Bearing only plus gaussian noise
                [bng, ~] = Cart2Pol(state(1:2));
                Observs(t).r(i, 1) = bng + mvnrnd(0, Par.ObsNoiseVar);
                
            end
            
            i = i + 1;
        end
    end
    
    % Generate clutter observations
    for i = num_tgts+1:Observs(t).N
        
        if Par.FLAG_ObsMod == 0
            % Gaussian noise only
            Observs(t).r(i, 1) = unifrnd(-Par.Xmax, Par.Xmax);
            Observs(t).r(i, 2) = unifrnd(-Par.Xmax, Par.Xmax);
            
        elseif Par.FLAG_ObsMod == 1
            % Bearing only plus gaussian noise
            Observs(t).r(i, 1) = unifrnd(-pi, pi);
            
        end
    end
    
end %GenerateObs