classdef PartDistn < handle
    %PARTDISTN A particle approximation of a multi-target state
    
    properties
        particles       % Cell array of TrackSet objects
        weight          % Vector of particle weights, of equal length
    end
    
    methods
        
        % Constructor
        function obj = PartDistn(particles, weight)
            if nargin == 2
                obj.particles = particles;
                obj.weight = weight;
                assert(length(particles)==length(weight), 'Particle array and weight array have different sizes');
            elseif nargin == 1
                obj.particles = particles;
                obj.weight = ones(length(particles),1)/length(particles);
            end
        end
        
        
        
        % Copy
        function new = Copy(obj)
            p = cell(size(obj.particles));
            for k = 1:length(p)
                p{k} = obj.particles{k}.Copy;
            end
            new = PartDistn(p, obj.weight);
        end
        
        
        
        
    end
    
end

