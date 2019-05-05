single_ap_fn = 'c:\projects\xenapse2d\Dynamin\Dynamin single pulse latency analysis Baseline 50frame 100hz acqusition\37_CMOS\0125\2\MDA_1 1Ap\MDA_1 1Ap_MMStack_Pos0.ome.tif';
ctrl_fn = 'c:\projects\xenapse2d\Dynamin\Dynamin single pulse latency analysis Baseline 50frame 100hz acqusition\Test analysis\0121\1_37c\MD-5 bleach ctrl\MD-5 bleach ctrl_MMStack_Pos0.ome.tif';

%{
process_tiff(single_ap_fn, 'single_ap_no_blur.tif', 0);
process_tiff(single_ap_fn, 'single_ap_sigma_0_5.tif', 0.5);
process_tiff(single_ap_fn, 'single_ap_sigma_1.tif', 1.0);

process_tiff(ctrl_fn, 'control_no_blur.tif', 0);
process_tiff(ctrl_fn, 'control_sigma_0_5.tif', 0.5);
process_tiff(ctrl_fn, 'cotrol_ap_sigma_1.tif', 1.0);
%}

%{
process_tiff(single_ap_fn, 'single_ap_no_blur_no_bg.tif', 0, 1);
process_tiff(single_ap_fn, 'single_ap_sigma_0_5_no_bg.tif', 0.5, 1);
process_tiff(single_ap_fn, 'single_ap_sigma_1_no_bg.tif', 1.0, 1);

process_tiff(ctrl_fn, 'control_no_blur_no_bg.tif', 0, 1);
process_tiff(ctrl_fn, 'control_sigma_0_5_no_bg.tif', 0.5, 1);
process_tiff(ctrl_fn, 'control_sigma_1_no_bg.tif', 1.0, 1);
%}

process_tiff(single_ap_fn, 'single_ap_no_blur_ta.tif', 0, 0, 0.2);
process_tiff(single_ap_fn, 'single_ap_sigma_0_5_ta.tif', 0.5, 0, 0.2);
process_tiff(single_ap_fn, 'single_ap_sigma_1_ta.tif', 1.0, 0, 0.2);

process_tiff(ctrl_fn, 'control_no_blur_ta.tif', 0, 0, 0.2);
process_tiff(ctrl_fn, 'control_sigma_0_5_ta.tif', 0.5, 0, 0.2);
process_tiff(ctrl_fn, 'control_sigma_1_ta.tif', 1.0, 0, 0.2);
