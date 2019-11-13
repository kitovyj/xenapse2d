%exp_folder = 'newest';
%ctrl_folder = 'dynamin 37c no stim';

exp_folder = 'Dyn1 GFP cont 4mM Ca2+ 200frame base\selected-rt\';

files = dir([ exp_folder '/**/*.tif' ]);
%files = dir([ ctrl_folder '/**/*.tif' ]);

all_events = {};

for i = 1 : length(files)
    f = fullfile(files(i).folder, files(i).name);
    data = ImagingData();
    data.load(f, 0.2);
    [intensities, events] = data.analyze_xenapses(find(data.responded_xenapses == 0), 1, 1);     
    all_events{end + 1} = { events, intensities };
    
end

save('events.mat', 'all_events');