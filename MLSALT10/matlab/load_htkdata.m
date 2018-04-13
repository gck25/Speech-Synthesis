% function [data info] = load_htkdata(file)
function [data,info] = load_htkdata(file)

fid = fopen(file);

info_long = fread(fid,2,'long');
info_int = fread(fid,2,'short');
info=[info_long(1) info_int(1)/4];

data = fread(fid,[info_int(1)/4,inf],'float');

fclose(fid);





