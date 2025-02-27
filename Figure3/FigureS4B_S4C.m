% load CSV file
fileName = fullfile('data', 'dataFigureS4BC.csv');
dataT = readtable(fileName);

% read the table
[input.ORNs, ~, icORN] = unique(dataT.ORN, 'stable');     %ORN name

for i = 1:length(input.ORNs)
    list1 = find(icORN == i); 
    
    %odor name
    odorVec = unique(dataT.Odor(list1),'stable');       
    input.odors(i, :) = odorVec';   
    
    %concentration, df/f, exp_ID 
    for j = 1:length(input.odors(i,:))
        list2 = find(strcmp(input.odors{i, j}, dataT.Odor)) ;
        list12 = intersect(list1, list2);
        
        % concentration
        concVec = unique(dataT.Concentration(list12), 'stable'); input.concList{i, j} = concVec';
        
        % df/f
        input.dff{i, j} = transpose(reshape(dataT.DF_F(list12), length(input.concList{i, j}), []));
        
        % exp ID
        input.expID{i, j} = unique(dataT.Exp_ID(list12), 'stable'); 
    end
end

%% other settings
% color map for curves
cColor = [252,141,89;...
    240,59,32; ...
    44,127,184; ...
    127,205,187]/255;

% setup fitting function and method
hillEq = @(a, b, c, x)  a./(1+ exp(-b*(x-c)));
ft = fittype( 'a/(1+ exp(-b*(x-c)))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Robust = 'Bisquare';
opts.Lower = [-1 -1 -11]; % setup the range and initial value of the variable
opts.Upper = [10 15 -3];
opts.StartPoint = [5 5 -9];

%% averaged data
%calculate the mean and sem
results.rMean = cellfun(@mean, input.dff, 'UniformOutput', false);
results.rSEM  = cellfun(@(x) std(x)/size(x, 1), input.dff, 'UniformOutput', false);

% plot the curves in one figure
figure; hold on; legText = {};
for i = 1:length(input.ORNs)
    for j = 1:length(input.odors(1, :))
        errorbar(input.concList{i,j}, results.rMean{i, j}, results.rSEM{i, j}, ...
            '-o', 'Color', cColor(j+(i-1)*length(input.odors(1, :)),:)); 
        legText{end+1} = [input.ORNs{i}, ' ',input.odors{i, j}];
    end    
end

% format the figure 
legend(legText, 'Location',  'northwest'); axis tight; hold off;
xlabel('Concentration'); ylabel('\DeltaF/F'); set(gca,'XScale','log' );
yTickMax = round(max(reshape(cell2mat(results.rMean), [], 1)));
yticks(1:yTickMax); yticklabels(num2str((1:yTickMax)')); 
xticks(logspace(-11, -4, 8));
xticklabels({'10^{11}', '10^{10}', '10^{9}', '10^{8}', '10^{7}', ...
    '10^{6}', '10^{5}', '10^{4}',});
set(gcf, 'Position', [100, 100, 700, 420]); movegui(gcf, 'northwest');

% save figure
saveas(gcf, fullfile('.', 'results', 'figures', 'FigureS4B.fig'));

%% fit each individual curve and display the parameters
disp('----------FIT INDIVIDUAL CURVE:----------');
fprintf('%5s\t%-20s\t%-5s\t%-5s\t%-5s\t%-5s\t%-5s\t\n', 'ORN', 'Odor', 'Trial', 'Amp', 'Slop', 'EC_{50}', 'R^2');
for i = 1:length(input.ORNs)
    for j = 1:length(input.odors(1, :))
        yMat = input.dff{i, j}; [trialNum, ~] = size(yMat);
        for k = 1:trialNum
            [fitresult, gof] = fit(log10((input.concList{i,j})'), (yMat(k,:))', ft, opts);
            results.fitCoeffIdv{i, j}(k,:) = coeffvalues(fitresult);    
            results.fitR2Idv{i, j}(k) = gof.rsquare; 
            fprintf('%5s\t%-20s\t%5s\t%.2f\t%.2f\t%.2f\t%.2f\n', ...
                input.ORNs{i}, input.odors{i, j}, input.expID{i, j}{k}, ...
                results.fitCoeffIdv{i, j}(k,1), results.fitCoeffIdv{i, j}(k,2), ...
                results.fitCoeffIdv{i, j}(k,3), results.fitR2Idv{i, j}(k));
        end
    end
end

%% compare the amplitude responding to different odors for each individual animal
figure; hold on; 

coeffPool = cell2mat(results.fitCoeffIdv);
ampPool = coeffPool(:, [1, 4]); 

for i = 1:length(input.ORNs)
    for k = 1:length(input.expID{i, 1})
        myIndex = (i-1) * length(input.expID{1, 1}) + k;
        for j = 1:length(input.odors(1, :))
            plot((i-1)*length(input.odors(1, :)) + j, ampPool(myIndex, j), ...
                'o', 'Color', cColor(j+(i-1)*length(input.odors(1, :)),:));
            
        end
        plot([1 2]+(i-1)*2, ampPool(myIndex, :), 'k');

    end
end

xticks(1:i*j); hold off 
xticklabels({input.odors{1, 1}, input.odors{1,2}, input.odors{2, 1}, input.odors{2,2}});
xtickangle(-45);    ylabel('y_{max}'); axis([0.5 4.5 floor(min(ampPool(:))) ceil(max(ampPool(:)))]);
set(gcf, 'Position', [100, 100, 350, 420]); movegui(gcf, 'north');

% save figure
saveas(gcf, fullfile('.', 'results', 'figures', 'FigureS4C.fig'));