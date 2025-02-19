function myPulseFit_1RC()
    clc; clear; close all;
    
    %% 1. MAT 파일 불러오기 (경로/파일명 맞춤 수정)
    % 예) 5 Pulse HPPC data
 
    rawData = load('03-11-17_08.47 25degC_5Pulse_HPPC_Pan18650PF.mat');
    
    % 시간, 전압, 전류 데이터 추출
    time = rawData.meas.Time;       % 1×N (datetime 또는 숫자형 등 실제 확인)
    voltage = rawData.meas.Voltage; % 1×N
    current = rawData.meas.Current; % 1×N
    
    % 예시로 struct data1에 저장
    data1.I = current(:);   % 열벡터화
    data1.V = voltage(:);
    data1.t = time(:);
    
    % 전류 상태 구분 (Charge 'C', Rest 'R', Discharge 'D')
    data1.type = char(zeros(size(data1.t)));
    data1.type(data1.I > 0)  = 'C';
    data1.type(data1.I == 0) = 'R';
    data1.type(data1.I < 0)  = 'D';
    
    % step 구분
    data_length = length(data1.t);
    data1.step = zeros(data_length, 1);
    m = 1;
    data1.step(1) = m;
    for j = 2:data_length
        if data1.type(j) ~= data1.type(j-1)
            m = m + 1;
        end
        data1.step(j) = m;
    end
    
    % 유니크 스텝
    vec_step = unique(data1.step);
    num_step = length(vec_step);
    
    % 구조체 배열 data: 각 스텝별 구간 저장
    data_line = struct('V',[],'I',[],'t',[],'indx',[],'type','R','steptime',[],'T',[],'SOC',0);
    data = repmat(data_line, num_step, 1);  % num_step 길이의 구조체 생성
    
    for i_step = 1:num_step
        range = find(data1.step == vec_step(i_step));
        data(i_step).V       = data1.V(range);
        data(i_step).I       = data1.I(range);
        data(i_step).t       = data1.t(range);
        data(i_step).indx    = range;
        data(i_step).type    = data1.type(range(1));
        data(i_step).steptime= data1.t(range);
        data(i_step).T       = zeros(size(range)); % 온도 데이터가 없으므로 0으로 설정
        
        % 시간 0으로 재정의(편의상)
        initT = data(i_step).t(1);
        data(i_step).t = data(i_step).t - initT;
    end
    
    %% 2. Discharge 스텝만 인덱싱
    step_chg = [];
    step_dis = [];
    for i = 1:num_step
        if strcmp(data(i).type, 'C')
            step_chg(end+1) = i;
        elseif strcmp(data(i).type, 'D')
            step_dis(end+1) = i;
        end
    end
    
    %% 3. R0, R1, C 추출을 위한 전처리
    % 평균 전류
    for i = 1:num_step
        data(i).avgI = mean(data(i).I);
    end
    
    % deltaV: 직전 스텝의 마지막 전압과의 차
    % 여기서는 예시로: 같은 스텝 내에서는 deltaV를 단순히 (V - V(1))로 할 수도 있고,
    %                  또는 "이전 스텝"과의 차를 구할 수도 있습니다.
    % 아래는 기존 코드를 유지
    for i = 1:num_step
        if i == 1
            data(i).deltaV = zeros(size(data(i).V));
        else
            data(i).deltaV = data(i).V - data(i-1).V(end);
        end
    end
    
    % 단순 저항 R 계산 = deltaV / avgI
    for i = 1:num_step
        if data(i).avgI == 0
            data(i).R = zeros(size(data(i).V));
        else
            data(i).R = (data(i).deltaV / data(i).avgI) .* ones(size(data(i).V));
        end
    end
    
    %% 4. 1초, 10초 시점 저항 (R0, R1) 추정
    for i = 1:length(step_dis)
        idx = step_dis(i);
        if length(data(idx).t) >= 5
            % 0.01초 시점 R
            data(idx).R001s = data(idx).R(1);
            
            % 1초 시점(혹은 10초 시점)을 R1s로 사용 (기존 코드에서 11번째 샘플)
            if length(data(idx).R) >= 11
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
    
    %% 5. 63.2% 시점(tau) 이용해서 C 계산
    for i = 1:length(step_dis)
        idx = step_dis(i);
        
        % 방전 구간에서 min/maxVoltage
        minVoltage = min(data(idx).V);
        maxVoltage = max(data(idx).V);
        
        % 63.2% 값 (기존 코드: minVoltage + (1 - 0.632)*(max - min))
        targetVoltage = minVoltage + (1 - 0.632) * (maxVoltage - minVoltage);
        
        % 가장 가까운 인덱스
        [~, t632idx] = min(abs(data(idx).V - targetVoltage));
        
        % 시간 (주의: data(idx).t가 duration이면 seconds() 변환 필요)
        timeVec = data(idx).t; 
        % 만약 t가 duration이라면:
        if isduration(timeVec)
            timeVec = seconds(timeVec);
            data(idx).t = timeVec;  % double로 덮어쓰기
        end
        
        data(idx).timeAt632 = timeVec(t632idx);
        
        % RC 계산
        % R1s = (R1 + R0) ? or (R1 only) etc. -> 기존 코드 유지
        if ~isnan(data(idx).R001s) && ~isnan(data(idx).R1s)
            data(idx).C = data(idx).timeAt632 / (data(idx).R1s - data(idx).R001s);
        else
            data(idx).C = NaN;
        end
    end
    
    %% 6. SOC 배열 정의 (임의 로직)
    % 예: soc_values = [1, 0.95, 0.9, 0.8, ...];
    % 여기서는 기존 코드를 그대로 사용
    soc_values = [1, 0.95, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.25, 0.2, 0.15, 0.1, 0.05];
    steps_per_level = 5;
    SOC = zeros(length(step_dis), 1);
    current_index = 1;
    for i = 1:length(soc_values)
        end_index = min(current_index + steps_per_level - 1, length(step_dis));
        SOC(current_index:end_index) = soc_values(i);
        current_index = end_index + 1;
    end
    for i = 1:length(step_dis)
        data(step_dis(i)).SOC = SOC(i);
    end
    
    % 예) 특정 인덱스 130이 존재한다면 SOC를 0.05로 강제
    % (실제 step_dis에 130이 없는 경우 주의)
    if length(data) >= 130
        data(130).SOC = 0.05;
    end
    
    %% 7. 실제 1RC 피팅 실행 (멀티스타트 fmincon)
    % 결과 저장용 구조체
    optimized_params_struct_final_1RC = struct(...
        'R0', [], 'R1', [], 'C', [], 'SOC', [], 'Crate', [], 'm', []);
    
    % MultiStart 설정
    num_start_points = 10;  % 시작점 개수
    ms = MultiStart('Display', 'off');
    
    for i = 1:length(step_dis)
        idx = step_dis(i);
        
        deltaV_exp = data(idx).deltaV;  % 실험 전압(or 전압차)
        time_exp   = data(idx).t;       % 시간
        avgI       = data(idx).avgI;    % 평균 전류
        R0_initial = data(idx).R0;      % 초기 추정 R0
        if isnan(R0_initial), R0_initial = 0.01; end
        
        % 가중치용 m 후보군
        m_candidates = [2 / max(1e-6, data(idx).timeAt632), ...
                        1 / max(1e-6, data(idx).timeAt632), ...
                        1.05, 1.4];
        
        best_cost  = Inf;
        best_params= [NaN, NaN];
        best_m     = NaN;
        
        % step이 충분히 길 경우에만
        step_duration = time_exp(end) - time_exp(1);
        if step_duration < 0
            % 비정상 데이터
            optimized_params_struct_final_1RC(i).R0  = NaN;
            optimized_params_struct_final_1RC(i).R1  = NaN;
            optimized_params_struct_final_1RC(i).C   = NaN;
            optimized_params_struct_final_1RC(i).SOC = NaN;
            optimized_params_struct_final_1RC(i).Crate=NaN;
            optimized_params_struct_final_1RC(i).m   = NaN;
            continue;
        end
        
        % 초기 추정값(예: [R1, C])
        init_guess_R1 = data(idx).R1;
        init_guess_C  = data(idx).C;
        if isnan(init_guess_R1), init_guess_R1 = 0.02; end
        if isnan(init_guess_C),  init_guess_C  = 1000; end
        
        initial_guesses = repmat([init_guess_R1, init_guess_C], num_start_points, 1);
        
        % fmincon 설정
        lb = [0, 0];  % R1 >= 0,  C >= 0
        ub = [];
        options = optimoptions('fmincon', 'Display', 'none', 'MaxIterations', 100);
        
        % m 루프
        for m_idx = 1:length(m_candidates)
            m_val = m_candidates(m_idx);
            
            problem = createOptimProblem('fmincon',...
                'objective', @(prms) cost_function(prms, time_exp, deltaV_exp, avgI, m_val, R0_initial), ...
                'x0', initial_guesses(1,:), ...
                'lb', lb, 'ub', ub, 'options', options);
            
            [opt_params, cost] = run(ms, problem, num_start_points);
            
            if cost < best_cost
                best_cost   = cost;
                best_params = opt_params;
                best_m      = m_val;
            end
        end
        
        % 결과 저장
        optimized_params_struct_final_1RC(i).R0  = R0_initial;
        optimized_params_struct_final_1RC(i).R1  = best_params(1);
        optimized_params_struct_final_1RC(i).C   = best_params(2);
        optimized_params_struct_final_1RC(i).SOC = data(idx).SOC;
        
        % 예: C-rate = avgI / data(step_dis(2)).avgI (원래 코드상)
        %  -> 만약 "기준 전류"가 step_dis(2)라면, idx 2가 존재하는지 유의
        if length(step_dis) >= 2
            ref_I = data(step_dis(2)).avgI;
        else
            ref_I = 1;  % 안전 장치
        end
        optimized_params_struct_final_1RC(i).Crate = avgI / ref_I;
        optimized_params_struct_final_1RC(i).m     = best_m;
    end
    
    %% 8. 서브플롯으로 실험 vs 모델 비교
    plots_per_fig = 9;  % 한 그림당 3x3
    num_figures   = ceil(length(step_dis) / plots_per_fig);
    fig_counter   = 1;
    subplot_idx   = 1;
    
    figure(fig_counter);
    set(gcf, 'Units','pixels','Position',[100,100,1200,800]);
    sgtitle('Comparison of Experimental Data and Model Results');
    
    for i = 1:length(step_dis)
        idx = step_dis(i);
        time_exp   = data(idx).t;
        deltaV_exp = data(idx).deltaV;
        avgI       = data(idx).avgI;
        
        if (time_exp(end) - time_exp(1)) < 0
            continue;  % 비정상
        end
        
        if subplot_idx > plots_per_fig
            fig_counter = fig_counter + 1;
            figure(fig_counter);
            set(gcf, 'Units','pixels','Position',[100,100,1200,800]);
            sgtitle('Comparison of Experimental Data and Model Results');
            subplot_idx = 1;
        end
        
        subplot(3,3,subplot_idx); hold on; grid on;
        
        % 최적화 결과
        R0_opt = optimized_params_struct_final_1RC(idx).R0;
        R1_opt = optimized_params_struct_final_1RC(idx).R1;
        C_opt  = optimized_params_struct_final_1RC(idx).C;
        m_opt  = optimized_params_struct_final_1RC(idx).m;
        soc_val= optimized_params_struct_final_1RC(idx).SOC;
        crate_val = optimized_params_struct_final_1RC(idx).Crate;
        
        if isduration(time_exp)
            time_exp = seconds(time_exp);
        end
        
        % 모델 예측
        voltage_model = model_func(time_exp, R0_opt, R1_opt, C_opt, avgI);
        
        % 실험 데이터 (deltaV_exp) vs 모델 (voltage_model)
        plot(time_exp, deltaV_exp, 'b-', 'LineWidth',1.5, 'DisplayName','실험 데이터');
        plot(time_exp, voltage_model, 'r--','LineWidth',1.5, 'DisplayName','모델 결과');
        
        % 63.2% 라인
        if isfield(data(idx),'timeAt632') && ~isempty(data(idx).timeAt632)
            t632 = data(idx).timeAt632;
            if isduration(t632), t632 = seconds(t632); end
            plot([t632, t632],[min(deltaV_exp),max(deltaV_exp)], 'g--','LineWidth',1.5,'DisplayName','63.2% 시간');
        end
        
        % 텍스트( SOC, C-rate, m )
        soc_text   = sprintf('SOC: %.2f%%', soc_val*100);
        crate_text = sprintf('C-rate: %.2f', crate_val);
        m_text     = sprintf('m: %.2f', m_opt);
        text(time_exp(1)+0.05*(time_exp(end)-time_exp(1)), ...
             max(deltaV_exp)*0.9, {soc_text, crate_text, m_text}, ...
             'FontSize',8,'Color','k','FontWeight','bold');
        
        xlabel('시간 (s)','FontSize',8); 
        ylabel('전압 (V)','FontSize',8);
        title(sprintf('Discharge Step %d', i),'FontSize',10);
        legend('Location','best','FontSize',6);
        
        subplot_idx = subplot_idx + 1;
    end
    
    
end

%% --------------------------------------------------------
%  아래는 사용자 정의 보조 함수들
%% --------------------------------------------------------

function cost = cost_function(params, time, deltaV, I, m, R0)
    % params = [R1, C]
    R1 = params(1);
    C  = params(2);

    % 모델 예측
    voltage_model = model_func(time, R0, R1, C, I);

    % 오차
    error = (deltaV - voltage_model);

    % 시간 가중치: exp(-m * t)
    if isduration(time), time = seconds(time); end
    time_weights = exp(-m * time);

    % RMS 오차, 가중치 적용
    weighted_error = error .* time_weights;
    cost = sqrt(mean(weighted_error.^2));
end

function voltage_model = model_func(time, R0, R1, C, I)
    % 1RC 모델: deltaV(t) = I * [ R0 + R1 * (1 - exp(-t / (R1*C))) ]
    % (사용자 정의 형태)
    if isduration(time), time = seconds(time); end
    voltage_model = I .* ( R0 + R1 * (1 - exp(-time ./ (R1*C))) );
end

function create_plots(SG, CG, Param_grid, Param_name)
    %% 3D Surface
    figure();
    surf(SG, CG, Param_grid, 'EdgeColor','none');
    xlabel('SOC'); ylabel('C-rate'); zlabel(Param_name);
    title([Param_name ' vs. SOC & C-rate']);
    colorbar; view(45,30); grid on;

    %% Contour Plot
    figure();
    contourf(SG, CG, Param_grid, 20, 'LineColor','none');
    xlabel('SOC'); ylabel('C-rate');
    title([Param_name ' Contour Plot']);
    colorbar; grid on;
end
