function [DOA_par] = doa_init(Cfg)

antena_phase=Cfg.antena_phase;
phase_cmp=exp(-1i*antena_phase.'*pi/180);
%%
%------------DOA初始化------------%
%----------------DOA CFG ------------------%
DOA_engine=Cfg.doa_method;% 0:  DBF  1:MUSIC  2:DML  3:compare DBF and DML
DOA_info_t = { ...
        { ...
            'DOA_info', ...
            '', ...
            'DOA_info description', ...
            'Auto', ...
            '-1', ...
            {
             {'num',1,'uint16', -1,'real','Sample'}; ...
             {'ele_pos',[4 1],'double', -1,'real','Sample'};...
             {'mask',[4 1],'uint16', -1,'real','Sample'};...
             {'saidx_len',[4 1],'uint16', -1,'real','Sample'};...
             {'saidx',[4 16],'uint16', -1,'real','Sample'};...
             },...
            }, ...
        };
% Generate a bus object in the base workspace from the cell array.
Simulink.Bus.cellToObject(DOA_info_t);


HSA=Simulink.Bus.createMATLABStruct('DOA_info');
HSA.num=uint16(0);%子阵数目
HSA.ele_pos=zeros(4,1);%子阵的俯仰位置
HSA.mask=uint16(zeros(4,1));%子阵的掩码
HSA.saidx_len=zeros(4,1);%子阵的单元数
HSA.saidx=zeros(4,16);%子阵的单元idx


if(Cfg.doa_mode==0)%norm mode
    HSA.num=uint16(Cfg.doa_num_groups);%子阵数目
    for k1=1:HSA.num
        HSA.mask(k1)=Cfg.doa_fft_mux(k1);
        
        for has_idx=1:16
            if(bitget(Cfg.doa_fft_mux(k1),has_idx))
                HSA.ele_pos(k1)=Cfg.antena_position(2,has_idx);
            end
        end
        for k2=1:16
            if(bitget(HSA.mask(k1),k2))
                HSA.saidx_len(k1)=HSA.saidx_len(k1)+1;
                HSA.saidx(k1,HSA.saidx_len(k1))=k2;
            end
        end
    end
    
elseif(Cfg.doa_mode==1)%combine mode
    for k1=1:length(Cfg.combined_doa_fft_mux)
        if(Cfg.combined_doa_fft_mux(k1)~=0)
        
            HSA.num=HSA.num+uint16(1);
            HSA.mask(k1)=Cfg.combined_doa_fft_mux(k1);
            for has_idx=1:16
                if(bitget(Cfg.combined_doa_fft_mux(k1),has_idx))
                    HSA.ele_pos(k1)=Cfg.antena_position(2,has_idx);
                end
            end
            for k2=1:16
                if(bitget(HSA.mask(k1),k2))
                    HSA.saidx_len(k1)=HSA.saidx_len(k1)+1;
                    HSA.saidx(k1,HSA.saidx_len(k1))=k2;
                end
            end
        end
    end
    
end


if(1==HSA.num)
    DOA_3D_enable=0;%1:使能3D DOA   0:不使能3D DOA
else
    DOA_3D_enable=1;%1:使能3D DOA   0:不使能3D DOA
end



ELE_start_angle=Cfg.bfm_ev_down;
ELE_end_angle=Cfg.bfm_ev_up;
ELE_step_num=Cfg.doa_npoint(2);
ELE_reso=(ELE_end_angle-ELE_start_angle)/ELE_step_num;
ELE_angle=ELE_start_angle+[0:ELE_step_num-1]*ELE_reso;
ELE_steer_vector=exp(-1i*2*pi*HSA.ele_pos(1:HSA.num)*sind(ELE_angle));%DBF导向矢量

if(isempty(ELE_steer_vector))
    ELE_steer_vector=1;
end



%case1: DBF engine
DBF_start_angle=Cfg.bfm_az_left;
DBF_end_angle=Cfg.bfm_az_right;
DBF_step_num=Cfg.doa_npoint(1);
DBF_reso=(DBF_end_angle-DBF_start_angle)/DBF_step_num;
DBF_angle=DBF_start_angle+[0:DBF_step_num-1]*DBF_reso;
num_DBF_angle=length(DBF_angle);
DBF_win=ones(Cfg.nvirtual_array,1);%ones(nvirtual_array,1)  hanning(nvirtual_array)
DBF_steer_vector=exp(-1i*2*pi*Cfg.antena_position(1,:).'*sind(DBF_angle));%DBF导向矢量
DBF_steer_vector=DBF_steer_vector.*repmat((phase_cmp),1,num_DBF_angle);%补偿相位
DBF_multi_obj_TH=1;%residual_power/signal_power



%case2: Capon engine
% Capon_start_angle=-90;
% Capon_end_angle=90;
% Capon_step_angle=0.5;
% Capon_angle=[Capon_start_angle:Capon_step_angle:Capon_end_angle];
% num_Capon_angle=length(Capon_angle);
% Capon_diag_alph=0.0000005;%对角加载参数
% Capon_steer_vector=exp(1i*2*pi*Cfg.antena_position(1,:).'*sind(Capon_angle));%Capon导向矢量
% Capon_angle_multi_obj_TH=0.1;%second peak/first peak



%case3: DML engine
DML_sin_angle_reso=(sind(Cfg.bfm_az_right)-sind(Cfg.bfm_az_left))/Cfg.doa_npoint(1);
DML_sin_angle=sind(Cfg.bfm_az_left)+[Cfg.dml_2dsch_start(1):Cfg.dml_2dsch_end(1)]*DML_sin_angle_reso;
DML_angle = asind(DML_sin_angle) ;%asin(-0.95:0.0025:0.95) * 180 / pi
num_DML_angle=length(DML_angle);
DML_down_sampling=Cfg.dml_2dsch_step(1);%
DML_refine_num=ceil(DML_down_sampling/2);
DML_down_sampling_num=fix((num_DML_angle-1)/DML_down_sampling)+1;
DML_steer_vector=exp(1i*2*pi*Cfg.antena_position(1,:).'*sind(DML_angle));%DML导向矢量
DML_steer_vector=DML_steer_vector.*repmat(conj(phase_cmp),1,num_DML_angle);%DML的补偿为负共轭相乘

%------------计算dml的k值-------------%
saidx=zeros(16,1);
saidx_len=0;
for k=1:16
    if(bitget(HSA.mask(1),k))
        saidx_len=saidx_len+1;
        saidx(saidx_len)=k;
    end
end
DML_steer_vector_main=exp(1i*2*pi*Cfg.antena_position(1,saidx(1:saidx_len)).'*sind(DML_angle));%DML导向矢量
DML_d_value=zeros(1,num_DML_angle-1);
for k2=2:num_DML_angle
    DML_d_value(k2-1)=DML_steer_vector_main(:,1)'*DML_steer_vector_main(:,k2);
end




DOA_par.DOA_engine=DOA_engine;
DOA_par.DOA_3D_enable=DOA_3D_enable;
DOA_par.HSA=HSA;
DOA_par.ELE_angle=ELE_angle;
DOA_par.ELE_steer_vector=ELE_steer_vector;
DOA_par.DBF_angle=DBF_angle;
DOA_par.DBF_steer_vector=DBF_steer_vector;
DOA_par.num_DBF_angle=num_DBF_angle;
DOA_par.DBF_win=DBF_win;
DOA_par.DBF_multi_obj_TH=DBF_multi_obj_TH;

DOA_par.DML_angle=DML_angle;
DOA_par.DML_down_sampling=DML_down_sampling;
DOA_par.DML_refine_num=DML_refine_num;
DOA_par.DML_down_sampling_num=DML_down_sampling_num;
DOA_par.DML_steer_vector=DML_steer_vector;
DOA_par.num_DML_angle=num_DML_angle;
DOA_par.DML_d_value=DML_d_value;





end

