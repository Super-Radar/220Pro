function [CfarPra] = cfar_init(Cfg)
%------------------------------------------------------------------------------
%   cfar_init.m
%------------------------------------------------------------------------------
%   Author       : ZhuXinpeng
%   Created      : 2021-04-12
%   Description  : cfar para init
%------------------------------------------------------------------------------
%   Reviser      : ZhuXinpeng
%   Edited       : 2021-10-19
%   Description  : add cfar_recwin_decimate
%------------------------------------------------------------------------------

%分区参数
CfarPra.regionR  = Cfg.cfar_region_sep_rng + 1;%[37, 121, 350];
CfarPra.regionV  = (reshape(Cfg.cfar_region_sep_vel + 1, 2, 4)).';

CfarPra.cfar_recwin_msk     = zeros(11,11,8);
mskTmp1      = dec2bin(Cfg.cfar_recwin_msk,11);
mskTmp2      = zeros(88,11);
for m = 1:88
    for n = 1:11
        mskTmp2(m,n)    = str2num(mskTmp1(m,n));
    end
end
for m = 1:8
    CfarPra.cfar_recwin_msk(:,:,m)  = mskTmp2((m-1)*11+1:m*11,:);
end
% CfarPra.cfar_recwin_msk = dec2bin(Cfg.cfar_recwin_msk,11);

%CFAR参数
if(isempty(Cfg.cfar_region_algo_type))
    Cfg.cfar_region_algo_type=0;
end

cfarRegionAlgoTypeRead = dec2bin(Cfg.cfar_region_algo_type,16);
CfarPra.cfar_region_algo_type = flip(bin2dec(reshape(cfarRegionAlgoTypeRead,2,8)')');
CfarPra.cfar_ca_n = Cfg.cfar_ca_n;
CfarPra.cfar_ca_alpha = Cfg.cfar_ca_alpha;
CfarPra.cfar_pk_win_size1 = Cfg.cfar_pk_win_size1;
CfarPra.cfar_os_rnk_sel = Cfg.cfar_os_rnk_sel;
CfarPra.cfar_os_tdec = Cfg.cfar_os_tdec;
CfarPra.cfar_os_rnk_ratio = Cfg.cfar_os_rnk_ratio;
CfarPra.cfar_os_alpha = Cfg.cfar_os_alpha;
CfarPra.cfar_crswin_rng_size = Cfg.cfar_crswin_rng_size;
CfarPra.cfar_crswin_rng_skip = Cfg.cfar_crswin_rng_skip;
CfarPra.cfar_crswin_vel_size = Cfg.cfar_crswin_vel_size;
CfarPra.cfar_crswin_vel_skip = Cfg.cfar_crswin_vel_skip;

if(Cfg.cfar_combine_dirs)
    CfarPra.mimo_cfar_steer_vector=zeros(Cfg.nvirtual_array,Cfg.cfar_combine_dirs);
    for beamNum=1:Cfg.cfar_combine_dirs
        for k=1:Cfg.nvirtual_array
            CfarPra.mimo_cfar_steer_vector(k,beamNum)=exp(-1i*2*pi*Cfg.ant_pos(2*k-1)*sind(Cfg.cfar_combine_thetas(beamNum))*cosd(Cfg.cfar_combine_phis(beamNum)))...
                *exp(-1i*2*pi*Cfg.ant_pos(2*k)*sind(Cfg.cfar_combine_phis(beamNum)))*exp(1i*Cfg.ant_comps(k)/180*pi);
        end
    end
else
    CfarPra.mimo_cfar_steer_vector= 0;
end

if(Cfg.cfar_sliding_win)
    CfarPra.cfar_sliding_choice = 1;
    CfarPra.exp_num_r = Cfg.cfar_crswin_rng_size + Cfg.cfar_crswin_rng_skip;
    CfarPra.exp_num_fd = Cfg.cfar_crswin_vel_size + Cfg.cfar_crswin_vel_skip;
else
    CfarPra.cfar_sliding_choice = 0;
    CfarPra.cfar_recwin_decimate = Cfg.cfar_recwin_decimate;
    if CfarPra.cfar_recwin_decimate ~= 0
        cfar_recwin_decimate = dec2bin(Cfg.cfar_recwin_decimate, 16);
        [CfarPra.exp_num_r_0, CfarPra.exp_num_fd_0] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(1:2)));
        [CfarPra.exp_num_r_1, CfarPra.exp_num_fd_1] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(3:4)));
        [CfarPra.exp_num_r_2, CfarPra.exp_num_fd_2] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(5:6)));
        [CfarPra.exp_num_r_3, CfarPra.exp_num_fd_3] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(7:8)));
        [CfarPra.exp_num_r_4, CfarPra.exp_num_fd_4] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(9:10)));
        [CfarPra.exp_num_r_5, CfarPra.exp_num_fd_5] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(11:12)));
        [CfarPra.exp_num_r_6, CfarPra.exp_num_fd_6] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(13:14)));
        [CfarPra.exp_num_r_7, CfarPra.exp_num_fd_7] = choice_cfar_recwin_decimate(bin2dec(cfar_recwin_decimate(15:16)));
    end
end

end

function [exp_num_r, exp_num_fd] = choice_cfar_recwin_decimate(cfar_recwin_decimate)
switch(cfar_recwin_decimate)
    case 0%不抽取
        exp_num_r       = 5;
        exp_num_fd      = 5;
    case 1%距离抽取
        exp_num_r       = 10;
        exp_num_fd      = 5;
    case 2%速度抽取
        exp_num_r       = 5;
        exp_num_fd      = 10;
    case 3%速度距离抽取
        exp_num_r       = 10;
        exp_num_fd      = 10;
    otherwise
end

end