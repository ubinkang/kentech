%% 전체 스크립트 시작
clc; clear; close all;

%% 1. MAT 파일 불러오기 (newStruct)
S = load('NewPulseData.mat'); 
dataAll = S.newStruct;   % dataAll(i).current, .voltage, .time, .V_final, .SOC_begin, ...
Npulse = numel(dataAll);
fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);

%% 2. 각 펄스를 한 화면에 서브플롯으로 표시 + 가중치 준 1RC 모델 피팅 결과만 표시
figure;
nrows = 4;
ncols = 4;
c_mat = lines(9);  % 컬러맵

% 모델 초기 파라미터 (1RC 모델)
para0 = [0.03, 0.013, 1.5];  % [R0, R1, tau1]

for i = 1:Npulse
    subplot(nrows, ncols, i)
    
    % 데이터 추출
    x = dataAll(i).time - dataAll(i).time(1);
    y1 = dataAll(i).voltage - dataAll(i).V_final;
    I_val = mean(dataAll(i).current);
    
    % 데이터 플롯 (파란 원-선)
    plot(x, y1, 'bo-', 'LineWidth', 1.5)
    hold on; grid on;
    xlabel('Time (s)')
    ylabel('Voltage (V)')

    % SOC_begin 값으로 제목 설정
    if isfield(dataAll(i), 'SOC_begin')
        title(sprintf('SOC: %.2f', dataAll(i).SOC_begin))
    else
        title(sprintf('Pulse #%d', i))
    end
    
    % fmincon으로 [R0, R1, tau1] 최적화 (가중치 적용)
    lb = [0, 0, 1];
    ub = para0 * 10;
    weight_exp = exp(-x/0.8);  % 지수 가중치
    para_hat = fmincon(@(p) func_cost(y1, p, x, I_val, weight_exp), ...
                       para0, [], [], [], [], lb, ub);

    % (추가) 파라미터 출력
    fprintf('Pulse #%d fitted: R0=%.4f, R1=%.4f, tau1=%.4f\n', ...
        i, para_hat(1), para_hat(2), para_hat(3));

    % 피팅된 모델 곡선
    y_model_hat = func_1RC(x, I_val, para_hat);
    plot(x, y_model_hat, '-', 'Color', c_mat(4,:), 'LineWidth', 1.5)
    
    legend({'data', 'fitted (weighted)'}, 'FontSize',8, 'Location','best')
    
    % 축 범위 자동 맞춤
    axis tight;  
    ylims = ylim;
    y_margin = 0.1 * (ylims(2) - ylims(1));
    ylim([ylims(1) - y_margin,  ylims(2) + y_margin]);

    hold off;
end

%% -----------------------------------------------------------------------
%% 함수 정의
function y = func_1RC(time, I, para)
    R0   = para(1);
    R1   = para(2);
    tau1 = para(3);
    y = I * R0 + I * R1 .* (1 - exp(-time / tau1));
end

function cost = func_cost(y_data, para, t, I, weight)
    y_model = func_1RC(t, I, para);
    cost = sqrt(mean(((y_data - y_model) .* weight).^2));  % RMSE
end
