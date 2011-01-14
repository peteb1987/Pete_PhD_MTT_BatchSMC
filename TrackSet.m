classdef TrackSet < handle
    %TRACKSET A set of track objects, comprising a multi-target state over
    %the duration of a scene
    
    properties
        tracks          % Cell array of track objects
        N               % Number of tracks

    end
    
    methods
        
        % Constructor
        function obj = TrackSet(tracks)
            obj.tracks = tracks;
            obj.N = length(tracks);
        end %Constructor
        
        % Copy
        
        
        
    end
    
end

