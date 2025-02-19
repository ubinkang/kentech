function myPulseFit_05C()
    clc; clear; close all;
    
    %% 1. MAT 파일 불러오기 (newStruct)
    S = load('NewPulseData.mat'); 
    dataAll = S.newStruct;   % dataAll(i).current, .voltage, .time, .V_final, .SOC_begin, .SOC_end, ...
    Npulse = numel(dataAll);
    fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);
    
    %% 2. 1RC 모델 피팅 및 4×4 서브플롯 표시
    % 한 Figure에 최대 16개 subplot (4행×4열)
    plots_per_fig = 16;
    fig_count = 1;
    subplot_idx = 1;
    
    % Figure 생성 및 기본 설정
    figure('Name','1RC Fitting (4x4)','Color','w');
    set(gcf, 'Units','pixels','Position',[100,100,1200,800]);
    sgtitle('1RC Fitting Results (4x4 Grid)');
    
    % 1RC 모델 초기 파라미터 (초기 추정값)
    para0 = [0.03, 0.013, 1.5];  % [R0, R1, tau]
    
    % 최적화 옵션 및 경계조건
    lb = [0, 0, 0.5];
    ub = para0 * 10;
    options = optimoptions('fmincon','Display','none',...
                           'MaxIterations',1000, 'MaxFunctionEvaluations',5000);
    
    for i = 1:Npulse
        % Figure 변경: 16개를 초과하면 새 Figure 생성
        if subplot_idx > plots_per_fig
            fig_count = fig_count + 1;
            figure('Name','1RC Fitting (4x4)','Color','w');
            set(gcf, 'Units','pixels','Position',[100,100,1200,800]);
            sgtitle('1RC Fitting Results (4x4 Grid)');
            subplot_idx = 1;
        end
        
        % 데이터 추출: 시간은 0부터 시작하도록 재설정, 전압 오프셋은 V - V_final
        x = dataAll(i).time - dataAll(i).time(1);
        y_data = dataAll(i).voltage - dataAll(i).V_final;
        I_val = mean(dataAll(i).current);
        
        % 서브플롯에 데이터 플롯
        subplot(4,4,subplot_idx);
        plot(x, y_data, 'bo-', 'LineWidth',1.5);
        hold on; grid on;
        xlabel('Time (s)');
        ylabel('Voltage drop (V)');
        if isfield(dataAll(i),'SOC_begin')
            title(sprintf('Pulse #%d, SOC: %.2f', i, dataAll(i).SOC_begin));
        else
            title(sprintf('Pulse #%d', i));
        end
        
        % 가중치 벡터 (초반에 더 큰 비중: exp(-x/0.8))
        weight_exp = exp(-x/0.8);
        
        % fmincon을 통해 1RC 모델 파라미터 피팅
        para_hat = fmincon(@(p) func_cost(y_data, p, x, I_val, weight_exp), para0, [], [], [], [], lb, ub, [], options);
        
        % 피팅된 파라미터 콘솔 출력
        fprintf('Pulse #%d fitted parameters: R0 = %.4f, R1 = %.4f, tau = %.4f\n', i, para_hat(1), para_hat(2), para_hat(3));
        
        % 1RC 모델 피팅 결과 계산 및 플로팅
        y_model = func_1RC(x, I_val, para_hat);
        plot(x, y_model, 'r-', 'LineWidth',1.5);
        
        % 축 범위 자동 맞춤 (axis tight + 여유)
        axis tight;
        ylims = ylim;
        y_margin = 0.1 * (ylims(2) - ylims(1));
        ylim([ylims(1) - y_margin, ylims(2) + y_margin]);
        
        % 플롯 내에 피팅 파라미터 텍스트 추가
        txt = sprintf('R0 = %.4f\nR1 = %.4f\ntau = %.4f', para_hat(1), para_hat(2), para_hat(3));
        text(0.05 * max(x), 0.9 * max(y_data), txt, 'FontSize',10, 'Color','k', 'BackgroundColor','w');
        
        legend({'Data', '1RC fitted (weighted)'}, 'Location','best', 'FontSize',8);
        hold off;
        
        subplot_idx = subplot_idx + 1;
    end
end

%% -----------------------------------------------------------------------
%% 서브함수들

% 1RC 모델 함수
function y = func_1RC(time, I, para)
    % para = [R0, R1, tau]
    R0 = para(1);
    R1 = para(2);
    tau = para(3);
    y = I * R0 + I * R1 .* (1 - exp(-time ./ (R1 * tau)));
end

% 가중치 적용된 1RC 모델 비용 함수 (RMSE)
function cost = func_cost(y_data, para, t, I, weight)
    y_model = func_1RC(t, I, para);
    cost = sqrt(mean(((y_data - y_model) .* weight).^2));
end
