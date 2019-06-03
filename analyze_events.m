%load('ctrl-events.mat');
load('exp-events.mat');

amplitudes = [];

for i = 1:numel(all_events)
    
    for j = 1:numel(all_events{i})
       
        events = all_events{i}{j};
                
        for k = 1:numel(events)
            e = events(k).events;
            sigma = events(k).sigma;
            max_a = max(e(:, 4)) / sigma;   
            amplitudes = [amplitudes max_a];
        end
        
    end
    
end

disp(mean(amplitudes));