function myPulseFit_ClosedForm_AllDischarge()
    clc; clear; close all;

    %% 1. MAT 파일 불러오기 (newStruct)
    S = load('NewPulseData.mat'); 
    dataAll = S.newStruct;   % 예: dataAll(i).current, .voltage, .time, .V_final, .SOC_begin ...

    Npulse = numel(dataAll);
    fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);

    %% 2. fmincon 최적화 설정
    % (A) 경계조건: [R0, R1, C] >= 0
    lb = [0, 0, 0];
    ub = [Inf, Inf, Inf];

    % (B) 가중치에서 사용할 m 값
    m_value = 0.5;  % w(t) = exp(-m_value * t)

    % (C) fmincon 옵션
    options = optimoptions('fmincon',...
        'Display','iter',...
        'MaxFunctionEvaluations',1e5,...
        'TolFun',1e-9,'TolX',1e-9);

    % (D) 초기 추정값
    param0 = [0.0013, 0.02, 2000];  % [R0, R1, C]

    % 결과 저장 배열
    bestParams = zeros(Npulse,3);   % [R0, R1, C]
    sumErrors  = zeros(Npulse,1);   % Weighted SSE

    %% 3. 각 펄스(i)에 대해 폐형식 1RC 모델 피팅
    for i = 1:Npulse
        % ----- (1) 데이터 추출 -----
        I_vec  = dataAll(i).current;   % Nx1
        V_meas = dataAll(i).voltage;   % Nx1
        t_vec  = dataAll(i).time;      % Nx1 (duration이면 seconds 변환)
        if isduration(t_vec)
            t_vec = seconds(t_vec);
        end

        % 상수 전류로 근사
        I_constant = mean(I_vec);

        % 직전 Rest 전압(V_final)을 OCV로 사용
        OCV_init = dataAll(i).V_final;

        % ----- (2) fmincon 최적화 -----
        costFun = @(p) costFunClosedFormWeighted(...
            p, t_vec, I_constant, V_meas, OCV_init, m_value);

        [bestP, fval] = fmincon(costFun, param0, [],[],[],[], lb, ub, [], options);

        % 결과 저장
        bestParams(i,:) = bestP;
        sumErrors(i)    = fval;

        % 화면 출력
        fprintf('\n=== 펄스 #%d ===\n', i);
        fprintf('R0=%.5f,  R1=%.5f,  C=%.1f,  Weighted SSE=%.4g\n',...
            bestP(1), bestP(2), bestP(3), fval);
    end

    %% 4. 결과 테이블
    T = array2table(bestParams, 'VariableNames',{'R0','R1','C'});
    disp('=== 1RC 폐형식 + 가중치 + 경계조건 결과 ===');
    disp(T);

    disp('=== Weighted SSE 목록 ===');
    disp(sumErrors);

    %% 5. 펄스별 측정 vs 모델 전압 비교 그래프
    plots_per_fig = 9;
    subplot_idx   = 1;
    figure('Name','ClosedForm Weighted','Color','w');
    sgtitle('모든 Discharge 펄스: 1RC Closed-Form (Weighted)');

    for i = 1:Npulse
        if subplot_idx>plots_per_fig
            figure('Name','ClosedForm Weighted - next','Color','w');
            sgtitle('모든 Discharge 펄스: 1RC Closed-Form (Weighted)');
            subplot_idx = 1;
        end
        subplot(3,3,subplot_idx); hold on; grid on;

        % 측정값
        I_vec  = dataAll(i).current;
        V_meas = dataAll(i).voltage;
        t_vec  = dataAll(i).time;
        if isduration(t_vec), t_vec = seconds(t_vec); end

        % 모델 계산
        pfit      = bestParams(i,:);
        I_constant= mean(I_vec);
        OCV_init  = dataAll(i).V_final;
        V_model   = simulate1RCClosedForm(t_vec, I_constant, OCV_init, pfit);

        plot(t_vec, V_meas, 'k-', 'LineWidth',1.2, 'DisplayName','Measured');
        plot(t_vec, V_model,'r--','LineWidth',1.2,'DisplayName','Model');

        xlabel('Time (s)');
        ylabel('Voltage (V)');
        title(sprintf('Pulse #%d', i));
        legend('Location','best','FontSize',7);

        % (선택) SOC_begin, SOC_end 표시
        if isfield(dataAll(i),'SOC_begin') && isfield(dataAll(i),'SOC_end')
            text(t_vec(1), max(V_meas), ...
                sprintf('SOC: %.1f%% -> %.1f%%', dataAll(i).SOC_begin*100, dataAll(i).SOC_end*100), ...
                'FontSize',8,'Color','k','FontWeight','bold');
        end

        subplot_idx = subplot_idx+1;
    end
end

%% ------------------------------------------------------------------------
% 비용함수: Weighted SSE 
%   V_model(t) = OCV - [ I*R0 + I*R1*(1 - exp(-t/(R1*C))) ]
%   cost = sum( w(t)*(V_meas - V_model)^2 ),  w(t)=exp(-m*t)
%% ------------------------------------------------------------------------
function cost = costFunClosedFormWeighted(p, t_vec, I_const, V_meas, OCV, m_value)
    R0 = p(1); 
    R1 = p(2); 
    C1 = p(3);

    V_model = simulate1RCClosedForm(t_vec, I_const, OCV, [R0,R1,C1]);

    err = (V_meas - V_model);
    w   = exp(-m_value .* t_vec);

    cost = sum( w .* (err.^2) );
end

%% ------------------------------------------------------------------------
% 폐형식 1RC 전압 계산
%   V_model = OCV - [ I*R0 + I*R1*(1 - exp(-t/(R1*C))) ]
%% ------------------------------------------------------------------------
function V_model = simulate1RCClosedForm(t_vec, I, OCV, p)
    R0 = p(1);
    R1 = p(2);
    C1 = p(3);

    N = length(t_vec);
    V_model = zeros(N,1);

    for k = 1:N
        t = t_vec(k);
        deltaV = I*R0 + I*R1*(1 - exp(-t/(R1*C1)));
        V_model(k) = OCV - deltaV;
    end
end
