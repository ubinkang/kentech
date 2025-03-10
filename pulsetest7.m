function myPulseFit_05C_Compare()
    clc; clear; close all;

    %% 1. MAT 파일 불러오기 (newStruct)
    S = load('NewPulseData.mat'); 
    dataAll = S.newStruct;  
    % dataAll(i).current, .voltage, .time, .V_final, .SOC_begin, .SOC_end, etc.
    Npulse = numel(dataAll);
    fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);

    %% 2. 데이터 전처리: 각 펄스마다 시간 0부터 시작하도록 조정, 전압 변화(dv) 계산, 평균 전류 계산
    for i = 1:Npulse
        % 시간: duration이면 초(sec)로 변환 후 0부터 시작
        t_raw = dataAll(i).time;
        if isduration(t_raw)
            t_raw = seconds(t_raw);
        end
        dataAll(i).t = t_raw - t_raw(1);
        
        % 전압 변화: measured voltage - V_final
        dataAll(i).dv = dataAll(i).voltage - dataAll(i).V_final;
        
        % 평균 전류
        dataAll(i).avgI = mean(dataAll(i).current);
    end

    %% 3. 1RC 및 2RC 모델 피팅 (모든 펄스에 대해)
    % 1RC 결과 저장: [R0, R1, tau]
    res_1RC = zeros(Npulse, 3);
    % 2RC 결과 저장: [R0, R1, C1, R2, C2]
    res_2RC = zeros(Npulse, 5);
    
    % MultiStart 설정
    ms_1RC = MultiStart('Display','off');
    ms_2RC = MultiStart('Display','off');
    
    % 1RC 초기 추정값 및 경계조건
    init_1RC = [0.03, 0.013, 1.5];
    lb_1RC = [0, 0, 0.5];
    ub_1RC = init_1RC * 10;
    opts_1RC = optimoptions('fmincon','Display','none','MaxIterations',200);
    
    % 2RC 초기 추정값 및 경계조건 (독립 최적화)
    init_2RC = [0.03, 0.013, 1.5, 0.01, 2.0];
    lb_2RC = [0, 0, 0.5, 0, 0.5];
    ub_2RC = init_2RC * 10;
    opts_2RC = optimoptions('fmincon','Display','none','MaxIterations',200);
    
    for i = 1:Npulse
        t_data = dataAll(i).t;
        dv_data = dataAll(i).dv;
        I_val = dataAll(i).avgI;
        
        % 1RC 피팅 (가중치 적용: 초반 강조)
        weight_1RC = exp(-t_data/0.8);
        problem_1RC = createOptimProblem('fmincon',...
            'objective',@(p) cost_1RC(p, t_data, dv_data, I_val, weight_1RC),...
            'x0', init_1RC, 'lb', lb_1RC, 'ub', ub_1RC, 'options', opts_1RC);
        [p_1RC, cost1] = run(ms_1RC, problem_1RC, 10);
        res_1RC(i,:) = p_1RC;
        
        % 2RC 피팅 (기본 RMSE, 가중치 없이)
        problem_2RC = createOptimProblem('fmincon',...
            'objective',@(p) cost_2RC(p, t_data, dv_data, I_val),...
            'x0', init_2RC, 'lb', lb_2RC, 'ub', ub_2RC, 'options', opts_2RC);
        [p_2RC, cost2] = run(ms_2RC, problem_2RC, 10);
        res_2RC(i,:) = p_2RC;
        
        fprintf('Pulse #%d 1RC: R0=%.4f, R1=%.4f, tau=%.4f (cost=%.4g)\n', i, p_1RC(1), p_1RC(2), p_1RC(3), cost1);
        fprintf('Pulse #%d 2RC: R0=%.4f, R1=%.4f, C1=%.4f, R2=%.4f, C2=%.4f (cost=%.4g)\n', i, p_2RC(1), p_2RC(2), p_2RC(3), p_2RC(4), p_2RC(5), cost2);
    end
    
    %% 4. 플로팅: 1RC와 2RC 결과를 동시에 한 서브플롯에 표시 (4×4 grid)
    figure('Name','1RC vs 2RC Comparison','Color','w');
    set(gcf, 'Units','pixels','Position',[100,100,1200,800]);
    sgtitle('Discharge Pulses: Data vs 1RC vs 2RC (4x4 Grid)');
    nplots = min(Npulse, 16);
    for i = 1:nplots
        t_data = dataAll(i).t;
        if isduration(t_data), t_data = seconds(t_data); end
        dv_data = dataAll(i).dv;
        I_val = dataAll(i).avgI;
        
        % 1RC 모델 결과 계산
        y_1RC = func_1RC(t_data, I_val, res_1RC(i,:));
        % 2RC 모델 결과 계산
        y_2RC = model_2RC(t_data, I_val, res_2RC(i,:));
        
        subplot(4,4,i); hold on; grid on;
        % 실험 데이터 플롯 (검정)
        plot(t_data, dv_data, 'ko-', 'LineWidth',1.5, 'DisplayName','Data');
        % 1RC 피팅 결과 (빨간 점선)
        plot(t_data, y_1RC, 'r--', 'LineWidth',1.5, 'DisplayName','1RC');
        % 2RC 피팅 결과 (파란 점-점선)
        plot(t_data, y_2RC, 'b-.', 'LineWidth',1.5, 'DisplayName','2RC');
        xlabel('Time (s)'); ylabel('Voltage drop (V)');
        if isfield(dataAll(i),'SOC_begin')
            title(sprintf('Pulse #%d, SOC: %.2f%%', i, dataAll(i).SOC_begin*100));
        else
            title(sprintf('Pulse #%d', i));
        end
        
        % 파라미터 텍스트 (1RC와 2RC 각각)
        txt1 = sprintf('1RC: R0=%.4f, R1=%.4f,\ntau=%.4f', res_1RC(i,1), res_1RC(i,2), res_1RC(i,3));
        txt2 = sprintf('2RC: R0=%.4f, R1=%.4f,\nC1=%.4f, R2=%.4f, C2=%.4f', res_2RC(i,1), res_2RC(i,2), res_2RC(i,3), res_2RC(i,4), res_2RC(i,5));
        text(0.05*max(t_data), 0.9*max(dv_data), {txt1, txt2}, 'FontSize',8, 'BackgroundColor','w');
        
        legend('Location','best','FontSize',8);
        hold off;
    end
end

%% --- 1RC model ---
function y = func_1RC(time, I, para)
    % para = [R0, R1, tau]
    R0 = para(1);
    R1 = para(2);
    tau = para(3);
    y = I * R0 + I * R1 .* (1 - exp(-time./(R1*tau)));
end
function c = cost_1RC(p, t, dv_data, I, weight)
    dv_model = func_1RC(t, I, p);
    c = sqrt(mean(((dv_data - dv_model) .* weight).^2));
end

%% --- 2RC model ---
function y = model_2RC(t, I, p)
    % p = [R0, R1, C1, R2, C2]
    R0 = p(1);
    R1 = p(2);
    C1 = p(3);
    R2 = p(4);
    C2 = p(5);
    y = I * (R0 + R1*(1 - exp(-t./(R1*C1))) + R2*(1 - exp(-t./(R2*C2))));
end
function c = cost_2RC(p, t, dv_data, I)
    dv_model = model_2RC(t, I, p);
    c = sqrt(mean((dv_data - dv_model).^2));
end
