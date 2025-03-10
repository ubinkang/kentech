%% 1. MAT 파일 불러오기 (newStruct)
S = load('NewPulseData.mat'); 
dataAll = S.newStruct;   % 예: dataAll(i).current, .voltage, .time, .V_final, .SOC_begin, ...
Npulse = numel(dataAll);
fprintf('NewPulseData.mat에서 총 %d개의 Discharge 펄스가 로드되었습니다.\n', Npulse);

% 한 화면에 모든 펄스를 표시하기 위한 서브플롯 설정 (예: 4행 4열 grid; 총 16 슬롯 중 14 사용)
figure;
nrows = 4;
ncols = 4;
c_mat = lines(9);
for i = 1:Npulse
    subplot(nrows, ncols, i)
    
    % 시간: 첫 번째 시간값 기준 오프셋 적용
    x = dataAll(i).time - dataAll(i).time(1);
    % 전압 오프셋: voltage - V_final
    y1 = dataAll(i).voltage - dataAll(i).V_final;
    % 전류 데이터
    y2 = dataAll(i).current;
    
    % 왼쪽 y축: Voltage 데이터 플로팅
    yyaxis left
    plot(x, y1, 'bo-', 'LineWidth', 1.5)
    % 여기서는 y1의 최소값이 음수라고 가정하여, y축 범위를 [1.1*min(y1) 0]으로 설정
    ylim([1.1*min(y1) 0])
    ylabel('Voltage (V)', 'Color', 'b')
    
    % 오른쪽 y축: Current 데이터 플로팅
    yyaxis right
    plot(x, y2, 'ro-', 'LineWidth', 1.5)
    ylim([1.1*min(y2) 0])
    ylabel('Current (A)', 'Color', 'r')
    
    xlabel('Time (s)')
    title(sprintf('Pulse %d', i))
    grid on;
    
    % 모델 시각화 (모델 결과를 왼쪽 y축에 오버레이)
    para0 = [0.023, 0.023, 2.2];  % 모델 파라미터: [R0, R1, tau1]
    y_model = func_1RC(x, y2, para0);
    yyaxis left
    hold on
    plot(x, y_model, 'k-', 'LineWidth', 1.5)  % 검은 선으로 모델 결과 표시
    hold off
end

%% Model 함수 정의
function y = func_1RC(time, I, para)
    % time: 시간 (초)
    % I: 전류 (A)
    % para(1) = R0 [ohm]
    % para(2) = R1 [ohm]
    % para(3) = tau1 [s]
    % y: overpotential (V-OCV) [V]
    
    R0 = para(1);
    R1 = para(2);
    tau1 = para(3);
    y = I * R0 + I * R1 .* (1 - exp(-time / tau1));
end

%legend


%%fitting case1
%initial guess
    %para
%bound
    lb = [0 0 1];
    ub = para0*10;

    

% weight
    weight = ones(size(y1)); %uniform weighting
%fitting
    para_hat = fmincon(@(para)func_cost(y1,para,x,y2,weight), para0,[] ,[] ,[],[] , lb,ub);
%visualize    
    
    y_model_hat = func_1RC(x, y2, para_hat);
    figure(1)
    hold on
    yyaxis left
    plot(x, y_model_hat, 'g-')  % 초록 선으로 모델 결과 표시

%%fitting case 2
%initial guess
    %para
%bound
    lb = [0 0 1];
    ub = para0*10;

    

% weight
    weight = exp(-x/0.8); %uniform weighting
%fitting
    para_hat = fmincon(@(para)func_cost(y1,para,x,y2,weight), para0,[] ,[] ,[],[] , lb,ub);
%visualize    
    
    y_model_hat = func_1RC(x, y2, para_hat);
    figure(1)
    hold on
    yyaxis left
    plot(x, y_model_hat, '-','Color',c_mat(4,:))  % 초록 선으로 모델 결과 표시
legend({'data','initial','fitted','modified_fit'})

% cost (weight)
function cost = func_cost(y_data, para,t,I, weight)

y_model = func_1RC(t,I,para);
cost = sqrt(mean((y_data - y_model).*weight).^2) %RMSE error

end