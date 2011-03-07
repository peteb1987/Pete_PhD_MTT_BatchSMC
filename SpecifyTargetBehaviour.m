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
%     TargSpec(j).state(1) = unifrnd(-0.5*Par.Xmax, 0.5*Par.Xmax);
%     TargSpec(j).state(2) = unifrnd(-0.5*Par.Xmax, 0.5*Par.Xmax);
    rng = unifrnd(0.15*Par.Xmax, 0.25*Par.Xmax);
    bng = unifrnd(-pi, pi);
    TargSpec(j).state(1) = rng*cos(bng);
    TargSpec(j).state(2) = rng*sin(bng);
    TargSpec(j).state(3) = unifrnd(-Par.Vmax, Par.Vmax);
    TargSpec(j).state(4) = unifrnd(-Par.Vmax, Par.Vmax);
%     TargSpec(j).state(1) = unifrnd(0.35*Par.Xmax, 0.4*Par.Xmax);
%     TargSpec(j).state(2) = unifrnd(0.35*Par.Xmax, 0.4*Par.Xmax);
%     TargSpec(j).state(3) = unifrnd(-Par.Vmax, -0.5*Par.Vmax);
%     TargSpec(j).state(4) = unifrnd(0, 0.1*Par.Vmax);
    TargSpec(j).acc = zeros(num, 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Manually overwrite individual target values if desired              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % SIMPLE TEST, SINGLE TARGET
% 
% j = 1;
% TargSpec(j).birth = 1;
% TargSpec(j).state = Par.TargInitState{1};
% num = T - TargSpec(j).birth + 1;
% TargSpec(j).acc = zeros(num, 2);

% SIMPLE TEST, N TARGETS, CLUTTER, MISSED DETECTIONS
for j = 1:N
    TargSpec(j).birth = 2*j-1;
    num = T - TargSpec(j).birth + 1;
    TargSpec(j).acc = zeros(num, 2);
    Par.TargInitState{j} = TargSpec(j).state;
end
% TargSpec(1).death = 15;
% TargSpec(2).death = 23;
% TargSpec(3).death = 25;
% TargSpec(4).death = 27;

% % SIMPLE TEST, 5 TARGETS, 2 BORN, 2 DIE
% for j = 1:N
%     TargSpec(j).birth = 1;
%     num = T - TargSpec(j).birth + 1;
%     TargSpec(j).acc = zeros(num, 2);
%     Par.TargInitState{j} = TargSpec(j).state;
% end
% TargSpec(2).death = 11;
% TargSpec(3).death = 16;
% TargSpec(4).birth = 3;
% TargSpec(5).birth = 6;

% % Birth States
% TargSpec(1).state(1) = 220;
% TargSpec(1).state(2) = 100;
% TargSpec(1).state(3) = -2;
% TargSpec(1).state(4) = 0;
% TargSpec(2).state(1) = 180;
% TargSpec(2).state(2) = 100;
% TargSpec(2).state(3) = 2;
% TargSpec(2).state(4) = 0;
% TargSpec(3).state(1) = 200;
% TargSpec(3).state(2) = 120;
% TargSpec(3).state(3) = 0;
% TargSpec(3).state(4) = -2;
% TargSpec(4).state(1) = 200;
% TargSpec(4).state(2) = 80;
% TargSpec(4).state(3) = 0;
% TargSpec(4).state(4) = 2;
% TargSpec(5).state(1) = 180;
% TargSpec(5).state(2) = 80;
% TargSpec(5).state(3) = 2;
% TargSpec(5).state(4) = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% End of manual overwrites                                            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Par.FLAG_TargInit
    for j = 1:N
        TargSpec(j).birth = 1;
        num = T - TargSpec(j).birth + 1;
        TargSpec(j).acc = zeros(num, 2);
        Par.TargInitState{j} = TargSpec(j).state;
    end
end

end %SpecifyTargetBehaviour