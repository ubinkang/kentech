%% 전체 스크립트 시작
clc; clear; close all;

%% 1. MAT 파일 불러오기 (newStruct)
S = load('NewPulseData.mat');
dataAll = S.newStruct;   % dataAll(i).current, .voltage, .time, .V_final, .SOC_begin, ...
Npulse = numel(dataAll);
fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);

%% 2. 각 펄스를 한 화면에 서브플롯으로 표시 + 2RC 모델 (가중치 없이) 피팅 결과 표시
figure('Name','2RC Fit - Auto Axis','Color','w');
nrows = 4;
ncols = 4;
c_mat = lines(9);  % 컬러맵

% 1RC 모델 초기 파라미터 (고정값으로 사용)
para0 = [0.02, 0.02, 2.2];  % [R0, R1, tau1]
R0_fixed = para0(1);
R1_fixed = para0(2);
C1_fixed = para0(3)/para0(2);  % C1 = tau1 / R1

for i = 1:Npulse
    subplot(nrows, ncols, i)

    % 데이터 추출: 시간 (t_seconds 기준; 첫 번째 값 기준 오프셋)와 전압 오프셋 계산
    t_raw = dataAll(i).time;
    if isduration(t_raw), t_raw = seconds(t_raw); end
    x = t_raw - t_raw(1);

    % 실험 전압 데이터: voltage - V_final
    y_data = dataAll(i).voltage - dataAll(i).V_final;

    % 모델에서 필요한 전류(I)는 평균 전류 사용 (플롯에는 표시하지 않음)
    I_val = mean(dataAll(i).current);

    % 원래 데이터 플로팅 (파란 원-선)
    plot(x, y_data, 'bo-', 'LineWidth', 1.5)
    hold on; grid on;

    xlabel('Time (s)');
    ylabel('Voltage (V)');

    % 제목을 SOC_begin 값으로 설정 (예: SOC: 0.75)
    if isfield(dataAll(i),'SOC_begin')
        title(sprintf('SOC: %.2f', dataAll(i).SOC_begin))
    else
        title(sprintf('Pulse #%d', i))
    end

    % 2RC 모델 최적화: 최적화 변수는 [R2, C2]
    % 초기 추정값: R2_init = R1_fixed*1.1, C2_init = C1_fixed*1.1
    R2_init = R1_fixed * 1.1;
    C2_init = C1_fixed * 1.1;
    initial_guess = [R2_init, C2_init];

    % 변수의 하한과 상한 설정
    lb = [0, 0];
    ub = [2.5, inf];  % R2의 상한을 2.5로 제한, C2 상한은 무한대

    % 최적화 옵션 설정 (단순 fmincon 사용)
    options = optimoptions('fmincon','Display','none',...
                           'MaxIterations',1000,'MaxFunctionEvaluations',5000);

    % 2RC 모델 비용 함수 (가중치 없이 RMSE) 최적화: 최적화 대상은 [R2, C2]
    para_hat_2RC = fmincon(@(params) cost_function_2RC(params, x, y_data, I_val,...
                               R0_fixed, R1_fixed, C1_fixed), ...
                           initial_guess, [], [], [], [], lb, ub, [], options);

    % 최적화된 2RC 모델 결과 계산
    y_model_2RC = model_func_2RC(x, R0_fixed, R1_fixed, para_hat_2RC(1),...
                                 C1_fixed, para_hat_2RC(2), I_val);

    % 최적화된 2RC 모델 결과 플로팅 (c_mat의 4번째 색상 사용)
    plot(x, y_model_2RC, '-', 'Color', c_mat(4, :), 'LineWidth', 1.5)

    legend({'data','2RC fitted'}, 'FontSize',8, 'Location','best')

    % --- 여기서 축 범위를 데이터 범위로 자동 맞춤 + 조금의 여유 ---
    axis tight;  % 플롯된 데이터 범위에 딱 맞춤
    % y축에 여유 추가
    ylims = ylim;
    y_margin = 0.05 * (ylims(2) - ylims(1));
    ylim([ylims(1) - y_margin,  ylims(2) + y_margin]);

    hold off;
end

%% -----------------------------------------------------------------------
%% 함수 정의

%% 2RC 모델 함수
function voltage = model_func_2RC(time, R0, R1, R2, C1, C2, I)
    % 2RC 모델: 두 RC 소자 병렬 (전류에 따른 overpotential 계산)
    voltage = I * (R0 ...
        + R1 * (1 - exp(-time / (R1*C1))) ...
        + R2 * (1 - exp(-time / (R2*C2))));
end

%% 2RC 모델 cost 함수 (단순 RMSE)
function cost = cost_function_2RC(params, time, deltaV, I, R0, R1, C1)
    % params: [R2, C2]
    R2 = params(1);
    C2 = params(2);
    voltage_model = model_func_2RC(time, R0, R1, R2, C1, C2, I);
    error = deltaV - voltage_model;
    cost = sqrt(mean(error.^2));  % 단순 RMSE
end
