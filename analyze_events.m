%load('ctrl-events.mat');
%load('exp-events.mat');
load('events.mat');

amplitudes = [];

latencies = [];

event_latencies = [];
event_onsets = [];
life_times = [];

figure;

stimulus_time_point = 200;

for i = 1:numel(all_events)

    intensities = all_events{i}{2};
    
    for j = 1:size(intensities, 1)
    
        % plot(intensities(j, :));

        % w = gausswin(30);
        % w = gausswin(30);
        % intensities(j, :) = filter(w, 1, intensities(j, :));
        intensities(j, :) = smooth(intensities(j, :), 30);

        % plot(intensities(j, :));
    
    end
    
    %intensity = imgaussfilt(intensity, 10.0);

    if numel(intensities) == 0
        continue
    end
    
    [mv, mi] = max(intensities(:, stimulus_time_point:(stimulus_time_point + 400)), [], 2);
    
    latencies = [latencies; mi];
    
    for j = 1:numel(all_events{i}{1})
       
        events = all_events{i}{1}{j};
                
        for k = 1:numel(events)
            e = events(k).events;
            sigma = events(k).sigma;
            max_a = max(e(:, 4)) / sigma;   
            amplitudes = [amplitudes max_a];
            
            latency = e(1, 1);

            life_time = e(end, 1) - e(1, 1) + 1;
            
            if life_time / 100. < 1.0
               continue; 
            end
            
            life_times = [life_times life_time];        
            
            event_latencies = [event_latencies latency];
            
        end
        
        
    end
    
end

event_latencies = event_latencies / 100.;
life_times = life_times / 100.;


latencies = latencies / 100.;

se = std(latencies) / sqrt(length(latencies));

disp(mean(latencies));

disp(se);
disp(mean(amplitudes));