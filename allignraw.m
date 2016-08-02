%% Initiation

% First and last frame of fluoview to read
frame_fl_first = 1;
frame_fl_last = 3000;

% Offset between fluoview and fly/arena view (in flyview frames (1000 fps))
% Negative = flyview starts later
default_offset = 60;

% fv oversample ratio
fv_os = 10;

% Get file names
[fn_fl, filepath] = uigetfile('*.tif','Get fluoview: ');
fn_fv = uigetfile(fullfile(filepath,'fv*.fmf'),'Get flyview: ');

% Limit end frame
disp('Reading metadata...')
tifinfo = imfinfo(fullfile(filepath,fn_fl));
frame_fl_last = min(length(tifinfo),frame_fl_last);

%% Read the stacks

% Determine frames to read
frames2read_fl = frame_fl_first : frame_fl_last;
n_frames2read = length(frames2read_fl);

% Read a sample frame
fl_sample = imread(fullfile(filepath,fn_fl),1);

% Read the fluoview stack
disp('Reading fluoview stack...')
tic
fl_stack = repmat(fl_sample,[1,1,n_frames2read]);
for i = 1 : n_frames2read
    fl_stack(:,:,i) = imread(fullfile(filepath,fn_fl), frames2read_fl(i));
end
toc

% Read the flyview stack
tic
disp('Reading flyview stack...')
fv_stack = uint8(fmf_read( fullfile(filepath,fn_fv), frame_fl_first*fv_os +...
    default_offset, n_frames2read, fv_os, 1 ));
toc

%% Plot the data

% Calculate means
meanfv = squeeze(mean(mean(fv_stack,1),2));
meanfl = squeeze(mean(mean(fl_stack(75:175,75:175,:),1),2));

figure('Position',[0 50 1500 400])

% Plot fly view with offset
hfv = plot((frame_fl_first:frame_fl_last)-default_offset,...
    meanfv-mean(meanfv),'g-');

% Plot fluoview
hold on
hfl = plot((frame_fl_first:frame_fl_last),meanfl-mean(meanfl),'b-');
hold off

% Default y limit
ylim([-20,20])
xlim([frame_fl_first, frame_fl_last])

%% Use slider to find offset

% Create slider
sld = uicontrol('Style', 'slider',...
        'Min',-200,'Max',200,'Value',default_offset,...
        'Position', [220 60 200 20],....
        'SliderStep',[0.005 0.1]);
    
% Add a text uicontrol to label the slider.
btn = uicontrol('Style','pushbutton',...
    'Position',[220 80 200 20],...
    'String',num2str(get(sld,'Value')));
   
% Callbacks
set(sld,'Callback',@(hObject,eventdata) set(hfv,'XData', (frame_fl_first:frame_fl_last)-round(get(hObject,'Value'))))
set(btn,'Callback',@(hObject,eventdata) set(btn,'String', num2str(get(sld,'Value'))));
