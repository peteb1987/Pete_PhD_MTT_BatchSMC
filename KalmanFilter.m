function [ EstState, EstVar ] = KalmanFilter( obs, init_state, init_var )
%KALMANFILTER Kalman filter a set of observations to give a track estimate

global Par;

L = length(obs(:,1));

PredState = cell(L, 1);
PredVar = cell(L, 1);

PredVar = cell(L, 1);
EstVar = cell(L, 1);

% Loop through time
for k = 1:L
    
    % Prediction step
    
    if k==1
        PredState{1} = Par.A * init_state;
        PredVar{1} = Par.A * init_var * Par.A + Par.Q;
    else
        PredState{k} = Par.A * EstState{k-1};
        PredVar{k} = Par.A * EstVar{k-1} * Par.A + Par.Q;
    end
    
    % Update step
    
    % Innovation
    y = obs{k} - Par.C * PredState{k};
    s = Par.C * PredVar{k} * Par.C' + Par.R;
    gain = PredVar{k} * Par.C' / s;
    EstState{k} = PredState{k} + gain * y;
    EstVar{k} = (eye(4)-gain*Par.C) * PredVar{k};

end





end

