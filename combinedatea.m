%% Initiation

% First and last frame of fluoview to read
frame_fl_first = 1;
frame_fl_last = 5000;

% Offset between fluoview and fly/arena view (in fluoview frames (100 fps))
% Negative = flyview starts later
frame_offset = 58;

% fv oversample ratio
fv_os = 10;

% Read the files
% [fn_fl, filepath] = uigetfile('*.tif','Get fluoview: ');
% fn_av = uigetfile(fullfile(filepath,'av*.fmf'),'Get arenaview: ');
% fn_fv = uigetfile(fullfile(filepath,'fv*.fmf'),'Get flyview: ');


%% Read the stacks

% Determine frames to read
frames2read_fl = frame_fl_first:frame_fl_last;
n_frames2read = length(frames2read_fl);

% Read a sample frame
% fl_sample = imread(fullfile(filepath,fn_fl),1);

% Read the fluoview stack and resize it to 512 x 512
fl_stack = uint8(zeros(512,512,n_frames2read));
disp('Reading fluoview stack...')
tic
for i = 1 : n_frames2read
    tempframe = imresize(imread(fullfile(filepath,fn_fl)...
        ,frames2read_fl(i)),[512 512]);
    fl_stack(:,:,i) = flip(imrotate(tempframe,180),1);
end

fl_stack = uint8(fl_stack);
toc

% Read the arenaview stack
disp('Reading arenaview stack...')
tic
av_stack = fmf_read( fullfile(filepath,fn_av), frame_fl_first +...
    frame_offset, n_frames2read, 1, 1 );
toc

% Read the flyview stack
disp('Reading flyview stack...')
tic
fv_stack = uint8(fmf_read( fullfile(filepath,fn_fv), frame_fl_first*fv_os +...
    frame_offset*fv_os, n_frames2read, fv_os, 1 ));

% resize the flyview to 512 x 512
fv_stack512 = uint8(zeros(512,512,n_frames2read));
for i = 1 : n_frames2read
    fv_stack512(:,:,i) = imresize(fv_stack(:,:,i), [512 512]);
end
toc

%% Simple concatenation
save(fullfile(filepath,'combined.mat'))
%%
movie_con = horzcat(av_stack,fv_stack512+50,uint8((single(fl_stack)-180)/75*255));
stkwrite(movie_con,fullfile(filepath,'combined.tif'))

%% Make Figure
% % figure('Position',[0 50 1500 400])
% 
% % Plot arenaview
% % subplot(1,3,1)
% % imshow(av_stack(:,:,1))
% 
% % Plot flyview
% subplot(1,3,2)
% imshow(fv_stack512(:,:,1),[0 150])
% 
% % Plot fluoview
% subplot(1,3,3)
% imshow(fl_stack(:,:,1),maps/255)