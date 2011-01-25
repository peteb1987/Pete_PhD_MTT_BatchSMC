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
        function new = Copy(obj)
            t = cell(size(obj.tracks));
            for k = 1:length(t)
                t{k} = obj.tracks{k}.Copy;
            end
            new = TrackSet(t);
        end
        
        
        %ProjectTracks - Projects each track in a TrackSet forward by one frame.
        function ProjectTracks(obj, t)
            
            global Par;
            
            % Loop through targets
            for j = 1:obj.N
                
                % Check that the track ends at t-1
                assert(obj.tracks{j}.death==t, 'Track to be projected does not end at t-1');
                
                % Get previous state
                prev_state = obj.tracks{j}.GetState(t-1);
                
                % Project it forward
                state = Par.A * prev_state;
                
                % Extend the track
                obj.tracks{j}.Extend(t, state, 0);
                
            end
            
        end
        
        
        
        %SamplfJAH - Probabilitically selects a joint association hypothesis for a frame
        function prob = SampleJAH(obj, t, Observs )

            % % % As a first approximation, use ML % % %
            
            % Dig out target states
            states = cell(obj.N, 1);
            for j = 1:obj.N
                states{j} = obj.tracks{j}.GetState(t)';
            end
            
            % Auction algorithm for ML associations
            assoc = AuctionAssoc( states, Observs(t).r );
            
            % Set associations
            for j = 1:obj.N
                obj.tracks{j}.SetAssoc(t, assoc(j));
            end
            
            prob = log(1);
            
        end
        
    end
    
end

