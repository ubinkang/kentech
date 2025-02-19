%% peakPlotFindpeaks_Prominence.m

% 1. Trips.mat 불러오기
load('Trips.mat','trips');

% 2. 트립 번호 입력
tripNumber = input('Enter the trip number to display: ');
if tripNumber < 1 || tripNumber > length(trips)
    error('트립 번호가 유효하지 않습니다. (1~%d 사이)', length(trips));
end

% 3. 데이터 추출
t = trips(tripNumber).time;
c = trips(tripNumber).current;  % Current
v = trips(tripNumber).voltage; % Voltage

% --------------------------------------------------
% 4. 국소 최대/최소 찾기 (findpeaks 이용 + 전류 조건)
% --------------------------------------------------
% (a) 국소 최대 (Voltage 기준)
[pksMaxAll, idxMaxAll] = findpeaks(v, 'MinPeakProminence', 0.02);
%  ↑ 0.02 대신 신호에 맞는 적절한 값으로 조정하세요.

% (b) 국소 최소 (–Voltage 기준)
[pksMinAll, idxMinAll] = findpeaks(-v, 'MinPeakProminence', 0.02);
pksMinAll = -pksMinAll; % 실제 전압 최소값

% (c) 전류 조건 필터링: 국소 최대 → c(i) > +1, 국소 최소 → c(i) < -1
condMax = (c(idxMaxAll) > 1);
idxMax  = idxMaxAll(condMax);
pksMax  = pksMaxAll(condMax);

condMin = (c(idxMinAll) < -1);
idxMin  = idxMinAll(condMin);
pksMin  = pksMinAll(condMin);

% --------------------------------------------------
% 5. 최소·최대 정보 통합하여 시간 순서 정렬
% --------------------------------------------------
%   - peakTimes(k): k번째 피크의 시간
%   - peakVals(k) : k번째 피크의 전압
%   - peakTypes(k): 'min' 또는 'max'
peakTimes = [ t(idxMin); t(idxMax) ];
peakVals  = [ pksMin;   pksMax   ];
peakTypes = [ repmat({'min'}, length(idxMin), 1);
              repmat({'max'}, length(idxMax), 1) ];

% 시간 기준 오름차순 정렬
[peakTimesSorted, iSort] = sort(peakTimes);
peakValsSorted  = peakVals(iSort);
peakTypesSorted = peakTypes(iSort);

% --------------------------------------------------
% 6. 연속된 두 피크가 서로 다른 유형(min→max or max→min)이면서
%    전압 차이가 0.2 V 이상이면 → 검은 마커로 표시
% --------------------------------------------------
blackTimes = [];  % 검은 마커 찍을 시간들을 모을 배열
blackVals  = [];  % 검은 마커 찍을 전압

for k = 1 : (length(peakTimesSorted) - 1)
    % 현재 피크(k)와 다음 피크(k+1)
    typeNow  = peakTypesSorted{k};
    typeNext = peakTypesSorted{k+1};
    
    % 서로 다른 유형(최소->최대 or 최대->최소)인지 확인
    if ~strcmp(typeNow, typeNext)
        diffV = abs(peakValsSorted(k+1) - peakValsSorted(k));
        if diffV >= 0.2
            % 두 지점을 검은 마커로 표시하기 위해 기록
            blackTimes = [blackTimes, peakTimesSorted(k), peakTimesSorted(k+1)];
            blackVals  = [blackVals,  peakValsSorted(k),  peakValsSorted(k+1)];
        end
    end
end

% --------------------------------------------------
% 7. 그래프 그리기
% --------------------------------------------------
figure('Name', sprintf('Trip %d: Local Max/Min with Condition (findpeaks)', tripNumber), ...
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

% 국소 최대(빨간 점), 국소 최소(초록 점) 표시
plot(t(idxMax), pksMax, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(t(idxMin), pksMin, 'go', 'MarkerSize', 6, 'MarkerFaceColor', 'g');

% 전압 차이가 0.2 V 이상인 쌍에 대해 검은 점 표시
plot(blackTimes, blackVals, 'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'k');

ylabel('Voltage (V)', 'Color', 'b');
set(gca,'YColor','b');

xlabel('Time');
title(sprintf('Trip %d: Local Max/Min with Current Condition (findpeaks)', tripNumber));
grid on;
legend('Current','Voltage','Local Max','Local Min','ΔV>=0.2','Location','best');
