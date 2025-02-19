% 1. 파일 불러오기
data = load('03-11-17_08.47 25degC_5Pulse_HPPC_Pan18650PF.mat');

% 2. 필요한 데이터 가져오기
current = data.meas.Current;  % 전류 데이터
time = data.meas.Time;        % 시간 데이터 (초 단위)
voltage = data.meas.Voltage;  % 전압 데이터

% 3. 허용 오차 설정
tolerance = 0.1;

% 4. Step 할당 (기본값: REST)
step = strings(size(current));  % Step 배열 초기화

% 5. Step 정의 조건
step(abs(current - (-1.45)) <= tolerance) = "0.5C";
step(abs(current - (-2.9)) <= tolerance) = "1C";
step(abs(current - (-5.8)) <= tolerance) = "2C";
step(abs(current - (-11.6)) <= tolerance) = "4C";
step(abs(current - (-17.4)) <= tolerance) = "6C";
step(abs(current) <= tolerance) = "REST";  % 전류가 0인 경우 REST

% 6. 기존 데이터에 Step 추가
data.meas.Step = step;

% 7. 데이터 테이블 생성
T = table(time, current, voltage, step, 'VariableNames', {'Time', 'Current', 'Voltage', 'Step'});

% 8. 새로운 MAT 파일로 저장
save('Updated_Step_Data.mat', 'data', 'T');

% 9. 결과 출력
disp('Step data successfully added and saved to Updated_Step_Data.mat');
