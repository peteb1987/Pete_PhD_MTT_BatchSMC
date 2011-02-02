% Define constant parameters for target tracker execution

global Par;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Flags                                                               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.FLAG_ObsMod = 2;        % 0 = cartesian, 1 = bearing only, 2 = polar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scene parameters                                                    %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.T = 20;                             % Number of frames
Par.P = 1; P = Par.P;                   % Sampling period
Par.Xmax = 500;                         % Scene limit
Par.Vmax = 10;                          % Maximum velocity

Par.UnifPosDens = 1/(2*Par.Xmax)^2;     % Uniform density on position
Par.UnifVelDens = 1/(2*Par.Vmax)^2;     % Uniform density on velocity

if Par.FLAG_ObsMod == 0
    Par.ClutDens = Par.UnifPosDens;
elseif Par.FLAG_ObsMod == 2
    Par.ClutDens = (1/Par.Xmax)*(1/(2*pi));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scenario parameters                                                 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.NumTgts = 5;
Par.TargInitState = cell(Par.NumTgts,1);
Par.TargInitState{1} = [-150 150 2 0]';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Target dynamic model parameters                                     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.ProcNoiseVar = 1;                                                      % Gaussian process noise variance (random accelerations)
Par.A = [1 0 P 0; 0 1 0 P; 0 0 1 0; 0 0 0 1];                              % 2D transition matrix using near CVM model
Par.B = [P^2/2*eye(2); P*eye(2)];                                          % 2D input transition matrix (used in track generation when we impose a deterministic acceleration)
Par.Q = Par.ProcNoiseVar * ...
    [P^3/3 0 P^2/2 0; 0 P^3/3 0 P^2/2; P^2/2 0 P 0; 0 P^2/2 0 P];          % Gaussian motion covariance matrix (discretised continous random model)
%     [P^4/4 0 P^3/2 0; 0 P^4/4 0 P^3/2; P^3/2 0 P^2 0; 0 P^3/2 0 P^2];      % Gaussian motion covariance matrix (piecewise constant acceleration discrete random model)
Par.ExpBirth = 0.5;                                                        % Expected number of new targets in a frame (poisson deistributed)
Par.PDeath = 0.1;                                                          % Probability of a (given) target death in a frame

Par.Qchol = chol(Par.Q);                                                   % Cholesky decompostion of Par.Q

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Observation model parameters                                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.ExpClutObs = 20;                    % Number of clutter objects expected in scene
Par.PDetect = 0.9;                      % Probability of detecting a target in a given frame

if Par.FLAG_ObsMod == 0
    Par.ObsNoiseVar = 1;                % Observation noise variance
    Par.R = Par.ObsNoiseVar * eye(2);   % Observation covariance matrix
    Par.C = [1 0 0 0; 0 1 0 0];         % 2D Observation matrix
elseif Par.FLAG_ObsMod == 1
    Par.ObsNoiseVar = 1E-4;             % Observation noise variance
    Par.R = Par.ObsNoiseVar;
elseif Par.FLAG_ObsMod == 2
    Par.BearingNoiseVar = 1E-4;                                 % Bearing noise variance
    Par.RangeNoiseVar = 1;                                     % Range noise variance
    Par.R = [Par.BearingNoiseVar 0; 0 Par.RangeNoiseVar];      % Observation covariance matrix
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Algorithm parameters                                                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.L = 5;                              % Length of rolling window
Par.NumPart = 1000;                     % Number of particles

Par.Vlimit = 2*Par.Vmax;                % Limit above which we do not accept velocity (lh=0)
Par.BirthExclusionRadius = 10;          % Radius within which a birth site is not identified
Par.KFInitVar = 1E-20;                  % Variance with which to initialise Kalman Filters (scaled identity matrix)
Par.AuctionVar = 10;                    % Variance of likelihood function used for auction bidding
Par.PRemove = 0.5;                      % Probability of removing a track
Par.PAdd = 0.5;                         % Probability of adding a track