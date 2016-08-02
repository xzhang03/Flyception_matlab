function [ ] = stkwrite( data, fn )
%STKWRITE writes tiff stack to the designated path and uses gui to guide
%process if neccesary
%   [ output_args ] = stkwrite( data, fn )

if nargin < 2
    filepath = uigetdir();
    fn = input('Filename = ', 's');
end

data = mat2gray(data);

if exist('filepath','var')
    fn = fullfile(filepath,fn);
end

nslides = size(data,3);

for i = 1 : nslides
    imwrite(data(:, :, i), fn, 'WriteMode', 'append');
end

disp(fn)

end

