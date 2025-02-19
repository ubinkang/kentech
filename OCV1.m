% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');

% 2. 필요한 데이터 가져오기
time = data.meas.Time;       % 시간 데이터 (초 단위)
voltage = data.meas.Voltage; % OCV 데이터 (V)
state = data.meas.state;     % 충전/방전 상태 ('Charge' 또는 'Discharge')

% 3. 충전과 방전 구분 (state 변수를 활용)
charge_idx    = strcmpi(state, 'Charge');      % 대소문자 구분 없이 비교
discharge_idx = strcmpi(state, 'Discharge');

% 4. V vs Time 그래프 그리기 (충전: 파란색, 방전: 빨간색)
figure;
hold on;
plot(time(charge_idx), voltage(charge_idx), 'b-', 'LineWidth', 1.5);      % 충전 (파란색)
plot(time(discharge_idx), voltage(discharge_idx), 'r-', 'LineWidth', 1.5);  % 방전 (빨간색)
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Voltage vs Time');
legend('Charging', 'Discharging');
grid on;
hold off;
