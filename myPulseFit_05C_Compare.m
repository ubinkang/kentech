function myPulseFit_05C_Compare()
    clc; clear; close all;

    %% 1. MAT 파일 불러오기
    rawData = load('03-11-17_08.47 25degC_5Pulse_HPPC_Pan18650PF.mat');

    % 시간, 전압, 전류
    time    = rawData.meas.Time;
    voltage = rawData.meas.Voltage;
    current = rawData.meas.Current;

    % 하나의 구조체 data1에 저장
    data1.I = current(:);
    data1.V = voltage(:);
    data1.t = time(:);

    % 전류 상태 구분: C(양전류), R(0), D(음전류)
    data1.type = char(zeros(size(data1.t)));
    data1.type(data1.I>0)  = 'C';
    data1.type(data1.I==0) = 'R';
    data1.type(data1.I<0)  = 'D';

    % 스텝 번호 매기기
    data_length = length(data1.t);
    data1.step = zeros(data_length,1);
    m = 1;
    data1.step(1) = m;
    for j=2:data_length
        if data1.type(j) ~= data1.type(j-1)
            m = m+1;
        end
        data1.step(j) = m;
    end

    %% 2. 각 스텝별 구조체 만들기
    vec_step = unique(data1.step);
    num_step = length(vec_step);

    data_line = struct('V',[],'I',[],'t',[],'type','R');
    data = repmat(data_line, num_step, 1);

    for i_step = 1:num_step
        range = find(data1.step == vec_step(i_step));
        data(i_step).V    = data1.V(range);
        data(i_step).I    = data1.I(range);
        data(i_step).t    = data1.t(range);
        data(i_step).type = data1.type(range(1));
        % 시간 0으로 재설정
        t0 = data(i_step).t(1);
        data(i_step).t = data(i_step).t - t0;
    end

    %% 3. Discharge 스텝 인덱스
    step_dis = [];
    for i=1:num_step
        if strcmp(data(i).type, 'D')
            step_dis(end+1) = i;
        end
    end

    % 평균 전류
    for i=1:num_step
        data(i).avgI = mean(data(i).I);
    end

    % deltaV: 이번 스텝 시작 전압 대비
    for i=1:num_step
        if i==1
            data(i).dv = zeros(size(data(i).V));
        else
            data(i).dv = data(i).V - data(i-1).V(end);
        end
    end

    %% 임의로 "0.5C" 스텝만 추출
    if length(step_dis)>=2
        refI = data(step_dis(2)).avgI; 
    else
        refI = 1;  % 임시
    end

    step_05C = [];
    tol = 1e-3;
    for k=1:length(step_dis)
        idx = step_dis(k);
        cRate = data(idx).avgI / refI;
        if abs(cRate - 0.5)<tol
            step_05C(end+1) = idx;
        end
    end
    disp(['0.5C step count: ', num2str(length(step_05C))]);

    %% 4. 1RC(가중치=초반부 강조), 2RC(가중치 없이) 각각 피팅
    n05 = length(step_05C);

    % 1RC 결과
    res_1RC = struct('R0',NaN,'R1',NaN,'C',NaN,'cost',NaN);
    res_1RC = repmat(res_1RC, n05,1);

    % 2RC 결과
    res_2RC = struct('R0',NaN,'R1',NaN,'C1',NaN,'R2',NaN,'C2',NaN,'cost',NaN);
    res_2RC = repmat(res_2RC, n05,1);

    ms_1rc = MultiStart('Display','off');
    ms_2rc = MultiStart('Display','off');

    for i=1:n05
        idx = step_05C(i);
        t_data  = data(idx).t;
        dv_data = data(idx).dv;
        I_val   = data(idx).avgI;
        if isduration(t_data), t_data=seconds(t_data); end

        %% (A) 1RC: [R0,R1,C], cost 함수에서 앞부분(작은 t) 더 강조
        init_1rc = [0.01, 0.02, 2.0]; 
        lb_1rc   = [0,0,0];
        ub_1rc   = [0.5,1.0,100];
        problem_1rc = createOptimProblem('fmincon',...
            'objective',@(p) cost_1RC_weighted(p, t_data, dv_data, I_val),...
            'x0', init_1rc,'lb',lb_1rc,'ub',ub_1rc,...
            'options',optimoptions('fmincon','Display','none','MaxIterations',200));
        [p_1rc, c_1rc] = run(ms_1rc, problem_1rc, 10);

        res_1RC(i).R0  = p_1rc(1);
        res_1RC(i).R1  = p_1rc(2);
        res_1RC(i).C   = p_1rc(3);
        res_1RC(i).cost= c_1rc;

        %% (B) 2RC: [R0,R1,C1,R2,C2], cost 함수(기본 RMSE)
        init_2rc = [0.01, 0.02, 2.0, 0.01, 2.0];
        lb_2rc   = [0,0,0.1,0,0.1];
        ub_2rc   = [0.5,1.0,100,2.5,500];
        problem_2rc = createOptimProblem('fmincon',...
            'objective',@(p) cost_2RC_basic(p, t_data, dv_data, I_val),...
            'x0',init_2rc,'lb',lb_2rc,'ub',ub_2rc,...
            'options',optimoptions('fmincon','Display','none','MaxIterations',200));
        [p_2rc, c_2rc] = run(ms_2rc, problem_2rc, 10);

        res_2RC(i).R0 = p_2rc(1);
        res_2RC(i).R1 = p_2rc(2);
        res_2RC(i).C1= p_2rc(3);
        res_2RC(i).R2= p_2rc(4);
        res_2RC(i).C2= p_2rc(5);
        res_2RC(i).cost= c_2rc;
    end

    %% 5. 각 스텝별 한 화면(한 Figure)으로 출력
    for i=1:n05
        idx = step_05C(i);
        t_data  = data(idx).t;
        dv_data = data(idx).dv;
        I_val   = data(idx).avgI;
        if isduration(t_data), t_data=seconds(t_data); end

        figure('Name',sprintf('0.5C Step idx=%d',idx),'Color','w');
        hold on; grid on;

        % (a) Data
        plot(t_data, dv_data,'k-','LineWidth',1.5,'DisplayName','Data');

        % (b) 1RC
        R0_1=res_1RC(i).R0; 
        R1_1=res_1RC(i).R1; 
        C_1 =res_1RC(i).C;
        dv_1rc = model_1RC(t_data,I_val,[R0_1,R1_1,C_1]);
        plot(t_data, dv_1rc,'r--','LineWidth',1.2,'DisplayName','1RC(Weighted Front)');

        % (c) 2RC
        R0_2=res_2RC(i).R0;
        R1_2=res_2RC(i).R1;
        C1_2=res_2RC(i).C1;
        R2_2=res_2RC(i).R2;
        C2_2=res_2RC(i).C2;
        dv_2rc= model_2RC(t_data,I_val,[R0_2,R1_2,C1_2,R2_2,C2_2]);
        plot(t_data, dv_2rc,'b-.','LineWidth',1.2,'DisplayName','2RC(Basic)');

        title(sprintf('0.5C Step idx=%d', idx),'FontSize',10);
        xlabel('time(s)'); ylabel('Voltage drop(V)');
        legend('Location','best','FontSize',8);

        hold off;
    end

end

%% --- 1RC(가중치) ---
function dv = model_1RC(t, I, p)
    % p=[R0,R1,C]
    R0 = p(1); R1 = p(2); C = p(3);
    dv = I*( R0 + R1*(1 - exp(-t/(R1*C))) );
end
function c = cost_1RC_weighted(p, t, dv_data, I)
    % 가중치(초반부 강조): w = exp(-0.5 * t) 예시
    alpha=0.5;
    dv_model = model_1RC(t,I,p);
    w = exp(-alpha*t); 
    err = (dv_data - dv_model).* w;
    c   = sqrt(mean(err.^2));
end

%% --- 2RC(기본 RMSE) ---
function dv = model_2RC(t, I, p)
    % p=[R0,R1,C1,R2,C2]
    R0= p(1); R1= p(2); C1= p(3);
    R2= p(4); C2= p(5);
    dv = I*( R0 + R1*(1 - exp(-t/(R1*C1))) + R2*(1 - exp(-t/(R2*C2))) );
end
function c = cost_2RC_basic(p, t, dv_data, I)
    dv_model = model_2RC(t,I,p);
    c = sqrt(mean((dv_data - dv_model).^2));
end
