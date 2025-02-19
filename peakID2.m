%% peakPlotFindpeaks_Prominence.m
% - Trips.mat 불러오기
% - 사용자에게 트립 번호 입력받기
% - 해당 트립에서 Current, Voltage 불러오기
% - findpeaks로 국소 최대/최소 찾되, MinPeakProminence로 필터
% - 전류 조건(예: >2, < -2)도 적용
% - 결과를 이중축 그래프로 표시 (빨간 점=최대, 초록 점=최소)

% 1. Trips.mat 로드
load('Trips.mat','trips');

% 2. 사용자에게 트립 번호 입력받기
tripNumber = input('Enter the trip number to display: ');
if tripNumber < 1 || tripNumber > length(trips)
    error('트립 번호가 유효하지 않습니다. (1~%d 사이)', length(trips));
end

% 3. 해당 트립의 time, current, voltage 추출
t = trips(tripNumber).time;
c = trips(tripNumber).current;   % current
v = trips(tripNumber).voltage;  % voltage

% --------------------------
% 4. findpeaks로 국소 최대/최소 찾기
% --------------------------
% (1) 국소 최대
[pksMaxAll, idxMaxAll] = findpeaks(v, ...
    'MinPeakProminence', 0.02); 
% ↑ MinPeakProminence 값을 적당히 조절하세요 (0.01 ~ 0.1 등)

% (2) 국소 최소
[pksMinAll, idxMinAll] = findpeaks(-v, ...
    'MinPeakProminence', 0.02);
pksMinAll = -pksMinAll;  % 실제 전압 최소값으로 변환

% --------------------------
% 5. 전류 조건 필터링
% --------------------------
% 국소 최대는 current > +1 인 지점만
condMax = (c(idxMaxAll) > 1);
idxMax = idxMaxAll(condMax);
pksMax = pksMaxAll(condMax);

% 국소 최소는 current < -1 인 지점만
condMin = (c(idxMinAll) < -1);
idxMin = idxMinAll(condMin);
pksMin = pksMinAll(condMin);

% --------------------------
% 6. 플로팅
% --------------------------
figure('Name', sprintf('Trip %d: Local Max/Min with Current Condition (findpeaks)', tripNumber), ...
       'NumberTitle', 'off');

% (왼쪽 Y축 - Current)
yyaxis left
plot(t, c, 'm-', 'LineWidth', 1.3);
ylabel('Current (A)', 'Color', 'm');
set(gca,'YColor','m');

% (오른쪽 Y축 - Voltage)
yyaxis right
plot(t, v, 'b-', 'LineWidth', 1.3); 
hold on;

% 국소 최대(빨간 원), 국소 최소(초록 원) 표시
plot(t(idxMax), pksMax, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(t(idxMin), pksMin, 'go', 'MarkerSize', 6, 'MarkerFaceColor', 'g');

ylabel('Voltage (V)', 'Color', 'b');
set(gca,'YColor','b');

xlabel('Time');
title(sprintf('Trip %d: Local Max/Min with Current Condition (findpeaks)', tripNumber));
grid on;
legend('Current','Voltage','Local Max','Local Min','Location','best');
