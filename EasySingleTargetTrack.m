function [ Distns ] = EasySingleTargetTrack( Observs )
%EASYSINGLETARGETTRACK Runs a batch SMC tracking algorithm for a single
% target with no missed observations or clutter

global Par;

% Initialise particle array (an array of particle arrays)
Distns = cell(Par.T);

% Initialise particle set
init_track = Track(0, 1, {[0; 0; 5; 0]}, 0);
init_track_set = TrackSet({init_track});
part_set = repmat({init_track_set}, Par.NumPart, 1);
InitEst = PartDistn(part_set);

% Loop through time
for t = 1:Par.T
    
    if t==1
        Distns{t} = BatchSMC(t, t, InitEst, Observs);
    elseif t<Par.L
        Distns{t} = BatchSMC(t, t, Distns{t-1}, Observs);
    else
        Distns{t} = BatchSMC(t, Par.L, Distns{t-1}, Observs);
    end


end




end



function Distn = BatchSMC(t, L, InitEst, Observs)
% Execute a step of the SMC batch sampler

% Initialise particle array and weight array
Distn = InitEst.Copy;

% Loop through particles
for ii = 1:Par.NumPart
    
    % Filter the observations with a Kalman filter
    
    % Propose a new track from the KF distribution
    
    % Update the weights
    
end

% Test effective sample size
if 1
    
    % Resample
   
end




end