% function [data info] = load_traj(file,vsize)
   function [mcep,info] = load_traj(file,vsize)

fid=fopen(file);
mcep = fread(fid,[vsize,inf],'float32');

info=size(mcep);

fclose(fid);
