%% 1. 파일 불러오기 (OCV vs Time)
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');

% OCV, 시간, state 데이터 로드
OCV   = data1.meas.Voltage;  
time  = data1.meas.Time;    % 시간 데이터 (예: 초 또는 분)
state = data1.meas.state;   % 각 데이터 포인트에 대해 'Charge' 또는 'Discharge' 문자열

%% 2. 이동평균 계산 (각 데이터 포인트 기준 앞에 2개, 뒤에 3개)
N = length(OCV);
OCV_avg = zeros(size(OCV));

for i = 1:N
    % 중앙 영역: 앞쪽 2개와 뒤쪽 3개 모두 존재하는 경우
    if i - 2 >= 1 && i + 3 <= N
        idx = (i-2):(i+3);
    % 맨 앞 영역: 앞에 2개가 부족한 경우 -> 처음 6개 사용
    elseif i - 2 < 1
        idx = 1:min(6, N);
    % 맨 뒤 영역: 뒤에 3개가 부족한 경우 -> 마지막 6개 사용
    elseif i + 3 > N
        idx = max(1, N-5):N;
    end
    OCV_avg(i) = mean(OCV(idx));
end

%% 3. 충전과 방전 구분 (state 변수를 활용)
% state가 'Charge'이면 충전, 'Discharge'이면 방전으로 구분
charge_idx    = strcmpi(state, 'Charge');
discharge_idx = strcmpi(state, 'Discharge');

%% 4. 시간에 따른 OCV 플롯 (충전: 파란색, 방전: 빨간색)
figure;
hold on;
plot(time(charge_idx), OCV_avg(charge_idx), 'b-', 'LineWidth', 1.5);      % 충전 (파란색)
plot(time(discharge_idx), OCV_avg(discharge_idx), 'r-', 'LineWidth', 1.5);  % 방전 (빨간색)
xlabel('Time');
ylabel('OCV (V)');
title('OCV vs Time (6-Point Moving Average)');
legend('Charging', 'Discharging');
grid on;
hold off;
