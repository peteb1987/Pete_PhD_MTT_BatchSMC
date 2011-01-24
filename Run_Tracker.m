% Base script for multi-frame single-target tracker using batch SMC

% Clear the workspace (maintaining breakpoints)
clup

% Set a standard random stream (for repeatability)
s = RandStream('mt19937ar', 'seed', 4);
RandStream.setDefaultStream(s);

% Define all the necessary parameters in a global structure.
DefineParameters;

% Specify target behaviour
TargSpec = SpecifyTargetBehaviour;

% Generate target motion
[TrueState, TargSpec] = GenerateTargetMotion(TargSpec);

% Generate observations from target states
[Observs] = GenerateObs(TrueState);

% Plot states and observations
fig = PlotTrueState(TrueState);
PlotObs(Observs);

% Run tracker
% [ Distns, ESS_post, ESS_pre, num_resamples ] = EasySingleTargetTrack( Observs );
[ Distns, ESS_post, ESS_pre, num_resamples ] = MultiTargetTrack( Observs );

% Plot final estimates
PlotTracks(Distns{Par.T}, fig);

% Plot ESS
figure, plot(ESS_post), ylim([0 Par.NumPart])
figure, plot(ESS_pre), ylim([0 Par.NumPart])
disp(['Particles resampled ' num2str(num_resamples) ' times']);