% MAT 파일 로드
fileName = '05-08-17_13.26_C20_OCV_Test_with_Steps.mat'; % MAT 파일 이름
data = load(fileName); % MAT 파일 로드

% 데이터 추출
time = data.meas.Time;       % 시간 데이터
current = data.meas.Current; % 전류 데이터
voltage = data.meas.Voltage; % 전압 데이터
step = data.meas.Step;       % Step 데이터

% 초기 변수 정의
dt = 60; % 시간 간격 (1분 = 60초)

% Q 계산 (적분)
Q = zeros(size(current)); % Q 배열 초기화
for i = 2:length(current)
    dQ = current(i) * (dt / 3600); % Ah로 변환
    Q(i) = Q(i-1) + dQ; % 이전 Q에 변화량 추가
end

% Step 1에서 OCV vs Q 데이터 추출 (Discharge)
step1Indices = (step == 1); % Step 1 인덱스 (방전 과정)
step1_OCV = voltage(step1Indices); % Step 1의 전압 데이터
step1_Q = Q(step1Indices); % Step 1의 Q 데이터

% Step 3에서 OCV vs Q 데이터 추출 (Charge)
step3Indices = (step == 3); % Step 3 인덱스 (충전 과정)
step3_OCV = voltage(step3Indices); % Step 3의 전압 데이터
step3_Q = Q(step3Indices); % Step 3의 Q 데이터

% 방전 과정: Q 값을 3에서 0으로 변환
step1_Q_adjusted = max(step1_Q) - step1_Q;

% 충전 과정: Q를 좌우 반전 및 2.6166에서 0으로 조정
step3_Q_adjusted = step3_Q - min(step3_Q); % Q 최소값 0으로 조정
step3_Q_adjusted = 2.6166 - step3_Q_adjusted(end:-1:1); % 좌우 반전 및 조정

% OCV vs Q 그래프 그리기
figure;
plot(step1_Q_adjusted, step1_OCV, 'r', 'LineWidth', 1.5); % 방전 과정 (Discharge)
hold on;
plot(step3_Q_adjusted, step3_OCV(end:-1:1), 'b', 'LineWidth', 1.5); % 충전 과정 (Charge)
hold off;

% 그래프 설정
xlabel('Q (Ah)');
ylabel('OCV (V)');
title('OCV vs Q');
legend('Discharge', 'Charge');
grid on;

% 그래프 저장
outputGraphFile = 'OCV_vs_Q_Step1_and_Step3_Adjusted_Reversed.png';
saveas(gcf, outputGraphFile);
disp(['OCV vs Q 그래프가 저장되었습니다: ', outputGraphFile]);
