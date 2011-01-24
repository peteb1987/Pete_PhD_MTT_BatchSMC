function Set = ProjectTracks( t, SetIn )
%PROJECTTRACKS Projects each track in a TrackSet forward by one frame.

global Par;

Set = SetIn.Copy;

% Loop through targets
for j = 1:Set.N
    
    % Check that the track ends at t-1
    assert(Set.tracks{j}.death==t, 'Track to be projected does not end at t-1');
    
    % Get previous state
    prev_state = Set.tracks{j}.GetState(t-1);
    
    % Project it forward
    state = Par.A * prev_state;
    
    % Extend the track
    Set.tracks{j}.Extend(t, state, 0);

end

end