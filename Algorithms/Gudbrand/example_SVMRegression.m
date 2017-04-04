%% SVM regression testing.
% 
% bestEpsilon = .001;
% bestC = 10;
y = FUTURE_PRICE(1:n);
%hyperparameters chosen by cv using n=200
bestEpsilon = 0.0625;
bestC = 0.5;
%% load data

day1 = 1;
lookback = 60;
horizon = 7;
% bestEpsilon = .1;
% bestC = 10;

[PRICE_HISTORY, FUTURE_PRICE, NAMES] = loadData(day1, lookback, horizon);

n = 500;
t = 500;

X = PRICE_HISTORY(1:n,:);
y = FUTURE_PRICE(1:n);

Xtest = PRICE_HISTORY(n+1:n+t,:);
ytest = FUTURE_PRICE(n+1:n+t);

[~, d] = size(X);

%% Cross-validate to select parameters
tic
k = 5;
cvFolds = crossvalind('Kfold', n, k);   %# get indices of 10-fold CV
minError = inf;

i = 1; 
j = 1;
k = 1;

epsilons = 2.^(-3:3);
sigmas = 2.^(-3:3);
Cs = 2.^(-3:3);
validErrors = zeros(length(sigmas), length(Cs), length(epsilons));

for epsilon = epsilons
    for C = Cs
        for sigma = sigmas
            fprintf('Cross-validating; epsilon = %.3f, C = %.3f, sigma = %.3f\n', epsilon, C, sigma);
            validError = 0;
            for ii=1:k
                valIdx = (cvFolds == ii); 
                trainIdx = ~valIdx;

                Xtrain = X(trainIdx,:);
                ytrain = y(trainIdx);
                Xval = X(valIdx,:);
                yval = y(valIdx);

                model = SVMRegression(Xtrain, ytrain, epsilon, C, sigma);

                yhat = model.predict(model, Xval);

                validError = validError + (sqrt(mean(yhat - yval).^2));
            end
            if validError < minError
                bestEpsilon = epsilon;
                bestC = C;
                bestSigma = sigma;
                minError = validError;
            end
            validErrors(i,j,k) = validError;
            i = i+1;
        end
        j = j+1;
    end
    k = k+1;
end
toc
% Cross-validation is complete!
% Load snippet of Handel's Hallelujah Chorus and play back
load('handel');
p = audioplayer(y, Fs);
play(p, [1 (get(p, 'SampleRate') * 10)]);
y = FUTURE_PRICE(1:n);
%% Train optimal model
tic
% sigma = 100;
% bestC = 100;
% bestEpsilon = 0.01;
model = SVMRegression(X, y, bestEpsilon, bestC, bestSigma);
toc
% save('SVMmodel', 'model');

%% Compute prediction RMS-error
% ytrain = model.predict(model, X);
% yhat = model.predict(model, Xtest);

% trainError = sqrt(mean((y - ytrain).^2));
% trainError = mean(abs(y - ytrain));
trainError = median(abs(y - ytrain));
fprintf('Training error: %.3f\n', trainError);

% testError = sqrt(mean((yhat - ytest).^2));
% testError = mean(abs(yhat - ytest));
testError = median(abs(yhat - ytest));
fprintf('Test error: %.3f\n', testError);

%% Plot predictions
figure();
% plot([(1:t)' (1:t)'], [yhat ytest]);
hold on;
for i=1:t 
    h = plot([i i], [yhat(i) ytest(i)], 'k-');
    set(h,'linewidth',2);
end
h = plot(1:t, yhat, 'r*', 1:t, ytest, 'b+');
set(h,'linewidth',2);
legend('Test - Predictions', 'Ground Truth');
set(gca, 'FontSize', 16);
%%
figure();
plot(1:n, ytrain, '+', 1:n, y, '*');
legend('Training- Predictions', 'Ground Truth');

%%
%should compare with risk-free return here..
s = sign(yhat-X(:,end)).*sign(ytest-X(:,end));
correct = sum(s == 1);
fprintf('Up/Down prediction accuracy: %.2f\n', correct / t);
%%
figure();
hold on

for i=1:n
plot(X(i,:));
end

%%

MdlGau = fitrsvm(X,y,'KernelFunction','gaussian');

yhat = predict(MdlGau, Xtest);
ytrain = predict(MdlGau, X);