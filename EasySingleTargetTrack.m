function [ Distns, ESS, num_resamples ] = EasySingleTargetTrack( Observs )
%EASYSINGLETARGETTRACK Runs a batch SMC tracking algorithm for a single
% target with no missed observations or clutter

global Par;

% Initialise particle array (an array of particle arrays)
Distns = cell(Par.T, 1);
ESS = zeros(Par.T, 1);
num_resamples = 0;

% Initialise particle set
init_track = Track(0, 1, {[5-5; 25; 5; 0]}, 0);
init_track_set = TrackSet({init_track});
part_set = repmat({init_track_set}, Par.NumPart, 1);
InitEst = PartDistn(part_set);

% Loop through time
for t = 1:Par.T
    
    tic;
    
    disp('**************************************************************');
    disp(['*** Now processing frame ' num2str(t)]);
    
    if t==1
        [Distns{t}, ESS(t), resample] = BatchSMC(t, t, InitEst, Observs);
    elseif t<Par.L
        [Distns{t}, ESS(t), resample] = BatchSMC(t, t, Distns{t-1}, Observs);
    else
        [Distns{t}, ESS(t), resample] = BatchSMC(t, Par.L, Distns{t-1}, Observs);
    end

    if resample
        num_resamples = num_resamples + 1;
    end
    
    disp(['*** Frame ' num2str(t) ' processed in ' num2str(toc) ' seconds']);
    disp('**************************************************************');

end




end



function [Distn, ESS, resample] = BatchSMC(t, L, Previous, Observs)
% Execute a step of the SMC batch sampler

global Par;

% Runs an SMC on a batch of frames. We can alter states in t-L+1:t. Frame
% t-L is also needed for filtering, transition density calculations, etc.

% Initialise particle array and weight array
Distn = Previous.Copy;

% Generate a list of associated observations
obs = cell(L, 1);
for k = 1:L
    assert(Observs(t-L+k).N==1, ['There is not one observation in frame ' num2str(t-L+k)]);
    obs{k} = Observs(t-L+k).r(1, :)';
end

% Create a temporary array for un-normalised weights
weight = zeros(Par.NumPart, 1);

% Loop through particles
for ii = 1:Par.NumPart
    
    Part = Distn.particles{ii};
        
    % Filter the observations with a Kalman filter
    [KFMean, KFVar] = KalmanFilter(obs, Part.tracks{1}.GetState(t-L), Par.Q);
    
    % Propose a new track from the KF distribution
    [NewTrack, ppsl_prob] = SampleKalman(KFMean, KFVar);
    
    % Caluclate the probability of the artificial distribution term
    [~, prev_ppsl_prob] = SampleKalman(KFMean(1:L-1, 1), KFVar(1:L-1, 1), Part.tracks{1});
    
    % Update the track
    Part.tracks{1}.Update(t, NewTrack);
    
    % Update the weights
    post_prob = Posterior(t, L, Part, Observs);
    weight(ii) = Distn.weight(ii) ...
               + (post_prob - Distn.prev_post(ii)) ...
               + (prev_ppsl_prob - ppsl_prob);

	% Store probabilities for the next time step
%     Distn.prev_ppsl(ii) = ppsl_prob;
    Distn.prev_post(ii) = post_prob;
    
end

% Normalise weights
weight = exp(weight);
weight = weight/sum(weight);
weight = log(weight);

% Attach weights to particles
for ii = 1:Par.NumPart
    Distn.weight(ii) = weight(ii);
end

% Test effective sample size
ESS = CalcESS(weight);
assert(~isnan(ESS), 'Effective Sample Size is non defined (probably all weights negligible)');
if ESS < 0.5*Par.NumPart
    % Resample
    Distn = SystematicResample(Distn, weight);
    ESS = Par.NumPart;
    resample = true;
   
else
    resample = false;
    
end

end