%% Initiation

% Whether registrate flyview or not
reg_fv = 1;

% First and last frame of fluoview to read
frame_fl_first = 1;
frame_fl_last = 2200;
frame_fl_incr = 1;

% Offset between fluoview and fly/arena view (in flyview frames (1000 fps))
% Negative = flyview starts later
frame_offset = 60;

% fv oversample ratio
fv_os = 10;

% Get file names
[fn_fl, filepath] = uigetfile('*.tif','Get fluoview: ');

if reg_fv == 1
    fn_fv = uigetfile(fullfile(filepath,'fv*.fmf'),'Get flyview: ');
end

fn_fvtraj = uigetfile(fullfile(filepath,'fv-traj*.txt'),'Get flyview trajectory: ');

% Limit end frame
disp('Reading metadata...')
tifinfo = imfinfo(fullfile(filepath,fn_fl));
frame_fl_last = min(length(tifinfo),frame_fl_last);

%% Read the stacks

% Determine frames to read
frames2read_fl = frame_fl_first: frame_fl_incr: frame_fl_last;
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
if reg_fv == 1
    disp('Reading flyview stack...')
    tic
    [fv_stack, fvtrajframe2read] = fmf_read( fullfile(filepath,fn_fv), frame_fl_first*fv_os +...
        frame_offset*fv_os, n_frames2read, fv_os*frame_fl_incr, 1 );
    fv_stack = uint8(fv_stack);
    toc
else
    % There is a one 1 frame offset for the fmf_read function for some
    % reason
    fvtrajframe2read = frames2read_fl * fv_os + frame_offset*fv_os - 1;
end

% Read the flyview trajectory
disp('Reading flyview trajectory...')
fvtraj = dlmread(fullfile(filepath,fn_fvtraj),' ');

%% Calculate angles and rotate
% Read head and edge positions
headpos = fvtraj(fvtrajframe2read,4:5);
edgepos = fvtraj(fvtrajframe2read,6:7);

% Calculate the angles
rotangles = atan2(headpos(:,2)-edgepos(:,2), headpos(:,1)-edgepos(:,1));

% Determine the bedding size
if reg_fv == 1
    fvbedsize = ceil(sqrt(2)*max(size(fv_stack(:,:,1))));
end
flbedsize = ceil(sqrt(2)*max(size(fl_stack(:,:,1))));

% Initiate new registered stacks
if reg_fv == 1
    fv_stack_reg = uint8(zeros(fvbedsize, fvbedsize, n_frames2read));
end
fl_stack_reg = uint8(zeros(flbedsize, flbedsize, n_frames2read));


% Rotate flyview and pad
if reg_fv == 1
    for i = 1 : n_frames2read
       % Rotate images
       im = imrotate(fv_stack(:,:,i),rad2deg(rotangles(i)));

       % If the gap pixel length is odd then pad with one extra layer of pixels
       if mod(fvbedsize - size(im,1),2) == 1
           im = padarray(im,[1 1],'post');
       end

       % Pad
       fvpadsize = (fvbedsize - size(im))/2;
       fv_stack_reg(:,:,i) = uint8(padarray(im, fvpadsize,'both'));
    end
end

% Rotate fluoview and pad
for i = 1 : n_frames2read
   % Flip and rotate images (180 degree camera compensation)
   im = flip(fl_stack(:,:,i), 1);
   im = imrotate(im,rad2deg(rotangles(i))+180);
   
   % If the gap pixel length is odd then pad with one extra layer of pixels
   if mod(flbedsize - size(im,1),2) == 1
       im = padarray(im,[1 1],'post');
   end
   
   % Pad
   flpadsize = (flbedsize - size(im))/2;
   fl_stack_reg(:,:,i) = uint8(padarray(im, flpadsize,'both'));
end

%% Write the stacks
stkwrite(fl_stack_reg,'fluoview_reg.tif')
if reg_fv == 1
    stkwrite(fv_stack_reg,'flyview_reg.tif')
end
