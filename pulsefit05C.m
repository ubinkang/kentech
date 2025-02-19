%% 전체 스크립트 시작
function myPulseFit_05C()
    clc; clear; close all;
    
    %% 1. MAT 파일 불러오기
    rawData = load('03-11-17_08.47 25degC_5Pulse_HPPC_Pan18650PF.mat');

    % 시간, 전압, 전류
    time    = rawData.meas.Time;
    voltage = rawData.meas.Voltage;
    current = rawData.meas.Current;

    % 하나의 구조체 data1에 저장
    data1.I = current(:);
    data1.V = voltage(:);
    data1.t = time(:);

    % 전류 상태 구분: C(양전류), R(0), D(음전류)
    data1.type = char(zeros(size(data1.t)));
    data1.type(data1.I>0)  = 'C';
    data1.type(data1.I==0) = 'R';
    data1.type(data1.I<0)  = 'D';

    % 스텝 번호 매기기
    data_length = length(data1.t);
    data1.step = zeros(data_length,1);
    m = 1;
    data1.step(1) = m;
    for j=2:data_length
        if data1.type(j) ~= data1.type(j-1)
            m = m+1;
        end
        data1.step(j) = m;
    end

    %% 2. 각 스텝별 구조체 만들기
    vec_step = unique(data1.step);
    num_step = length(vec_step);

    data_line = struct('V',[],'I',[],'t',[],'indx',[],'type','R','steptime',[],'T',[],'SOC',0);
    data = repmat(data_line, num_step, 1);

    for i_step = 1:num_step
        range = find(data1.step == vec_step(i_step));
        data(i_step).V = data1.V(range);
        data(i_step).I = data1.I(range);
        data(i_step).t = data1.t(range);
        data(i_step).indx = range;
        data(i_step).type = data1.type(range(1));
        data(i_step).steptime = data1.t(range);
        data(i_step).T = zeros(size(range)); 
        % 시간 0 기준으로 재정의
        initT = data(i_step).t(1);
        data(i_step).t = data(i_step).t - initT;
    end

    %% 3. Discharge 스텝 인덱스 추출
    step_dis = [];
    for i=1:num_step
        if strcmp(data(i).type,'D')
            step_dis(end+1) = i;
        end
    end

    % 평균 전류
    for i=1:num_step
        data(i).avgI = mean(data(i).I);
    end

    % deltaV: (여기서는 이전 스텝 마지막 전압과의 차)
    for i=1:num_step
        if i==1
            data(i).deltaV = zeros(size(data(i).V));
        else
            data(i).deltaV = data(i).V - data(i-1).V(end);
        end
    end

    % R = deltaV / avgI
    for i=1:num_step
        if data(i).avgI==0
            data(i).R = zeros(size(data(i).V));
        else
            data(i).R = (data(i).deltaV / data(i).avgI) .* ones(size(data(i).V));
        end
    end

    % R0, R1 추정
    for i=1:length(step_dis)
        idx = step_dis(i);
        if length(data(idx).t)>=5
            data(idx).R001s = data(idx).R(1);
            if length(data(idx).R)>=11
                data(idx).R1s = data(idx).R(11);
            else
                data(idx).R1s = data(idx).R(end);
            end
            data(idx).R0 = data(idx).R001s;
            data(idx).R1 = data(idx).R1s - data(idx).R001s;
        else
            data(idx).R001s = NaN;
            data(idx).R1s   = NaN;
            data(idx).R0    = NaN;
            data(idx).R1    = NaN;
        end
    end

    % 63.2% (tau)
    for i=1:length(step_dis)
        idx = step_dis(i);
        minV = min(data(idx).V);
        maxV = max(data(idx).V);
        targetV = minV + (1-0.632)*(maxV-minV);

        [~, t632idx] = min(abs(data(idx).V - targetV));
        timeVec = data(idx).t;
        if isduration(timeVec)
            timeVec = seconds(timeVec);
            data(idx).t = timeVec;
        end

        data(idx).timeAt632 = timeVec(t632idx);

        if ~isnan(data(idx).R0) && ~isnan(data(idx).R1)
            data(idx).C = data(idx).timeAt632 / (data(idx).R1s - data(idx).R001s);
        else
            data(idx).C = NaN;
        end
    end

    % 임의로 SOC 부여
    soc_values = [1, 0.95, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.25, 0.2, 0.15, 0.1, 0.05];
    steps_per_level = 5;
    SOC = zeros(length(step_dis),1);
    currIdx = 1;
    for i=1:length(soc_values)
        endIdx = min(currIdx+steps_per_level-1, length(step_dis));
        SOC(currIdx:endIdx) = soc_values(i);
        currIdx = endIdx+1;
    end
    for i=1:length(step_dis)
        data(step_dis(i)).SOC = SOC(i);
    end

    %% 4. "0.5C"인 스텝만 골라내기
    if length(step_dis)>=2
        refI = data(step_dis(2)).avgI;
    else
        refI = 1;
    end

    step_05C = [];
    tol = 1e-3;
    for i=1:length(step_dis)
        idx = step_dis(i);
        cRate = data(idx).avgI / refI;
        if abs(cRate - 0.5) < tol
            step_05C(end+1) = idx; 
        end
    end
    fprintf('Discharge 스텝 중 "0.5C" 스텝 개수: %d\n', length(step_05C));

    %% 5. 1RC 피팅 (멀티스타트) - 오직 step_05C만
    optimized_params_struct_final_1RC = struct('R0',[],'R1',[],'C',[],...
                                               'SOC',[],'Crate',[],'m',[]);

    num_start_points = 10;
    ms = MultiStart('Display','off');

    for i=1:length(step_05C)
        idx = step_05C(i);

        deltaV_exp = data(idx).deltaV;
        time_exp   = data(idx).t;
        avgI       = data(idx).avgI;
        R0_initial = data(idx).R0;
        if isnan(R0_initial), R0_initial = 0.01; end

        m_candidates = [2/max(1e-6,data(idx).timeAt632), ...
                        1/max(1e-6,data(idx).timeAt632), 1.05, 1.4];
        best_cost  = Inf;
        best_params= [NaN, NaN];
        best_m     = NaN;

        if (time_exp(end)-time_exp(1))<0
            continue; 
        end

        init_guess_R1 = data(idx).R1;
        init_guess_C  = data(idx).C;
        if isnan(init_guess_R1), init_guess_R1=0.02; end
        if isnan(init_guess_C),  init_guess_C =1000; end

        initial_guesses = repmat([init_guess_R1, init_guess_C], num_start_points,1);
        lb = [0, 0];
        ub = [];
        options = optimoptions('fmincon','Display','none','MaxIterations',100);

        for m_idx=1:length(m_candidates)
            m_val = m_candidates(m_idx);
            problem = createOptimProblem('fmincon',...
                'objective', @(prms) cost_function(prms, time_exp, deltaV_exp, avgI, m_val, R0_initial),...
                'x0',initial_guesses(1,:), 'lb',lb, 'ub',ub, 'options',options);
            [opt_params, costVal] = run(ms, problem, num_start_points);
            if costVal<best_cost
                best_cost=costVal;
                best_params=opt_params;
                best_m=m_val;
            end
        end

        cRate = avgI/refI;
        optimized_params_struct_final_1RC(i).R0  = R0_initial;
        optimized_params_struct_final_1RC(i).R1  = best_params(1);
        optimized_params_struct_final_1RC(i).C   = best_params(2);
        optimized_params_struct_final_1RC(i).SOC = data(idx).SOC;
        optimized_params_struct_final_1RC(i).Crate= cRate;
        optimized_params_struct_final_1RC(i).m   = best_m;
    end

    %% 6. 서브플롯: 오직 step_05C만 (4×4 = 16개씩 표시)
    plots_per_fig = 16;      % 한 Figure당 16개의 subplot
    fig_counter = 1;
    subplot_idx = 1;
    figure(fig_counter); 
    set(gcf,'Units','pixels','Position',[100,100,1200,800]);
    sgtitle('Only 0.5C Steps: Experimental vs Model (4x4)');

    for i=1:length(step_05C)
        idx = step_05C(i);
        time_exp   = data(idx).t;
        deltaV_exp = data(idx).deltaV;
        avgI       = data(idx).avgI;

        if (time_exp(end)-time_exp(1))<0
            continue;
        end

        if subplot_idx>plots_per_fig
            fig_counter=fig_counter+1;
            figure(fig_counter);
            set(gcf,'Units','pixels','Position',[100,100,1200,800]);
            sgtitle(sprintf('Only 0.5C Steps: Experimental vs Model (%dx%d)',4,4));
            subplot_idx=1;
        end

        subplot(4,4,subplot_idx);  % 4행 4열
        hold on; grid on;

        R0_opt = optimized_params_struct_final_1RC(i).R0;
        R1_opt = optimized_params_struct_final_1RC(i).R1;
        C_opt  = optimized_params_struct_final_1RC(i).C;
        m_opt  = optimized_params_struct_final_1RC(i).m;
        soc_val= optimized_params_struct_final_1RC(i).SOC;
        cRate_val = optimized_params_struct_final_1RC(i).Crate;

        if isduration(time_exp)
            time_exp = seconds(time_exp);
        end
        % 모델 예측
        voltage_model = model_func(time_exp, R0_opt, R1_opt, C_opt, avgI);

        plot(time_exp, deltaV_exp,'b-','LineWidth',1.5,'DisplayName','실험');
        plot(time_exp, voltage_model,'r--','LineWidth',1.5,'DisplayName','모델');
        
        if isfield(data(idx),'timeAt632') && ~isempty(data(idx).timeAt632)
            t632 = data(idx).timeAt632;
            plot([t632,t632],[min(deltaV_exp),max(deltaV_exp)],'g--','LineWidth',1.2,'DisplayName','63.2%');
        end
        
        soc_txt = sprintf('SOC=%.1f%%', soc_val*100);
        
        m_txt   = sprintf('m=%.2f', m_opt);
        text(time_exp(1)+0.05*(time_exp(end)-time_exp(1)),...
             max(deltaV_exp)*0.9, {soc_txt,m_txt},...
             'FontSize',8,'Color','k','FontWeight','bold');
        
        xlabel('Time(s)'); ylabel('Voltage(V)');
        title(sprintf('0.5C Step idx=%d', idx));
        legend('Location','best','FontSize',7);
        
        subplot_idx=subplot_idx+1;
    end

    % (선택) 결과 저장
    save('optimized_params_05C.mat','optimized_params_struct_final_1RC');
end

%% ------------------------------ 보조 함수들 --------------------------------
function cost = cost_function(params, time, deltaV, I, m, R0)
    R1 = params(1);
    C  = params(2);
    voltage_model = model_func(time, R0, R1, C, I);
    error = deltaV - voltage_model;

    if isduration(time), time=seconds(time); end
    time_weights = exp(-m * time);
    weighted_err = error .* time_weights;
    cost = sqrt(mean(weighted_err.^2));
end

function voltage_model = model_func(time, R0, R1, C, I)
    if isduration(time), time=seconds(time); end
    voltage_model = I .* (R0 + R1 .* (1 - exp(-time./(R1*C))) );
end
