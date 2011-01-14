function [ Distns ] = EasySingleTargetTrack( Observs )
%EASYSINGLETARGETTRACK Runs a batch SMC tracking algorithm for a single
% target with no missed observations or clutter

global Par;

% Initialise particle array (an array of particle arrays)
Distns = cell(Par.T);

% Initialise particle set
init_track = Track(0, 1, {[-5; 0; 5; 0]}, 0);
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

global Par;

% Runs an SMC on a batch of frames. We can alter states in t-L+1:t. Frame
% t-L is also needed for filtering, transition density calculations, etc.

% Initialise particle array and weight array
Distn = InitEst.Copy;

% Generate a list of associated observations
obs = cell(L, 1);
for k = 1:L
    assert(Observs(t-L+k).N==1, ['There is not one observation in frame ' num2str(t-L+k)]);
    obs{k} = Observs(t-L+k).r(1, :)';
end
    
% Loop through particles
for ii = 1:Par.NumPart
    
    Part = Distn.particles{ii};
        
    % Filter the observations with a Kalman filter
    [KFMean, KFVar] = KalmanFilter(obs, Part.tracks{1}.GetState(t-L), Par.Q);
    
    % Propose a new track from the KF distribution
    [NewTrack, ppsl_prob] = SampleKalman(KFMean, KFVar);
    
    % Update the weights
    
end

% Test effective sample size
if 1
    
    % Resample
   
end




end