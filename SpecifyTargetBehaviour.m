function [ TargSpec ] = SpecifyTargetBehaviour
%SPECIFYTARGETBEHAVIOUR Generates a set of parameters specifying targets
%present in a scene

global Par;

% Output:   %TargSpec: structure array specifying target existence and dynamics            
                        % .birth - birth time
                        % .death - death time
                        % .state - initial birth state
                        % .acc - array of deterministic accelerations to simulate manoeuvring targets.

% Number of targets
N = Par.NumTgts;

% Number of time steps
T = Par.T;

% Initialise cell array for targets
TargSpec = repmat(struct('birth', 0, 'death', 0, 'state', zeros(4, 1), 'acc', []), N, 1);

% Randomly generate target birth states and times
for j = 1:N
    TargSpec(j).birth = unidrnd(T);
    TargSpec(j).death = T + 1;
    num = TargSpec(j).death - TargSpec(j).birth;
    TargSpec(j).state = zeros(4, 1);
    TargSpec(j).state(1) = unifrnd(-0.5*Par.Xmax, 0.5*Par.Xmax);
    TargSpec(j).state(2) = unifrnd(-0.5*Par.Xmax, 0.5*Par.Xmax);
    TargSpec(j).state(3) = unifrnd(-Par.Vmax, Par.Vmax);
    TargSpec(j).state(4) = unifrnd(-Par.Vmax, Par.Vmax);
    TargSpec(j).acc = zeros(num, 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Manually overwrite individual target values if desired              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SIMPLE TEST

j = 1;
TargSpec(j).birth = 1;
TargSpec(j).state = [-20 20 1 0]';
num = T - TargSpec(j).birth + 1;
TargSpec(j).acc = zeros(num, 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% End of manual overwrites                                            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end %SpecifyTargetBehaviour