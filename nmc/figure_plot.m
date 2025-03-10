% MAT 파일 로드
fileName = '03-21-17_00.29 25degC_UDDS_Pan18650PF.mat';
data = load(fileName);

% Time, Voltage, Current 데이터 추출
time = data.meas.Time;       % 시간 데이터
voltage = data.meas.Voltage; % 전압 데이터
current = data.meas.Current; % 전류 데이터

% 그래프 생성
figure;

% 왼쪽 y축: 전류
yyaxis left;
plot(time, current, 'LineWidth', 0.5, 'Color', 'r'); % 전류 플롯
ylabel('Current (A)'); % 왼쪽 y축 레이블
ylim([min(current) max(current)]); % y축 범위 설정
grid on;

% 오른쪽 y축: 전압
yyaxis right;
plot(time, voltage, 'LineWidth', 0.5, 'Color', 'b'); % 전압 플롯
ylabel('Voltage (V)'); % 오른쪽 y축 레이블
ylim([min(voltage) max(voltage)]); % y축 범위 설정

% 공통 x축 레이블 및 제목
xlabel('Time (s)');
title('Voltage and Current vs Time');
legend('Current (A)', 'Voltage (V)', 'Location', 'best');

% 그래프 저장
outputFileName = 'Voltage_and_Current_with_Dual_YAxis_UDDS.png';
saveas(gcf, outputFileName);
disp(['전압 및 전류 (이중 y축) vs 시간 그래프가 저장되었습니다: ', outputFileName]);
