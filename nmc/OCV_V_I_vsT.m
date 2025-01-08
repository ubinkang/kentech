% MAT 파일 로드
fileName = '05-08-17_13.26 C20 OCV Test_C20_25dC.mat';
data = load(fileName);

% 데이터 추출
time = data.meas.Time;       % 시간 데이터
voltage = data.meas.Voltage; % 전압 데이터
current = data.meas.Current; % 전류 데이터

% 그래프 생성
figure;

% 왼쪽 y축: 전류
yyaxis left;
plot(time, current, 'LineWidth', 1.5, 'Color', 'r'); % 전류 플롯
ylabel('Current (A)', 'Color', 'r'); % 왼쪽 y축 레이블 (빨간색)
set(gca, 'YColor', 'r'); % 왼쪽 y축 눈금 색상을 빨간색으로 설정
grid on; % 격자 추가

% 오른쪽 y축: 전압
yyaxis right;
plot(time, voltage, 'LineWidth', 1.5, 'Color', 'b'); % 전압 플롯
ylabel('Voltage (V)', 'Color', 'b'); % 오른쪽 y축 레이블 (파란색)
set(gca, 'YColor', 'b'); % 오른쪽 y축 눈금 색상을 파란색으로 설정

% 공통 x축 레이블 및 제목
xlabel('Time (s)');
title('OCV Voltage and Current vs Time');
legend('Current (A)', 'Voltage (V)', 'Location', 'best');

% 그래프 저장
outputFileName = 'Voltage_and_Current_with_Colored_YAxis_C20_OCV.png';
saveas(gcf, outputFileName);
disp(['전압 및 전류 (색상 통일) vs 시간 그래프가 저장되었습니다: ', outputFileName]);
