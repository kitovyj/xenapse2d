fn = 'MD-5 bleach ctrl_MMStack_Pos0.ome.mat';
%fn = 'MDA_5_2 5Ap 100hz_MMStack_Pos0.ome.mat';

load(fn);

frame_rate = 100;
min_life_time = 0.5;

life_times = [];

for i = 1:numel(all_spots_history)
   
    xh = all_spots_history{i};
    
    for j = 1:numel(xh)
  
        sph = xh{j};
        
        event_start = sph(1, 1) / frame_rate;
        
        if event_start > 5.
            continue
        end
        
        life_time = sph(end, 1) - sph(1, 1) + 1;
        life_time_s = single(life_time) / frame_rate;  
        
        if life_time_s < min_life_time
            continue
        end
        
        life_times = [life_times life_time_s];
        
    end
    
    
end

f = figure;
set(f, 'name', ['Life time - ' fn], 'NumberTitle', 'off');      
h = histogram(life_times, 'FaceColor', 'g');
set_plot_annotation(life_times);
