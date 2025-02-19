%% 1. 파일 불러오기 (OCV vs Time)
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');

% OCV, 시간, state 데이터 로드
OCV   = data1.meas.Voltage;  
time  = data1.meas.Time;    % 시간 데이터 (예: 초 또는 분)
state = data1.meas.state;   % 각 데이터 포인트에 대해 'Charge' 또는 'Discharge' 문자열

%% 2. 이동평균 계산 using movmean 함수
% movmean(데이터, [앞쪽 포함 개수  뒤쪽 포함 개수]) 형태로 사용 가능
% 여기서는 앞쪽 2개, 뒤쪽 3개를 포함하도록 설정합니다.
OCV_avg = movmean(OCV, [2 3]);

%% 3. 충전과 방전 구분 (state 변수를 활용)
% state가 'Charge'이면 충전, 'Discharge'이면 방전으로 구분
charge_idx    = strcmpi(state, 'Charge');      % 대소문자 구분 없이 비교
discharge_idx = strcmpi(state, 'Discharge');

%% 4. 시간에 따른 OCV 플롯 (충전: 파란색, 방전: 빨간색)
figure;
hold on;
plot(time(charge_idx), OCV_avg(charge_idx), 'b-', 'LineWidth', 1.5);      % 충전 (파란색)
plot(time(discharge_idx), OCV_avg(discharge_idx), 'r-', 'LineWidth', 1.5);  % 방전 (빨간색)
xlabel('Time');
ylabel('OCV (V)');
title('OCV vs Time (6-Point Moving Average using movmean)');
legend('Charging', 'Discharging');
grid on;
hold off;
