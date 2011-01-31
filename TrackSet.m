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
        
        
        
        % Remove Track
        function RemoveTrack(obj, j)
            obj.tracks(j) = [];
            obj.N = obj.N - 1;
        end
        
        
        
        %ProjectTracks - Projects each track in a TrackSet forward by one frame.
        function ProjectTracks(obj, t)
            
            global Par;
            
            % Loop through targets
            for j = 1:obj.N
                
                if obj.tracks{j}.death == t
                    % Only extend it if it dies in the current frame. If
                    % not, its expired completely.
                    
                    % % Check that the track ends at t-1
                    % assert(obj.tracks{j}.death==t, 'Track to be projected does not end at t-1');
                    
                    % Get previous state
                    prev_state = obj.tracks{j}.GetState(t-1);
                    
                    % Project it forward
                    state = Par.A * prev_state;
                    
                    % Extend the track
                    obj.tracks{j}.Extend(t, state, 0);
                    
                end
                
            end
            
        end
        
        
        
        %SamplfJAH - Probabilitically selects a joint association hypothesis for a frame
        function prob = SampleJAH(obj, t, Observs )

            global Par;
            
            prob = 0;
            
            % Propose target death
            if (t>2)
                for j = 1:obj.N
                    if (obj.tracks{j}.Present(t)) ...
                            && (obj.tracks{j}.GetAssoc(t)==0) ...
                            && (obj.tracks{j}.GetAssoc(t-1)==0) ...
                            && (obj.tracks{j}.GetAssoc(t-2)==0)
                        if rand < Par.PRemove
                            obj.tracks{j}.EndTrack(t-2);
                        end
                        prob = prob + log(0.5);
                    end
                end
            end
            
            % % % As a first approximation, use ML % % %
            
            % Dig out target states
            states = cell(obj.N, 1);
            for j = obj.N:-1:1
                if obj.tracks{j}.Present(t)
                    states{j} = obj.tracks{j}.GetState(t)';
                else
                    states(j) = [];
                end
            end
            
            % Fudge to make sure its the right way round
            if isempty(states)
                states = cell(0, 1);
            end
            
            % Generate a list of observations
            if Par.FLAG_ObsMod == 0
                obs = Observs(t).r;
            elseif Par.FLAG_ObsMod == 2
                obs = zeros(size(Observs(t).r));
                obs(:,1) = Observs(t).r(:,2).*cos(Observs(t).r(:,1));
                obs(:,2) = Observs(t).r(:,2).*sin(Observs(t).r(:,1));
            end
            
            % Auction algorithm for ML associations
            assoc = AuctionAssoc( states, obs );
            
            % Set associations
            i = 0;
            for j = 1:obj.N
                if (obj.tracks{j}.Present(t))
                    i = i + 1;
                    obj.tracks{j}.SetAssoc(t, assoc(i));
                end
            end
            
        end
        
    end
    
end

