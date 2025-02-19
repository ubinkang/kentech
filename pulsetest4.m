%% 전체 스크립트 시작
clc; clear; close all;

%% 1. MAT 파일 불러오기 (newStruct)
S = load('NewPulseData.mat');
dataAll = S.newStruct;   % dataAll(i).current, .voltage, .time, .V_final, .SOC_begin, ...
Npulse = numel(dataAll);
fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);

%% 2. 각 펄스를 한 화면에 서브플롯으로 표시 + 2RC 모델 (초반 구간 가중치↑) 피팅 결과 표시
figure('Name','2RC Fit - Weighted (Front Emphasis)','Color','w');
nrows = 4;
ncols = 4;
c_mat = lines(9);  % 컬러맵

% 1RC 모델 초기 파라미터 (고정값으로 사용)
para0 = [0.02, 0.02, 2.2];  % [R0, R1, tau1]
R0_fixed = para0(1);
R1_fixed = para0(2);
C1_fixed = para0(3) / para0(2);  % C1 = tau1 / R1

for i = 1:Npulse
    subplot(nrows, ncols, i)

    % (1) 시간, 전압 데이터
    t_raw = dataAll(i).time;
    if isduration(t_raw), t_raw = seconds(t_raw); end
    x = t_raw - t_raw(1);  % 0부터 시작
    y_data = dataAll(i).voltage - dataAll(i).V_final;  % 전압 오프셋

    % (2) 평균 전류
    I_val = mean(dataAll(i).current);

    % (3) 실측 데이터 플롯
    plot(x, y_data, 'bo-', 'LineWidth',1.5);
    hold on; grid on;
    xlabel('Time (s)');
    ylabel('Voltage (V)');

    % 제목(SOC)
    if isfield(dataAll(i),'SOC_begin')
        title(sprintf('SOC: %.2f', dataAll(i).SOC_begin))
    else
        title(sprintf('Pulse #%d', i))
    end

    % (4) fmincon 최적화
    %  - 최적화 변수: [R2, C2]
    R2_init = R1_fixed * 1.1;
    C2_init = C1_fixed * 1.1;
    initial_guess = [R2_init, C2_init];

    lb = [0, 0];
    ub = [2.5, inf];  % R2 <= 2.5, C2 제한 없음

    options = optimoptions('fmincon','Display','none',...
        'MaxIterations',1000,'MaxFunctionEvaluations',5000);

    % 가중치 있는 비용함수 호출
    para_hat_2RC = fmincon(@(params) cost_function_2RC_weighted(params, x, y_data, I_val,...
                               R0_fixed, R1_fixed, C1_fixed), ...
                           initial_guess, [], [], [], [], lb, ub, [], options);

    % (5) 최적화된 모델 결과 계산
    y_model_2RC = model_func_2RC(x, R0_fixed, R1_fixed, para_hat_2RC(1),...
                                 C1_fixed, para_hat_2RC(2), I_val);

    % (6) 모델 곡선 플롯
    plot(x, y_model_2RC, '-', 'Color', c_mat(4, :), 'LineWidth',1.5)

    legend({'data','2RC (front-weight)'}, 'FontSize',8, 'Location','best')

    % (7) 축 범위 자동 맞춤 + 여유
    axis tight;
    ylims = ylim;
    y_margin = 0.05*(ylims(2) - ylims(1));
    ylim([ylims(1) - y_margin,  ylims(2) + y_margin]);

    hold off;
end

%% -----------------------------------------------------------------------
%% 2RC 모델 함수 (그대로)
function voltage = model_func_2RC(time, R0, R1, R2, C1, C2, I)
    voltage = I * (R0 ...
        + R1 * (1 - exp(-time/(R1*C1))) ...
        + R2 * (1 - exp(-time/(R2*C2))));
end

%% -----------------------------------------------------------------------
%% 2RC 모델 cost 함수 (초반 가중치↑)
function cost = cost_function_2RC_weighted(params, time, deltaV, I, R0, R1, C1)
    % params: [R2, C2]
    R2 = params(1);
    C2 = params(2);

    % 모델 계산
    y_model = model_func_2RC(time, R0, R1, R2, C1, C2, I);

    err = deltaV - y_model;

    % 가중치: 앞부분(t=0 근처)에 더 큰 비중
    %  예) w(t) = exp(-alpha * t)
    alpha = 0.3;    % alpha값을 키우면 초반 오차 반영 ↑
    w = exp(-alpha * time);

    % 가중치 적용 RMSE
    weighted_err = err .* w;
    cost = sqrt(mean(weighted_err.^2));
end
